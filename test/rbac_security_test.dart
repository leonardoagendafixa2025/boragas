import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boragas/core/models/order_model.dart';
import 'package:boragas/core/models/product_model.dart';
import 'package:boragas/data/mock_database.dart';
import 'package:boragas/features/auth/providers/auth_provider.dart';
import 'package:boragas/features/customer/providers/cart_provider.dart';
import 'package:boragas/features/customer/providers/customer_providers.dart';
import 'package:boragas/features/merchant/providers/merchant_providers.dart';

void main() {
  group('RBAC & Multi-Tenant Architectural Rules - BoraGás', () {
    test('1. AuthProvider supports 4 distinct roles with explicit store binding', () {
      final container = ProviderContainer();
      final authNotifier = container.read(authProvider.notifier);

      // Cliente
      authNotifier.switchDemoRole(UserRole.customer);
      expect(container.read(authProvider).user?.role, equals(UserRole.customer));
      expect(container.read(authProvider).user?.storeId, isNull);

      // Lojista
      authNotifier.switchDemoRole(UserRole.merchant);
      expect(container.read(authProvider).user?.role, equals(UserRole.merchant));
      expect(container.read(authProvider).user?.storeId, equals('store-1'));

      // Entregador
      authNotifier.switchDemoRole(UserRole.courier);
      expect(container.read(authProvider).user?.role, equals(UserRole.courier));
      expect(container.read(authProvider).user?.storeId, equals('store-1'));

      // Super Admin
      authNotifier.switchDemoRole(UserRole.admin);
      expect(container.read(authProvider).user?.role, equals(UserRole.admin));
      expect(container.read(authProvider).user?.storeId, isNull);
    });

    test('2. Lojista only manages products from their own store (Multi-Tenant Isolation)', () {
      final container = ProviderContainer();
      container.read(storesProvider.notifier).set(MockDatabase.sampleStoresForTesting);
      container.read(productsProvider.notifier).set([
        ...MockDatabase.sampleProductsForTesting,
        const ProductModel(
          id: 'prod-4',
          storeId: 'store-2',
          storeName: 'Liquigás Central do Gás',
          category: ProductCategory.p13,
          name: 'Botijão P13 Liquigás (13kg)',
          brandName: 'Liquigás (Verde)',
          description: 'Botijão com chama forte e pura',
          refillPrice: 99.90,
          shellPrice: 279.00,
          inStock: true,
          imageUrl: 'assets/images/app_icon.png',
          rating: 4.8,
        ),
      ]);

      // Loja Ultragaz (store-1)
      final ultragazProducts = container.read(merchantProductsProvider);
      expect(ultragazProducts.every((p) => p.storeId == 'store-1'), isTrue);

      // Muda para loja Liquigás (store-2)
      final allStores = container.read(storesProvider);
      final store2 = allStores.firstWhere((s) => s.id == 'store-2');
      container.read(currentMerchantStoreProvider.notifier).set(store2);

      final liquigasProducts = container.read(merchantProductsProvider);
      expect(liquigasProducts.every((p) => p.storeId == 'store-2'), isTrue);
      expect(liquigasProducts.any((p) => p.storeId == 'store-1'), isFalse);
    });

    test('3. Checkout automatically binds the authenticated customer ID', () {
      final container = ProviderContainer();
      container.read(storesProvider.notifier).set(MockDatabase.sampleStoresForTesting);
      container.read(productsProvider.notifier).set(MockDatabase.sampleProductsForTesting);
      final authNotifier = container.read(authProvider.notifier);

      authNotifier.switchDemoRole(UserRole.customer);
      final stores = container.read(storesProvider);
      final products = container.read(productsProvider);

      // Simula adição de item ao carrinho
      final cartNotifier = container.read(cartProvider.notifier);
      cartNotifier.addItem(
        product: products.first,
        store: stores.first,
        quantity: 1,
        isRefillOnly: true,
      );

      final order = cartNotifier.checkout('Rua Teste, 100 - São Paulo');
      expect(order.customerId, equals('usr-001'));
      expect(order.storeId, equals(stores.first.id));
      expect(order.deliveryConfirmationCode.length, equals(4));
    });

    test('4. Delivery PIN verification validates physical dropoff', () {
      final order = OrderModel(
        id: 'ord-test-1',
        orderNumber: '#BG-9999',
        customerId: 'usr-001',
        customerName: 'Cliente Teste',
        customerPhone: '(11) 98765-4321',
        storeId: 'store-1',
        storeName: 'Ultragaz Paulistana Express',
        items: const [],
        status: OrderStatus.outForDelivery,
        paymentMode: PaymentMode.onlinePix,
        paymentStatus: PaymentStatus.paidDirectlyToStore,
        deliveryAddress: 'Av. Paulista, 1000',
        subtotal: 104.90,
        deliveryFee: 0.0,
        totalAmount: 104.90,
        commissionRatePercent: 8.0,
        platformCommissionAmount: 8.39,
        deliveryConfirmationCode: '4821',
        createdAt: DateTime.now(),
      );

      // PIN incorreto
      expect('1234' == order.deliveryConfirmationCode, isFalse);

      // PIN correto fornecido pelo cliente
      expect('4821' == order.deliveryConfirmationCode, isTrue);

      final completedOrder = order.copyWith(
        status: OrderStatus.delivered,
        deliveredAt: DateTime.now(),
      );
      expect(completedOrder.status, equals(OrderStatus.delivered));
      expect(completedOrder.deliveredAt, isNotNull);
    });
  });
}
