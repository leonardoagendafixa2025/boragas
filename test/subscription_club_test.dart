import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boragas/core/models/product_model.dart';
import 'package:boragas/core/models/store_model.dart';
import 'package:boragas/features/customer/providers/cart_provider.dart';
import 'package:boragas/features/customer/providers/subscription_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Clube BoraGás - Subscription Provider & Lifecycle Tests', () {
    test('1. Inicialização vazia e ativação do plano com periodicidade', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Estado inicial sem assinatura
      expect(container.read(subscriptionProvider), isNull);

      // Ativar assinatura de P13 a cada 30 dias
      await container.read(subscriptionProvider.notifier).activateSubscription(
            planId: 'p13_standard',
            planTitle: 'Gás de Cozinha P13',
            planPrice: 99.75,
            frequencyDays: 30,
            timeSlot: 'Manhã (08h às 12h)',
            deliveryAddress: 'Rua Principal, 100',
          );

      final sub = container.read(subscriptionProvider);
      expect(sub, isNotNull);
      expect(sub!.isActive, isTrue);
      expect(sub.isPaused, isFalse);
      expect(sub.planId, equals('p13_standard'));
      expect(sub.frequencyDays, equals(30));
      expect(sub.daysUntilNextDelivery, inInclusiveRange(29, 30));
    });

    test('2. Adiar entrega em +15 dias e adiantar para hoje', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(subscriptionProvider.notifier).activateSubscription(
            planId: 'combo_house',
            planTitle: 'Combo Econômico: Gás P13 + Água 20L',
            planPrice: 109.90,
            frequencyDays: 30,
            timeSlot: 'Tarde (13h às 18h)',
            deliveryAddress: 'Av Brasil, 500',
          );

      var sub = container.read(subscriptionProvider)!;
      final initialDays = sub.daysUntilNextDelivery;

      // Adiar entrega em +15 dias
      await container.read(subscriptionProvider.notifier).postponeNextDelivery(15);
      sub = container.read(subscriptionProvider)!;
      expect(sub.daysUntilNextDelivery, greaterThan(initialDays));

      // Adiantar entrega para hoje
      await container.read(subscriptionProvider.notifier).advanceNextDeliveryToToday();
      sub = container.read(subscriptionProvider)!;
      expect(sub.daysUntilNextDelivery, equals(0));
    });

    test('3. Pausar e retomar assinatura do clube', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(subscriptionProvider.notifier).activateSubscription(
            planId: 'water_20l',
            planTitle: 'Galão Água Mineral 20L',
            planPrice: 14.25,
            frequencyDays: 15,
            timeSlot: 'Qualquer Horário',
            deliveryAddress: 'Rua das Flores, 12',
          );

      // Pausar
      await container.read(subscriptionProvider.notifier).togglePause();
      var sub = container.read(subscriptionProvider)!;
      expect(sub.isPaused, isTrue);

      // Retomar
      await container.read(subscriptionProvider.notifier).togglePause();
      sub = container.read(subscriptionProvider)!;
      expect(sub.isPaused, isFalse);
    });

    test('4. Cancelamento da assinatura do clube', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(subscriptionProvider.notifier).activateSubscription(
            planId: 'p13_standard',
            planTitle: 'Gás de Cozinha P13',
            planPrice: 99.75,
            frequencyDays: 45,
            timeSlot: 'Manhã',
            deliveryAddress: 'Rua do Sol, 40',
          );

      expect(container.read(subscriptionProvider)?.isActive, isTrue);

      await container.read(subscriptionProvider.notifier).cancelSubscription();
      expect(container.read(subscriptionProvider), isNull);
    });
  });

  group('Clube BoraGás - Integração com Desconto no Carrinho (5% OFF)', () {
    const mockStore = StoreModel(
      id: 'store-test-01',
      name: 'Ultragaz Central Test',
      cnpj: '12.345.678/0001-90',
      phone: '(11) 99999-9999',
      logoUrl: '',
      coverUrl: '',
      address: 'Rua das Flores, 100',
      distanceKm: 1.5,
      rating: 4.9,
      reviewsCount: 150,
      estimatedTimeMin: 25,
      deliveryFee: 5.0,
      isOpen: true,
      commissionRate: 8.0,
    );

    const mockProduct = ProductModel(
      id: 'prod-p13-01',
      storeId: 'store-test-01',
      storeName: 'Ultragaz Central Test',
      category: ProductCategory.p13,
      name: 'Botijão de Gás P13',
      brandName: 'Ultragaz',
      description: 'Botijão lacrado Ultragaz',
      refillPrice: 100.0,
      shellPrice: 280.0,
      imageUrl: '',
      inStock: true,
    );

    test('5. Membro do Clube recebe 5% OFF automático no carrinho e checkout', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 1. Inicializa o cartProvider e adiciona 1 botijão troca (R$ 100,00)
      container.read(cartProvider.notifier).addItem(
            product: mockProduct,
            store: mockStore,
            quantity: 1,
            isRefillOnly: true,
          );

      // Sem assinatura: subtotal 100, entrega 5, total 105, clubDiscount 0
      var cart = container.read(cartProvider);
      expect(cart.subtotal, equals(100.0));
      expect(cart.isClubMember, isFalse);
      expect(cart.clubDiscount, equals(0.0));
      expect(cart.total, equals(105.0));

      // 2. Cliente ativa o Clube BoraGás
      await container.read(subscriptionProvider.notifier).activateSubscription(
            planId: 'p13_standard',
            planTitle: 'Gás P13',
            planPrice: 99.75,
            frequencyDays: 30,
            timeSlot: 'Manhã',
            deliveryAddress: 'Rua Teste, 123',
          );

      // O cartNotifier deve reagir e marcar isClubMember = true
      cart = container.read(cartProvider);
      expect(cart.isClubMember, isTrue);
      // 5% de R$ 100 = R$ 5,00 de desconto
      expect(cart.clubDiscount, equals(5.0));
      // Total: 100 + 5 (taxa) - 5 (desconto clube) = 100.0
      expect(cart.total, equals(100.0));

      // 3. Ao finalizar checkout, o pedido registra o desconto de R$ 5,00
      final order = container.read(cartProvider.notifier).checkout('Rua Teste, 123');
      expect(order.discount, equals(5.0));
      expect(order.totalAmount, equals(100.0));
    });
  });
}
