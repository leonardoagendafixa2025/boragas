import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/store_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'customer_providers.dart';

class CartItem {
  final ProductModel product;
  final int quantity;
  final bool isRefillOnly;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.isRefillOnly,
  });

  double get unitPrice =>
      isRefillOnly ? product.refillPrice : product.shellPrice;

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({
    ProductModel? product,
    int? quantity,
    bool? isRefillOnly,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      isRefillOnly: isRefillOnly ?? this.isRefillOnly,
    );
  }
}

class CartState {
  final StoreModel? store;
  final List<CartItem> items;
  final String? appliedCoupon;
  final double discount;
  final PaymentMode selectedPaymentMode;
  final double? changeForAmount;
  final String? notes;

  const CartState({
    this.store,
    this.items = const [],
    this.appliedCoupon,
    this.discount = 0.0,
    this.selectedPaymentMode = PaymentMode.onlinePix,
    this.changeForAmount,
    this.notes,
  });

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee => store?.deliveryFee ?? 0.0;

  double get total =>
      (subtotal + deliveryFee - discount).clamp(0.0, double.infinity);

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    StoreModel? store,
    List<CartItem>? items,
    String? appliedCoupon,
    double? discount,
    PaymentMode? selectedPaymentMode,
    double? changeForAmount,
    String? notes,
    bool clearCoupon = false,
  }) {
    return CartState(
      store: store ?? this.store,
      items: items ?? this.items,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      discount: clearCoupon ? 0.0 : (discount ?? this.discount),
      selectedPaymentMode: selectedPaymentMode ?? this.selectedPaymentMode,
      changeForAmount: changeForAmount ?? this.changeForAmount,
      notes: notes ?? this.notes,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  bool addItem({
    required ProductModel product,
    required StoreModel store,
    required int quantity,
    required bool isRefillOnly,
  }) {
    if (quantity <= 0 || !product.inStock) {
      return false; // Bloqueio de segurança: impede adicionar produto sem estoque ou quantidade <= 0
    }

    if (state.store != null &&
        state.store!.id != store.id &&
        state.items.isNotEmpty) {
      return false; // Indicates store conflict
    }

    final existingIndex = state.items.indexWhere((i) =>
        i.product.id == product.id && i.isRefillOnly == isRefillOnly);

    List<CartItem> updatedItems = List.from(state.items);
    if (existingIndex >= 0) {
      final current = updatedItems[existingIndex];
      updatedItems[existingIndex] = current.copyWith(
        quantity: current.quantity + quantity,
      );
    } else {
      updatedItems.add(
        CartItem(
          product: product,
          quantity: quantity,
          isRefillOnly: isRefillOnly,
        ),
      );
    }

    state = state.copyWith(
      store: store,
      items: updatedItems,
    );
    return true;
  }

  void updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(index);
      return;
    }

    final updatedItems = List<CartItem>.from(state.items);
    updatedItems[index] = updatedItems[index].copyWith(quantity: newQuantity);
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(int index) {
    final updatedItems = List<CartItem>.from(state.items);
    updatedItems.removeAt(index);

    if (updatedItems.isEmpty) {
      state = const CartState();
    } else {
      state = state.copyWith(items: updatedItems);
    }
  }

  bool applyCoupon(String code) {
    final clean = code.trim().toUpperCase();
    if (clean == 'BORAGAS10' || clean == 'BORA10' || clean == 'BORAVIZINHO10') {
      state = state.copyWith(
        appliedCoupon: clean,
        discount: 10.0,
      );
      return true;
    } else if (clean == 'PRIMEIRACOMPRA' || clean == 'BEMVINDO' || clean == 'RELAMPAGO15') {
      state = state.copyWith(
        appliedCoupon: clean,
        discount: 15.0,
      );
      return true;
    } else if (clean == 'COMBOTOP') {
      state = state.copyWith(
        appliedCoupon: clean,
        discount: 12.0,
      );
      return true;
    } else if (clean == 'FIMDESEMANA5') {
      state = state.copyWith(
        appliedCoupon: clean,
        discount: 5.0,
      );
      return true;
    }
    return false;
  }

  void removeCoupon() {
    state = state.copyWith(clearCoupon: true);
  }

  void setPaymentMode(PaymentMode mode) {
    state = state.copyWith(selectedPaymentMode: mode);
  }

  void setChangeForAmount(double? amount) {
    state = state.copyWith(changeForAmount: amount);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void clearCart() {
    state = const CartState();
  }

  OrderModel checkout(String deliveryAddress) {
    final store = state.store!;
    final commissionPercent = store.commissionRate;
    final commissionAmount = state.total * (commissionPercent / 100);

    final auth = ref.read(authProvider);
    final currentCustomer = auth.user;
    final customerId = currentCustomer?.id ?? 'usr-001';
    final customerName = currentCustomer?.name ?? 'Cliente BoraGás';
    final customerPhone = currentCustomer?.phone ?? '(11) 98122-3344';

    final newOrder = OrderModel(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      orderNumber: '#BG-${(1000 + (DateTime.now().millisecond * 7) % 9000)}',
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      storeId: store.id,
      storeName: store.name,
      items: state.items
          .map((i) => OrderItemModel(
                productId: i.product.id,
                productName:
                    '${i.product.name} (${i.isRefillOnly ? 'Troca' : 'Comprar Casco'})',
                quantity: i.quantity,
                isRefillOnly: i.isRefillOnly,
                unitPrice: i.unitPrice,
                totalPrice: i.totalPrice,
              ))
          .toList(),
      status: OrderStatus.accepted,
      paymentMode: state.selectedPaymentMode,
      paymentStatus: state.selectedPaymentMode == PaymentMode.onlinePix ||
              state.selectedPaymentMode == PaymentMode.onlineCard
          ? PaymentStatus.paidDirectlyToStore
          : PaymentStatus.awaitingPayment,
      deliveryAddress: deliveryAddress,
      subtotal: state.subtotal,
      deliveryFee: state.deliveryFee,
      discount: state.discount,
      totalAmount: state.total,
      changeForAmount: state.changeForAmount,
      commissionRatePercent: commissionPercent,
      platformCommissionAmount: commissionAmount,
      deliveryConfirmationCode:
          (1000 + (DateTime.now().millisecond * 9) % 9000).toString(),
      createdAt: DateTime.now(),
      courierName: 'Entregador em designação...',
    );

    ref.read(ordersProvider.notifier).update((orders) => [newOrder, ...orders]);

    if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
      SupabaseService.client.from('orders').insert({
        'id': newOrder.id,
        'order_number': newOrder.orderNumber,
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'store_id': store.id,
        'store_name': store.name,
        'status': 'accepted',
        'payment_mode': newOrder.paymentMode.name,
        'payment_status': newOrder.paymentStatus.name,
        'delivery_address': deliveryAddress,
        'subtotal': newOrder.subtotal,
        'delivery_fee': newOrder.deliveryFee,
        'discount': newOrder.discount,
        'total_amount': newOrder.totalAmount,
        'commission_rate_percent': commissionPercent,
        'platform_commission_amount': commissionAmount,
        'delivery_confirmation_code': newOrder.deliveryConfirmationCode,
        'created_at': DateTime.now().toIso8601String(),
      }).catchError((err) {
        debugPrint('Aviso ao sincronizar pedido no Supabase: $err');
      });
    }

    clearCart();
    return newOrder;
  }
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
