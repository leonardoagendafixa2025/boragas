import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boragas/core/models/store_model.dart';
import 'package:boragas/core/models/product_model.dart';
import 'package:boragas/features/customer/providers/customer_providers.dart';
import 'package:boragas/features/customer/providers/cart_provider.dart';
import 'package:boragas/features/merchant/providers/merchant_providers.dart';

void main() {
  group('Precificação Real de Frete pelas Distribuidoras (Sem Mocks)', () {
    const testStore = StoreModel(
      id: 'store-dist-1',
      name: 'Distribuidora Central de Gás',
      cnpj: '12.345.678/0001-99',
      phone: '(11) 98765-4321',
      logoUrl: 'assets/images/app_icon.png',
      coverUrl: 'assets/images/brand_lockup.png',
      address: 'Av. Amazonas, 500 - Centro',
      distanceKm: 2.5,
      rating: 4.9,
      reviewsCount: 88,
      estimatedTimeMin: 20,
      deliveryFee: 4.0, // Taxa base de saída
      feePerKm: 1.50, // R$ 1,50 por km
      maxDeliveryRadiusKm: 12.0, // Raio máximo de 12 km
      freeDeliveryThreshold: 200.0, // Frete grátis acima de R$ 200
      neighborhoodFees: {
        'Centro': 3.50,
        'Santa Efigênia': 6.00,
        'Savassi': 7.50,
        'Floresta': 0.0, // Bairro com entrega promocional grátis
      },
      isNeighborhoodPricingEnabled: true,
    );

    test('1. Aplica taxa fixa definida pela distribuidora para bairros cadastrados', () {
      final resCentro = testStore.calculateDeliveryFee(
        neighborhood: 'Centro',
        clientDistanceKm: 3.0,
        subtotal: 105.0,
      );

      expect(resCentro.fee, 3.50);
      expect(resCentro.pricingMethod, 'neighborhood');
      expect(resCentro.isOutOfRange, false);
      expect(resCentro.isFree, false);

      final resFloresta = testStore.calculateDeliveryFee(
        neighborhood: 'Floresta',
        clientDistanceKm: 2.0,
        subtotal: 90.0,
      );

      expect(resFloresta.fee, 0.0);
      expect(resFloresta.isFree, true);
      expect(resFloresta.pricingMethod, 'neighborhood');
    });

    test('2. Normaliza acentos e maiúsculas/minúsculas no nome dos bairros', () {
      // Cliente digita sem acento ou em maiúsculas: deve casar perfeitamente
      final resVariacao1 = testStore.calculateDeliveryFee(
        neighborhood: 'santa efigenia',
        clientDistanceKm: 4.0,
        subtotal: 100.0,
      );
      expect(resVariacao1.fee, 6.00);
      expect(resVariacao1.pricingMethod, 'neighborhood');

      final resVariacao2 = testStore.calculateDeliveryFee(
        neighborhood: 'SANTA EFIGÊNIA',
        clientDistanceKm: 4.0,
        subtotal: 100.0,
      );
      expect(resVariacao2.fee, 6.00);
      expect(resVariacao2.pricingMethod, 'neighborhood');
    });

    test('3. Calcula por KM (Taxa Base + KM * FeePerKm) quando o bairro não está na tabela fixa', () {
      // Bairro não listado na tabela da distribuidora (ex: Buritis)
      // Distância: 4.0 km -> 4.00 base + (4.0 * 1.50) = 4.00 + 6.00 = R$ 10,00
      final resKm = testStore.calculateDeliveryFee(
        neighborhood: 'Buritis',
        clientDistanceKm: 4.0,
        subtotal: 110.0,
      );

      expect(resKm.fee, 10.00);
      expect(resKm.pricingMethod, 'distance');
      expect(resKm.isOutOfRange, false);
      expect(resKm.description, contains('4.0 km'));
    });

    test('4. Bloqueia e identifica quando o cliente está fora do raio máximo de atendimento', () {
      // Raio máximo configurado: 12.0 km. Cliente a 15.2 km
      final resOutOfRange = testStore.calculateDeliveryFee(
        neighborhood: 'Contagem Industrial',
        clientDistanceKm: 15.2,
        subtotal: 120.0,
      );

      expect(resOutOfRange.isOutOfRange, true);
      expect(resOutOfRange.pricingMethod, 'out_of_range');
      expect(resOutOfRange.description, contains('fora do raio de entrega'));
    });

    test('5. Concede frete grátis prioritário se o subtotal atingir o limite configurado pela distribuidora', () {
      // Threshold = R$ 200,00. Subtotal = R$ 210,00
      final resFree = testStore.calculateDeliveryFee(
        neighborhood: 'Buritis',
        clientDistanceKm: 8.0,
        subtotal: 210.0,
      );

      expect(resFree.fee, 0.0);
      expect(resFree.isFree, true);
      expect(resFree.pricingMethod, 'free_threshold');
      expect(resFree.description, contains('Frete Grátis'));
    });

    test('6. Lojista atualiza regras de frete e reflete imediatamente no provedor da loja', () async {
      final container = ProviderContainer(
        overrides: [
          storesProvider.overrideWith(() => StoresNotifier()),
        ],
      );

      final merchantNotifier =
          container.read(currentMerchantStoreProvider.notifier);

      final success = await merchantNotifier.updateDeliveryConfig(
        baseDeliveryFee: 6.00,
        feePerKm: 2.00,
        maxDeliveryRadiusKm: 20.0,
        freeDeliveryThreshold: 250.0,
        neighborhoodFees: {
          'Funcionários': 8.00,
          'Serra': 10.00,
        },
        isNeighborhoodPricingEnabled: true,
      );

      expect(success, true);

      final updatedStore = container.read(currentMerchantStoreProvider);
      expect(updatedStore.deliveryFee, 6.00);
      expect(updatedStore.feePerKm, 2.00);
      expect(updatedStore.maxDeliveryRadiusKm, 20.0);
      expect(updatedStore.freeDeliveryThreshold, 250.0);
      expect(updatedStore.neighborhoodFees['Funcionários'], 8.00);
      expect(updatedStore.neighborhoodFees['Serra'], 10.00);

      // Testa cálculo com as novas regras atualizadas pelo lojista
      final calcFunc = updatedStore.calculateDeliveryFee(
        neighborhood: 'Funcionários',
        clientDistanceKm: 5.0,
        subtotal: 100.0,
      );
      expect(calcFunc.fee, 8.00);
      expect(calcFunc.pricingMethod, 'neighborhood');
    });

    test('7. CartProvider calcula frete automaticamente cruzando com o endereço do cliente', () {
      final container = ProviderContainer();

      // Configura endereço do cliente com bairro Santa Efigênia
      const clientAddr = AddressModel(
        id: 'addr-test',
        label: 'Casa',
        street: 'Rua Ceará',
        number: '120',
        neighborhood: 'Santa Efigênia',
        city: 'Belo Horizonte',
        state: 'MG',
        cep: '30150-310',
        isDefault: true,
      );
      container.read(currentAddressProvider.notifier).set(clientAddr);

      final testProduct = ProductModel(
        id: 'p13-gas',
        storeId: testStore.id,
        storeName: testStore.name,
        category: ProductCategory.p13,
        name: 'Botijão P13 GLP',
        brandName: 'Ultragaz',
        description: 'Gás de cozinha residencial',
        refillPrice: 105.00,
        shellPrice: 280.00,
        imageUrl: 'assets/images/app_icon.png',
        rating: 5.0,
        inStock: true,
      );

      // Adiciona item ao carrinho
      container.read(cartProvider.notifier).addItem(
            product: testProduct,
            store: testStore,
            quantity: 1,
            isRefillOnly: true,
          );

      final cartState = container.read(cartProvider);

      expect(cartState.subtotal, 105.00);
      // Como o cliente é do bairro Santa Efigênia, a taxa deve ser R$ 6,00
      expect(cartState.deliveryFee, 6.00);
      expect(cartState.total, 111.00);
      expect(cartState.deliveryFeeDescription, contains('Santa Efigênia'));

      // Agora altera o endereço do cliente para Savassi (taxa R$ 7,50)
      const clientAddrSavassi = AddressModel(
        id: 'addr-savassi',
        label: 'Trabalho',
        street: 'Av. Getúlio Vargas',
        number: '800',
        neighborhood: 'Savassi',
        city: 'Belo Horizonte',
        state: 'MG',
        cep: '30112-020',
        isDefault: true,
      );
      container.read(currentAddressProvider.notifier).set(clientAddrSavassi);

      final cartSavassi = container.read(cartProvider);
      expect(cartSavassi.deliveryFee, 7.50);
      expect(cartSavassi.total, 112.50);
      expect(cartSavassi.deliveryFeeDescription, contains('Savassi'));
    });
  });
}
