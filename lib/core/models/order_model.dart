enum OrderStatus {
  pending,
  accepted,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

enum PaymentMode {
  onlinePix,
  onlineCard,
  posOnDelivery,
  cashOnDelivery,
}

enum PaymentStatus {
  awaitingPayment,
  paidDirectlyToStore,
  failed,
  refunded,
}

class OrderItemModel {
  final String productId;
  final String productName;
  final int quantity;
  final bool isRefillOnly; // true = tem casco, false = comprar casco junto
  final double unitPrice;
  final double totalPrice;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.isRefillOnly,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String storeId;
  final String storeName;
  final List<OrderItemModel> items;
  final OrderStatus status;
  final PaymentMode paymentMode;
  final PaymentStatus paymentStatus;
  final String deliveryAddress;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double totalAmount;
  final double? changeForAmount;
  final double commissionRatePercent;
  final double platformCommissionAmount;
  final String deliveryConfirmationCode;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? courierName;
  final String? courierPhone;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.storeId,
    required this.storeName,
    required this.items,
    required this.status,
    required this.paymentMode,
    required this.paymentStatus,
    required this.deliveryAddress,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0.0,
    required this.totalAmount,
    this.changeForAmount,
    required this.commissionRatePercent,
    required this.platformCommissionAmount,
    required this.deliveryConfirmationCode,
    required this.createdAt,
    this.deliveredAt,
    this.courierName,
    this.courierPhone,
  });

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? storeId,
    String? storeName,
    List<OrderItemModel>? items,
    OrderStatus? status,
    PaymentMode? paymentMode,
    PaymentStatus? paymentStatus,
    String? deliveryAddress,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? totalAmount,
    double? changeForAmount,
    double? commissionRatePercent,
    double? platformCommissionAmount,
    String? deliveryConfirmationCode,
    DateTime? createdAt,
    DateTime? deliveredAt,
    String? courierName,
    String? courierPhone,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      items: items ?? this.items,
      status: status ?? this.status,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      changeForAmount: changeForAmount ?? this.changeForAmount,
      commissionRatePercent:
          commissionRatePercent ?? this.commissionRatePercent,
      platformCommissionAmount:
          platformCommissionAmount ?? this.platformCommissionAmount,
      deliveryConfirmationCode:
          deliveryConfirmationCode ?? this.deliveryConfirmationCode,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
    );
  }
}
