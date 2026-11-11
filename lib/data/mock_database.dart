import '../core/models/banner_model.dart';
import '../core/models/commission_model.dart';
import '../core/models/order_model.dart';
import '../core/models/payment_config_model.dart';
import '../core/models/product_model.dart';
import '../core/models/store_model.dart';
import '../core/models/support_ticket_model.dart';

class MockDatabase {
  static final List<HomeBannerModel> initialBanners = [
    const HomeBannerModel(
      id: 'banner-1',
      title: 'Entrega Flash em 25 min ⚡',
      subtitle: 'Botijões P13 lacrados e testados na sua porta',
      badgeText: 'P13 RESIDENCIAL',
      imageUrl: 'assets/images/products/gas_13kg_gold.png',
      actionType: 'open_category',
      actionTarget: 'p13',
      isActive: true,
      sortOrder: 1,
    ),
    const HomeBannerModel(
      id: 'banner-2',
      title: 'Água Mineral 20L Lacrada 💧',
      subtitle: 'Galões retornáveis higienizados e de procedência',
      badgeText: 'ÁGUA PURA',
      imageUrl: 'assets/images/products/water_20l_blue.png',
      actionType: 'open_category',
      actionTarget: 'water20l',
      isActive: true,
      sortOrder: 2,
    ),
  ];

  static final List<HomeCategoryModel> initialCategories = [
    const HomeCategoryModel(
      id: 'cat-1',
      title: 'P13 Residencial',
      slug: 'p13',
      iconName: 'gas_cylinder',
      sortOrder: 1,
    ),
    const HomeCategoryModel(
      id: 'cat-2',
      title: 'Água 20L',
      slug: 'water20l',
      iconName: 'water_drop',
      sortOrder: 2,
    ),
    const HomeCategoryModel(
      id: 'cat-3',
      title: 'P45 Industrial',
      slug: 'p45',
      iconName: 'factory',
      sortOrder: 3,
    ),
    const HomeCategoryModel(
      id: 'cat-4',
      title: 'P20 Empilhadeira',
      slug: 'p20',
      iconName: 'forklift',
      sortOrder: 4,
    ),
    const HomeCategoryModel(
      id: 'cat-5',
      title: 'Regulador & Mangueira',
      slug: 'accessories',
      iconName: 'build_circle',
      sortOrder: 5,
    ),
    const HomeCategoryModel(
      id: 'cat-6',
      title: 'Menor Preço',
      slug: 'lowest_price',
      iconName: 'savings',
      sortOrder: 6,
    ),
    const HomeCategoryModel(
      id: 'cat-7',
      title: 'Entrega Grátis',
      slug: 'free_delivery',
      iconName: 'local_shipping',
      sortOrder: 7,
    ),
  ];

  // Lojas e Produtos reais iniciam vazios em produção (carregados via Supabase)
  static final List<StoreModel> initialStores = const <StoreModel>[];

  static final List<ProductModel> initialProducts = const <ProductModel>[];

  // Fixtures de amostra exclusivas para testes unitários automatizados
  static final List<StoreModel> sampleStoresForTesting = [
    const StoreModel(
      id: 'store-1',
      name: 'Ultragaz Paulistana Express',
      cnpj: '12.345.678/0001-90',
      phone: '(11) 98711-2233',
      logoUrl: 'assets/images/app_icon.png',
      coverUrl: 'assets/images/brand_lockup.png',
      address: 'Av. Paulista, 1200 - Bela Vista',
      distanceKm: 1.2,
      rating: 4.9,
      reviewsCount: 384,
      estimatedTimeMin: 22,
      deliveryFee: 0.0,
      isVerified: true,
      isOpen: true,
      commissionRate: 8.0,
    ),
    const StoreModel(
      id: 'store-2',
      name: 'Liquigás Central do Gás',
      cnpj: '98.765.432/0001-11',
      phone: '(11) 97654-3210',
      logoUrl: 'assets/images/app_icon_v2.png',
      coverUrl: 'assets/images/brand_lockup.png',
      address: 'Rua Augusta, 850 - Consolação',
      distanceKm: 2.1,
      rating: 4.8,
      reviewsCount: 219,
      estimatedTimeMin: 28,
      deliveryFee: 5.0,
      isVerified: true,
      isOpen: true,
      commissionRate: 8.0,
    ),
  ];

  static final List<ProductModel> sampleProductsForTesting = [
    const ProductModel(
      id: 'prod-1',
      storeId: 'store-1',
      storeName: 'Ultragaz Paulistana Express',
      category: ProductCategory.p13,
      name: 'Botijão de Gás P13 (13kg)',
      brandName: 'Ultragaz (Azul)',
      description: 'Botijão de cozinha tradicional com lacre de segurança e pesagem aferida.',
      refillPrice: 104.90,
      shellPrice: 289.00,
      inStock: true,
      imageUrl: 'assets/images/products/gas_13kg_gold.png',
      rating: 4.9,
    ),
  ];

  // Pedidos em produção iniciam vazios e são persistidos no Supabase
  static final List<OrderModel> initialOrders = const <OrderModel>[];

  // Pedidos de teste/amostra exclusivos para testes unitários ou de widget
  static final List<OrderModel> sampleOrdersForTesting = [
    OrderModel(
      id: 'ord-101',
      orderNumber: '#BG-8842',
      customerId: 'usr-001',
      customerName: 'Carlos Eduardo Silva',
      customerPhone: '(11) 98122-3344',
      storeId: 'store-1',
      storeName: 'Ultragaz Paulistana Express',
      items: const [
        OrderItemModel(
          productId: 'prod-1',
          productName: 'Botijão P13 (13kg) - Troca de Vasilhame',
          quantity: 1,
          isRefillOnly: true,
          unitPrice: 104.90,
          totalPrice: 104.90,
        ),
      ],
      status: OrderStatus.outForDelivery,
      paymentMode: PaymentMode.onlinePix,
      paymentStatus: PaymentStatus.paidDirectlyToStore,
      deliveryAddress: 'Av. Brigadeiro Luís Antônio, 2344 - Apto 82',
      subtotal: 104.90,
      deliveryFee: 0.0,
      discount: 10.0,
      totalAmount: 94.90,
      commissionRatePercent: 8.0,
      platformCommissionAmount: 7.59,
      deliveryConfirmationCode: '4921',
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      courierName: 'Marcos Oliveira (Moto Fan 160)',
      courierPhone: '(11) 97722-1199',
    ),
  ];

  static final StorePaymentConfigModel initialPaymentConfig =
      const StorePaymentConfigModel(
    storeId: 'store-1',
    gatewayProvider: 'mercadopago',
    publicKey: '',
    accessToken: '',
    webhookSecret: '',
    posTerminalProvider: 'Mercado Pago Point Smart',
    posDeviceSerialId: '',
    acceptsOnlinePix: true,
    acceptsOnlineCard: true,
    acceptsPosOnDelivery: true,
    acceptsCashOnDelivery: true,
    isGatewayConnected: false,
  );

  // Faturas e tickets reais iniciam vazios em produção
  static final List<CommissionInvoiceModel> initialInvoices = const <CommissionInvoiceModel>[];

  static final List<SupportTicketModel> initialTickets = const <SupportTicketModel>[];
}
