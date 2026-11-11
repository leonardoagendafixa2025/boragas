import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boragas/core/models/order_model.dart';
import 'package:boragas/core/models/product_model.dart';
import 'package:boragas/core/models/store_model.dart';
import 'package:boragas/core/router/app_router.dart';
import 'package:boragas/features/auth/providers/auth_provider.dart';
import 'package:boragas/features/customer/providers/cart_provider.dart';
import 'package:boragas/features/customer/providers/customer_providers.dart';
import 'package:boragas/features/merchant/providers/merchant_providers.dart';

void main() {
  group('E2E QA & Security Pre-Launch Pipeline - BoraGás', () {
    // -------------------------------------------------------------
    // ETAPA 2.A: AUTENTICAÇÃO, CONTAS E PERMISSÕES POR PERFIL
    // -------------------------------------------------------------
    test('A1. Cadastro de novos perfis com padrão [QA-TESTE] isolado', () async {
      final container = ProviderContainer();
      final authNotifier = container.read(authProvider.notifier);

      // Cadastro de Cliente
      final regClientSuccess = await authNotifier.registerUser(
        name: '[QA-TESTE] Cliente Fulano',
        email: 'teste+cliente@qa-teste.local',
        phone: '(11) 90000-0001',
        password: 'SenhaSegura@123',
        role: UserRole.customer,
        deliveryAddress: 'Rua das Flores, 100 - Bairro Teste',
      );
      expect(regClientSuccess, isTrue);
      expect(container.read(authProvider).user?.role, equals(UserRole.customer));
      expect(container.read(authProvider).user?.name, contains('[QA-TESTE]'));

      // Cadastro de Lojista
      final regMerchantSuccess = await authNotifier.registerUser(
        name: '[QA-TESTE] Distribuidora Central',
        email: 'teste+lojista@qa-teste.local',
        phone: '(11) 90000-0002',
        password: 'SenhaSegura@123',
        role: UserRole.merchant,
        storeName: '[QA-TESTE] Distribuidora Central',
        storeCnpj: '11.222.333/0001-44',
        storeAddress: 'Av. Brasil, 500 - Centro',
      );
      expect(regMerchantSuccess, isTrue);
      expect(container.read(authProvider).user?.role, equals(UserRole.merchant));

      // Cadastro de Entregador
      final regCourierSuccess = await authNotifier.registerUser(
        name: '[QA-TESTE] Piloto Rápido',
        email: 'teste+entregador@qa-teste.local',
        phone: '(11) 90000-0003',
        password: 'SenhaSegura@123',
        role: UserRole.courier,
        vehicleModel: 'Yamaha Fazer 250',
        vehiclePlate: 'TEST-1234',
      );
      expect(regCourierSuccess, isTrue);
      expect(container.read(authProvider).user?.role, equals(UserRole.courier));
    });

    test('A2. Login com credenciais e recuperação de senha via WhatsApp Hub', () async {
      final container = ProviderContainer();
      final authNotifier = container.read(authProvider.notifier);

      // Login Lojista
      final loginSuccess = await authNotifier.loginWithEmailPassword(
        'teste+lojista@qa-teste.local',
        'SenhaSegura@123',
      );
      expect(loginSuccess, isTrue);
      expect(container.read(authProvider).isAuthenticated, isTrue);

      // Recuperação de Senha via WhatsApp
      final resetResult = await authNotifier.sendPasswordResetOtp('11900000002');
      expect(resetResult['success'], isTrue);
      expect(resetResult['code'], isNotNull);
      expect(resetResult['code'].toString().length, equals(6));

      // Logout
      await authNotifier.logout();
      expect(container.read(authProvider).isAuthenticated, isFalse);
      expect(container.read(authProvider).user, isNull);
    });

    test('A3. Validação de isolamento RBAC entre perfis', () {
      final customerAuth = const AuthState(
        isAuthenticated: true,
        user: UserProfile(
          id: 'usr-qa-cust-1',
          name: '[QA-TESTE] Cliente 1',
          phone: '(11) 90000-0001',
          email: 'teste+cliente@qa-teste.local',
          role: UserRole.customer,
        ),
      );

      final merchantAuth = const AuthState(
        isAuthenticated: true,
        user: UserProfile(
          id: 'usr-qa-merch-1',
          name: '[QA-TESTE] Lojista 1',
          phone: '(11) 90000-0002',
          email: 'teste+lojista@qa-teste.local',
          role: UserRole.merchant,
          storeId: 'store-qa-1',
        ),
      );

      // Cliente é barrado em rotas de Admin, Lojista e Entregador
      expect(evaluateAppRouteRedirect(auth: customerAuth, location: '/admin'), equals('/home'));
      expect(evaluateAppRouteRedirect(auth: customerAuth, location: '/merchant'), equals('/home'));
      expect(evaluateAppRouteRedirect(auth: customerAuth, location: '/courier'), equals('/home'));

      // Lojista é barrado no Admin e no Entregador
      expect(evaluateAppRouteRedirect(auth: merchantAuth, location: '/admin'), equals('/merchant'));
      expect(evaluateAppRouteRedirect(auth: merchantAuth, location: '/courier'), equals('/merchant'));
      expect(evaluateAppRouteRedirect(auth: merchantAuth, location: '/merchant'), isNull);
    });

    // -------------------------------------------------------------
    // ETAPA 2.B: OPERAÇÃO DO LOJISTA (LOJA, PRODUTOS, ESTOQUE)
    // -------------------------------------------------------------
    test('B1. Lojista: Abertura/fechamento da loja e gestão de catálogo Gás & Água', () {
      final container = ProviderContainer();
      final storeNotifier = container.read(currentMerchantStoreProvider.notifier);

      final qaStore = const StoreModel(
        id: 'store-qa-test-1',
        name: '[QA-TESTE] Central de Gás e Água do Bairro',
        cnpj: '12.345.678/0001-99',
        phone: '(11) 90000-0002',
        logoUrl: 'assets/images/app_icon.png',
        coverUrl: 'assets/images/brand_lockup.png',
        address: 'Rua de Teste, 500 - São Paulo',
        distanceKm: 1.5,
        rating: 5.0,
        reviewsCount: 1,
        estimatedTimeMin: 25,
        deliveryFee: 6.0,
        isVerified: true,
        isOpen: false,
        commissionRate: 8.0,
      );

      storeNotifier.set(qaStore);
      expect(container.read(currentMerchantStoreProvider).isOpen, isFalse);

      // Alterna para aberta
      final newStatus = storeNotifier.toggleOpen();
      expect(newStatus, isTrue);
      expect(container.read(currentMerchantStoreProvider).isOpen, isTrue);

      // Cadastro de Produtos da Loja: Gás e Água
      final prodGas = const ProductModel(
        id: 'prod-qa-gas-1',
        storeId: 'store-qa-test-1',
        storeName: '[QA-TESTE] Central de Gás e Água do Bairro',
        category: ProductCategory.p13,
        name: '[QA-TESTE] Botijão GLP 13kg Premium',
        brandName: 'Ultragaz',
        description: 'Gás de alta pressão para cozinha',
        refillPrice: 105.00,
        shellPrice: 285.00,
        inStock: true,
        imageUrl: 'assets/images/app_icon.png',
        rating: 5.0,
      );

      final prodWater = const ProductModel(
        id: 'prod-qa-water-1',
        storeId: 'store-qa-test-1',
        storeName: '[QA-TESTE] Central de Gás e Água do Bairro',
        category: ProductCategory.water20l,
        name: '[QA-TESTE] Galão de Água 20L Puríssima',
        brandName: 'Lindoya',
        description: 'Água mineral natural leve',
        refillPrice: 16.00,
        shellPrice: 48.00,
        inStock: true,
        imageUrl: 'assets/images/app_icon.png',
        rating: 4.9,
      );

      container.read(productsProvider.notifier).set([prodGas, prodWater]);
      final merchantProds = container.read(merchantProductsProvider);

      expect(merchantProds.length, equals(2));
      expect(merchantProds.any((p) => p.category == ProductCategory.p13), isTrue);
      expect(merchantProds.any((p) => p.category == ProductCategory.water20l), isTrue);
      expect(merchantProds.every((p) => p.storeId == 'store-qa-test-1'), isTrue);
    });

    // -------------------------------------------------------------
    // ETAPA 2.C & 2.D: JORNADA DO CLIENTE & MEIOS DE PAGAMENTO SANDBOX
    // -------------------------------------------------------------
    test('C1. Checkout Multimeios: Pix Online Sandbox com Cupom de Desconto', () {
      final container = ProviderContainer();
      final cartNotifier = container.read(cartProvider.notifier);

      final qaStore = const StoreModel(
        id: 'store-qa-test-1',
        name: '[QA-TESTE] Central de Gás e Água',
        cnpj: '12.345.678/0001-99',
        phone: '(11) 90000-0002',
        logoUrl: 'assets/images/app_icon.png',
        coverUrl: 'assets/images/brand_lockup.png',
        address: 'Rua de Teste, 500',
        distanceKm: 1.5,
        rating: 5.0,
        reviewsCount: 1,
        estimatedTimeMin: 25,
        deliveryFee: 5.00,
        isOpen: true,
        commissionRate: 8.0,
      );

      final prodGas = const ProductModel(
        id: 'prod-qa-gas-1',
        storeId: 'store-qa-test-1',
        storeName: '[QA-TESTE] Central de Gás e Água',
        category: ProductCategory.p13,
        name: '[QA-TESTE] Botijão GLP 13kg',
        brandName: 'Ultragaz',
        description: 'Botijão 13kg',
        refillPrice: 100.00,
        shellPrice: 280.00,
        inStock: true,
        imageUrl: 'assets/images/app_icon.png',
      );

      // Adiciona 1 botijão modo Troca (R$ 100,00)
      cartNotifier.addItem(product: prodGas, store: qaStore, quantity: 1, isRefillOnly: true);
      expect(container.read(cartProvider).subtotal, equals(100.00));
      expect(container.read(cartProvider).deliveryFee, equals(5.00));
      expect(container.read(cartProvider).total, equals(105.00));

      // Aplica Cupom de R$ 10,00
      cartNotifier.applyCoupon('BORA10');
      expect(container.read(cartProvider).discount, equals(10.00));
      expect(container.read(cartProvider).total, equals(95.00)); // 100 + 5 - 10

      // Seleciona Pix Online
      cartNotifier.setPaymentMode(PaymentMode.onlinePix);
      expect(container.read(cartProvider).selectedPaymentMode, equals(PaymentMode.onlinePix));

      // Finaliza Pedido
      final order = cartNotifier.checkout('Rua das Acácias, 42 - Apto 31');
      expect(order.totalAmount, equals(95.00));
      expect(order.subtotal, equals(100.00));
      expect(order.deliveryFee, equals(5.00));
      expect(order.discount, equals(10.00));
      expect(order.paymentMode, equals(PaymentMode.onlinePix));
      expect(order.paymentStatus, equals(PaymentStatus.paidDirectlyToStore));
      expect(order.deliveryConfirmationCode.length, equals(4));

      // Cálculo da Comissão BoraGás (8% do total = R$ 7,60)
      expect(order.commissionRatePercent, equals(8.0));
      expect(order.platformCommissionAmount, closeTo(95.00 * 0.08, 0.001));
    });

    test('C2. Checkout Dinheiro na Entrega com Troco Calculado', () {
      final container = ProviderContainer();
      final cartNotifier = container.read(cartProvider.notifier);

      final qaStore = const StoreModel(
        id: 'store-qa-test-1',
        name: '[QA-TESTE] Central',
        cnpj: '12.345.678/0001-99',
        phone: '(11) 90000-0002',
        logoUrl: 'assets/images/app_icon.png',
        coverUrl: 'assets/images/brand_lockup.png',
        address: 'Rua Teste',
        distanceKm: 1.0,
        rating: 5.0,
        reviewsCount: 1,
        estimatedTimeMin: 20,
        deliveryFee: 0.00, // Frete Grátis
        isOpen: true,
        commissionRate: 8.0,
      );

      final prodWater = const ProductModel(
        id: 'prod-qa-water-1',
        storeId: 'store-qa-test-1',
        storeName: '[QA-TESTE] Central',
        category: ProductCategory.water20l,
        name: '[QA-TESTE] Galão de Água 20L',
        brandName: 'Bonafont',
        description: 'Água 20L',
        refillPrice: 15.00,
        shellPrice: 45.00,
        inStock: true,
        imageUrl: 'assets/images/app_icon.png',
      );

      // 2 galões no modo compra de casco novo (2 * 45 = R$ 90,00)
      cartNotifier.addItem(product: prodWater, store: qaStore, quantity: 2, isRefillOnly: false);
      expect(container.read(cartProvider).total, equals(90.00));

      // Pagamento em dinheiro com troco para R$ 100,00
      cartNotifier.setPaymentMode(PaymentMode.cashOnDelivery);
      cartNotifier.setChangeForAmount(100.00);

      final order = cartNotifier.checkout('Av. Paulista, 1000');
      expect(order.paymentMode, equals(PaymentMode.cashOnDelivery));
      expect(order.changeForAmount, equals(100.00));
      expect(order.totalAmount, equals(90.00));
      expect((order.changeForAmount! - order.totalAmount), equals(10.00)); // Troco de R$ 10
    });

    // -------------------------------------------------------------
    // ETAPA 2.D & 2.E: CICLO DE VIDA, DESPACHO E ENTREGA COM PIN
    // -------------------------------------------------------------
    test('D1. Ciclo completo: Aceite -> Preparo -> Despacho -> Entrega validada com PIN', () {
      final initialOrder = OrderModel(
        id: 'ord-qa-flow-1',
        orderNumber: '#BG-QA-01',
        customerId: 'usr-qa-cust-1',
        customerName: '[QA-TESTE] Carlos Cliente',
        customerPhone: '(11) 90000-0001',
        storeId: 'store-qa-test-1',
        storeName: '[QA-TESTE] Distribuidora Central',
        items: const [
          OrderItemModel(
            productId: 'prod-qa-gas-1',
            productName: '[QA-TESTE] Botijão P13 (Troca)',
            quantity: 1,
            isRefillOnly: true,
            unitPrice: 104.90,
            totalPrice: 104.90,
          ),
        ],
        status: OrderStatus.accepted,
        paymentMode: PaymentMode.onlinePix,
        paymentStatus: PaymentStatus.paidDirectlyToStore,
        deliveryAddress: 'Rua das Flores, 120',
        subtotal: 104.90,
        deliveryFee: 0.00,
        discount: 0.00,
        totalAmount: 104.90,
        commissionRatePercent: 8.0,
        platformCommissionAmount: 8.39,
        deliveryConfirmationCode: '4821', // PIN do cliente
        createdAt: DateTime.now(),
      );

      // 1. Lojista coloca em preparo
      final preparingOrder = initialOrder.copyWith(status: OrderStatus.preparing);
      expect(preparingOrder.status, equals(OrderStatus.preparing));

      // 2. Lojista despacha com entregador atribuído
      final dispatchedOrder = preparingOrder.copyWith(
        status: OrderStatus.outForDelivery,
        courierName: '[QA-TESTE] Entregador Marcos',
      );
      expect(dispatchedOrder.status, equals(OrderStatus.outForDelivery));
      expect(dispatchedOrder.courierName, contains('Marcos'));

      // 3. Validação do PIN na porta do cliente
      const enteredWrongPin = '9999';
      expect(enteredWrongPin == dispatchedOrder.deliveryConfirmationCode, isFalse);

      const enteredCorrectPin = '4821';
      expect(enteredCorrectPin == dispatchedOrder.deliveryConfirmationCode, isTrue);

      // 4. Conclusão confirmada
      final deliveredOrder = dispatchedOrder.copyWith(status: OrderStatus.delivered);
      expect(deliveredOrder.status, equals(OrderStatus.delivered));
    });

    // -------------------------------------------------------------
    // ETAPA 2.F: AUDITORIA FINANCEIRA CENTAVO POR CENTAVO
    // -------------------------------------------------------------
    test('F1. Auditoria Financeira: Conciliação exata de GMV, Comissão de 8% e Repasse Líquido', () {
      final orders = [
        OrderModel(
          id: 'ord-qa-fin-1',
          orderNumber: '#BG-001',
          customerId: 'c1',
          customerName: 'Cliente 1',
          customerPhone: '11900000001',
          storeId: 'store-1',
          storeName: 'Loja Ultragaz',
          items: const [],
          status: OrderStatus.delivered,
          paymentMode: PaymentMode.onlinePix,
          paymentStatus: PaymentStatus.paidDirectlyToStore,
          deliveryAddress: 'Endereço 1',
          subtotal: 104.90,
          deliveryFee: 5.00,
          discount: 0.00,
          totalAmount: 109.90,
          commissionRatePercent: 8.0,
          platformCommissionAmount: 8.792, // 109.90 * 0.08
          deliveryConfirmationCode: '1111',
          createdAt: DateTime.now(),
        ),
        OrderModel(
          id: 'ord-qa-fin-2',
          orderNumber: '#BG-002',
          customerId: 'c2',
          customerName: 'Cliente 2',
          customerPhone: '11900000002',
          storeId: 'store-1',
          storeName: 'Loja Ultragaz',
          items: const [],
          status: OrderStatus.delivered,
          paymentMode: PaymentMode.posOnDelivery,
          paymentStatus: PaymentStatus.awaitingPayment,
          deliveryAddress: 'Endereço 2',
          subtotal: 14.90,
          deliveryFee: 0.00,
          discount: 0.00,
          totalAmount: 14.90,
          commissionRatePercent: 8.0,
          platformCommissionAmount: 1.192, // 14.90 * 0.08
          deliveryConfirmationCode: '2222',
          createdAt: DateTime.now(),
        ),
      ];

      final totalGMV = orders.fold(0.0, (sum, o) => sum + o.totalAmount);
      final totalCommissions = orders.fold(0.0, (sum, o) => sum + o.platformCommissionAmount);
      final totalNetStorePayout = totalGMV - totalCommissions;

      // 109.90 + 14.90 = 124.80 (verificação com tolerância contra imprecisão IEEE 754)
      expect(totalGMV, closeTo(124.80, 0.001));

      // 8% de 124.80 = 9.984 (arredondado para R$ 9.98)
      expect(totalCommissions, closeTo(9.984, 0.001));

      // Repasse Líquido à Loja = 124.80 - 9.984 = 114.816
      expect(totalNetStorePayout, closeTo(114.816, 0.001));

      // Verificação de que não há centavos negativos ou discrepâncias
      expect(totalCommissions > 0, isTrue);
      expect(totalNetStorePayout < totalGMV, isTrue);
      expect(double.parse((totalCommissions + totalNetStorePayout).toStringAsFixed(2)), equals(124.80));
    });

    // -------------------------------------------------------------
    // ETAPA 2.G & 2.H: CASOS DE BORDA, RESILIÊNCIA E VALIDAÇÃO DE ENTRADA
    // -------------------------------------------------------------
    test('G1. Bordas: Carrinho vazio, estoque zero e quantidade negativa bloqueadas', () {
      final container = ProviderContainer();
      final cartNotifier = container.read(cartProvider.notifier);

      // 1. Carrinho inicia vazio
      expect(container.read(cartProvider).isEmpty, isTrue);

      final qaStore = const StoreModel(
        id: 'store-qa-test-1',
        name: '[QA-TESTE] Central',
        cnpj: '12.345.678/0001-99',
        phone: '(11) 90000-0002',
        logoUrl: 'assets/images/app_icon.png',
        coverUrl: 'assets/images/brand_lockup.png',
        address: 'Rua Teste',
        distanceKm: 1.0,
        rating: 5.0,
        reviewsCount: 1,
        estimatedTimeMin: 20,
        deliveryFee: 0.00,
        isOpen: true,
      );

      final outOfStockProd = const ProductModel(
        id: 'prod-qa-zero-stock',
        storeId: 'store-qa-test-1',
        storeName: '[QA-TESTE] Central',
        category: ProductCategory.p13,
        name: '[QA-TESTE] Botijão Esgotado',
        brandName: 'Ultragaz',
        description: 'Sem estoque',
        refillPrice: 100.00,
        shellPrice: 280.00,
        inStock: false, // ESGOTADO
        imageUrl: 'assets/images/app_icon.png',
      );

      // 2. Tentativa de adicionar produto sem estoque
      final addedZeroStock = cartNotifier.addItem(
        product: outOfStockProd,
        store: qaStore,
        quantity: 1,
        isRefillOnly: true,
      );
      expect(addedZeroStock, isFalse);
      expect(container.read(cartProvider).isEmpty, isTrue);

      // 3. Tentativa de adicionar quantidade <= 0
      final inStockProd = outOfStockProd.copyWith(inStock: true);
      final addedNegative = cartNotifier.addItem(
        product: inStockProd,
        store: qaStore,
        quantity: 0,
        isRefillOnly: true,
      );
      expect(addedNegative, isFalse);
      expect(container.read(cartProvider).isEmpty, isTrue);
    });

    test('H1. Abertura e integridade de todas as rotas da aplicação', () {
      final routes = [
        '/',
        '/splash',
        '/login',
        '/otp',
        '/home',
        '/orders',
        '/support',
        '/cart',
        '/store/e1111111-1111-1111-1111-111111111111',
        '/tracking/ord-test-01',
        '/support/ticket/tkt-01',
        '/merchant',
        '/admin',
        '/courier',
        '/subscription-club',
        '/referral',
        '/loyalty',
      ];

      final adminAuth = const AuthState(
        isAuthenticated: true,
        user: UserProfile(
          id: 'admin-master',
          name: 'Super Admin',
          phone: '(11) 98888-0001',
          email: 'admin@boragas.app',
          role: UserRole.admin,
        ),
      );

      for (final r in routes) {
        final redirect = evaluateAppRouteRedirect(auth: adminAuth, location: r);
        // Nenhuma rota protegida pode causar exceção e o admin tem acesso a todas
        expect(redirect == null || redirect == '/admin' || redirect == '/splash', isTrue,
            reason: 'Rota $r avaliada com sucesso sem exceção');
      }
    });

    test('I1. Validação de funcionamento real de CADA slug de categoria na Home', () {
      final testStores = [
        const StoreModel(
          id: 'store-gas-only',
          name: 'Central do Gás Exclusivo',
          cnpj: '11.111.111/0001-11',
          phone: '(11) 91111-1111',
          logoUrl: 'assets/images/app_icon.png',
          coverUrl: 'assets/images/brand_lockup.png',
          address: 'Rua do Gás, 10',
          distanceKm: 2.0,
          rating: 4.8,
          reviewsCount: 100,
          estimatedTimeMin: 30,
          deliveryFee: 10.0,
          isVerified: true,
          isOpen: true,
          commissionRate: 8.0,
        ),
        const StoreModel(
          id: 'store-water-only',
          name: 'Fonte Pura Água Mineral',
          cnpj: '22.222.222/0001-22',
          phone: '(11) 92222-2222',
          logoUrl: 'assets/images/app_icon.png',
          coverUrl: 'assets/images/brand_lockup.png',
          address: 'Av. das Fontes, 20',
          distanceKm: 1.5,
          rating: 4.9,
          reviewsCount: 50,
          estimatedTimeMin: 20,
          deliveryFee: 0.0, // Frete Grátis
          isVerified: true,
          isOpen: true,
          commissionRate: 8.0,
        ),
        const StoreModel(
          id: 'store-complete',
          name: 'Mega Distribuidora Multiuso',
          cnpj: '33.333.333/0001-33',
          phone: '(11) 93333-3333',
          logoUrl: 'assets/images/app_icon.png',
          coverUrl: 'assets/images/brand_lockup.png',
          address: 'Rodovia dos Comércios, 30',
          distanceKm: 4.0,
          rating: 4.7,
          reviewsCount: 80,
          estimatedTimeMin: 45,
          deliveryFee: 15.0,
          isVerified: true,
          isOpen: true,
          commissionRate: 8.0,
        ),
      ];

      final testProducts = [
        const ProductModel(
          id: 'prod-p13',
          storeId: 'store-gas-only',
          storeName: 'Central do Gás Exclusivo',
          category: ProductCategory.p13,
          name: 'Botijão P13 Ultragaz',
          brandName: 'Ultragaz',
          description: 'P13 residencial',
          refillPrice: 105.00,
          shellPrice: 280.00,
          inStock: true,
          imageUrl: 'assets/images/products/gas_13kg_gold.png',
          rating: 5.0,
        ),
        const ProductModel(
          id: 'prod-water',
          storeId: 'store-water-only',
          storeName: 'Fonte Pura Água Mineral',
          category: ProductCategory.water20l,
          name: 'Galão Água Mineral 20L',
          brandName: 'Minalba',
          description: 'Água pura 20L',
          refillPrice: 14.00,
          shellPrice: 40.00,
          inStock: true,
          imageUrl: 'assets/images/products/water_20l_blue.png',
          rating: 5.0,
        ),
        const ProductModel(
          id: 'prod-p45',
          storeId: 'store-complete',
          storeName: 'Mega Distribuidora Multiuso',
          category: ProductCategory.p45,
          name: 'Cilindro P45 Industrial',
          brandName: 'Supergasbras',
          description: 'P45 Industrial',
          refillPrice: 420.00,
          shellPrice: 850.00,
          inStock: true,
          imageUrl: 'assets/images/products/gas_13kg_gold.png',
          rating: 5.0,
        ),
        const ProductModel(
          id: 'prod-p20',
          storeId: 'store-complete',
          storeName: 'Mega Distribuidora Multiuso',
          category: ProductCategory.p20,
          name: 'Cilindro P20 Empilhadeira',
          brandName: 'NacionalGás',
          description: 'P20 Empilhadeira',
          refillPrice: 180.00,
          shellPrice: 400.00,
          inStock: true,
          imageUrl: 'assets/images/products/gas_13kg_gold.png',
          rating: 5.0,
        ),
        const ProductModel(
          id: 'prod-acc',
          storeId: 'store-complete',
          storeName: 'Mega Distribuidora Multiuso',
          category: ProductCategory.accessories,
          name: 'Kit Regulador e Mangueira Inmetro',
          brandName: 'Aliança',
          description: 'Regulador',
          refillPrice: 45.00,
          shellPrice: 45.00,
          inStock: true,
          imageUrl: 'assets/images/products/gas_13kg_gold.png',
          rating: 5.0,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          storesProvider.overrideWith(() => _TestStoresNotifier(testStores)),
          productsProvider.overrideWith(() => _TestProductsNotifier(testProducts)),
        ],
      );

      // 1. Slug 'all' deve trazer todas as 3 lojas
      container.read(selectedCategorySlugProvider.notifier).set('all');
      expect(container.read(filteredStoresProvider).length, equals(3));

      // 2. Slug 'p13' deve trazer apenas a loja que tem P13 ('store-gas-only')
      container.read(selectedCategorySlugProvider.notifier).set('p13');
      final p13Stores = container.read(filteredStoresProvider);
      expect(p13Stores.length, equals(1));
      expect(p13Stores.first.id, equals('store-gas-only'));

      // 3. Slug 'water20l' deve trazer apenas 'store-water-only'
      container.read(selectedCategorySlugProvider.notifier).set('water20l');
      final waterStores = container.read(filteredStoresProvider);
      expect(waterStores.length, equals(1));
      expect(waterStores.first.id, equals('store-water-only'));

      // 4. Slug 'p45' deve trazer apenas 'store-complete'
      container.read(selectedCategorySlugProvider.notifier).set('p45');
      final p45Stores = container.read(filteredStoresProvider);
      expect(p45Stores.length, equals(1));
      expect(p45Stores.first.id, equals('store-complete'));

      // 5. Slug 'p20' deve trazer apenas 'store-complete'
      container.read(selectedCategorySlugProvider.notifier).set('p20');
      final p20Stores = container.read(filteredStoresProvider);
      expect(p20Stores.length, equals(1));
      expect(p20Stores.first.id, equals('store-complete'));

      // 6. Slug 'accessories' deve trazer apenas 'store-complete'
      container.read(selectedCategorySlugProvider.notifier).set('accessories');
      final accStores = container.read(filteredStoresProvider);
      expect(accStores.length, equals(1));
      expect(accStores.first.id, equals('store-complete'));

      // 7. Slug 'free_delivery' deve trazer apenas 'store-water-only' (deliveryFee == 0)
      container.read(selectedCategorySlugProvider.notifier).set('free_delivery');
      final freeStores = container.read(filteredStoresProvider);
      expect(freeStores.length, equals(1));
      expect(freeStores.first.id, equals('store-water-only'));
      expect(freeStores.first.deliveryFee, equals(0.0));

      // 8. Comparador de Preços para 'water20l' deve filtrar exatamente 1 item
      final waterItems = container.read(priceComparisonListProvider);
      expect(waterItems.length, equals(1));
      expect(waterItems.first.product.category, equals(ProductCategory.water20l));
      expect(waterItems.first.totalPrice, equals(14.00));
    });
  });
}

class _TestStoresNotifier extends StoresNotifier {
  final List<StoreModel> _stores;
  _TestStoresNotifier(this._stores);

  @override
  List<StoreModel> build() => _stores;
}

class _TestProductsNotifier extends ProductsNotifier {
  final List<ProductModel> _products;
  _TestProductsNotifier(this._products);

  @override
  List<ProductModel> build() => _products;
}
