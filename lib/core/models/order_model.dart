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

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    OrderStatus parseStatus(String? s) {
      if (s == null) return OrderStatus.accepted;
      return OrderStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == s.toLowerCase(),
        orElse: () => OrderStatus.accepted,
      );
    }

    PaymentMode parsePaymentMode(String? m) {
      if (m == null) return PaymentMode.posOnDelivery;
      return PaymentMode.values.firstWhere(
        (e) => e.name.toLowerCase() == m.toLowerCase(),
        orElse: () => PaymentMode.posOnDelivery,
      );
    }

    PaymentStatus parsePaymentStatus(String? ps) {
      if (ps == null) return PaymentStatus.awaitingPayment;
      return PaymentStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == ps.toLowerCase(),
        orElse: () => PaymentStatus.awaitingPayment,
      );
    }

    List<OrderItemModel> parseItems(dynamic rawItems) {
      if (rawItems is! List) return const [];
      return rawItems.map((item) {
        if (item is! Map) return null;
        final m = Map<String, dynamic>.from(item);
        return OrderItemModel(
          productId: m['product_id']?.toString() ?? '',
          productName: m['product_name']?.toString() ?? 'Produto',
          quantity: (m['quantity'] as num?)?.toInt() ?? 1,
          isRefillOnly: m['is_refill_only'] == true,
          unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0.0,
          totalPrice: (m['total_price'] as num?)?.toDouble() ?? 0.0,
        );
      }).whereType<OrderItemModel>().toList();
    }

    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '#BG-0000',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Cliente',
      customerPhone: json['customer_phone']?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '',
      storeName: json['store_name']?.toString() ?? '',
      items: parseItems(json['items']),
      status: parseStatus(json['status']?.toString()),
      paymentMode: parsePaymentMode(json['payment_mode']?.toString()),
      paymentStatus: parsePaymentStatus(json['payment_status']?.toString()),
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      changeForAmount: (json['change_for_amount'] as num?)?.toDouble(),
      commissionRatePercent: (json['commission_rate_percent'] as num?)?.toDouble() ?? 8.0,
      platformCommissionAmount: (json['platform_commission_amount'] as num?)?.toDouble() ?? 0.0,
      deliveryConfirmationCode: json['delivery_confirmation_code']?.toString() ?? '0000',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'].toString())
          : null,
      courierName: json['courier_name']?.toString(),
      courierPhone: json['courier_phone']?.toString(),
    );
  }
}
