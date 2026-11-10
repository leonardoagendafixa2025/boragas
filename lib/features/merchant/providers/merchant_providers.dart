import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/commission_model.dart';
import '../../../core/models/payment_config_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/store_model.dart';
import '../../../data/mock_database.dart';
import '../../customer/providers/customer_providers.dart';

// Currently logged in merchant store (Defaults to Ultragaz Paulistana store-1)
class CurrentMerchantStoreNotifier extends Notifier<StoreModel> {
  @override
  StoreModel build() {
    final stores = ref.watch(storesProvider);
    return stores.firstWhere((s) => s.id == 'store-1', orElse: () => stores.first);
  }

  void set(StoreModel s) => state = s;
}

final currentMerchantStoreProvider =
    NotifierProvider<CurrentMerchantStoreNotifier, StoreModel>(
  CurrentMerchantStoreNotifier.new,
);

// Store Payment Config Provider
final storePaymentConfigProvider =
    NotifierProvider<StorePaymentConfigNotifier, StorePaymentConfigModel>(
  StorePaymentConfigNotifier.new,
);

class StorePaymentConfigNotifier extends Notifier<StorePaymentConfigModel> {
  @override
  StorePaymentConfigModel build() => MockDatabase.initialPaymentConfig;

  void updateConfig(StorePaymentConfigModel newConfig) {
    state = newConfig;
  }

  void testAndConnect({
    required String gatewayProvider,
    required String publicKey,
    required String accessToken,
    required String webhookSecret,
    required String posTerminalProvider,
    required String posDeviceSerialId,
  }) {
    state = state.copyWith(
      gatewayProvider: gatewayProvider,
      publicKey: publicKey,
      accessToken: accessToken,
      webhookSecret: webhookSecret,
      posTerminalProvider: posTerminalProvider,
      posDeviceSerialId: posDeviceSerialId,
      isGatewayConnected: true,
    );
  }

  void toggleOnlinePix(bool val) => state = state.copyWith(acceptsOnlinePix: val);
  void toggleOnlineCard(bool val) => state = state.copyWith(acceptsOnlineCard: val);
  void togglePosOnDelivery(bool val) => state = state.copyWith(acceptsPosOnDelivery: val);
  void toggleCashOnDelivery(bool val) => state = state.copyWith(acceptsCashOnDelivery: val);
}

// Invoices Provider for Merchant & Admin
final commissionInvoicesProvider =
    NotifierProvider<CommissionInvoicesNotifier, List<CommissionInvoiceModel>>(
  CommissionInvoicesNotifier.new,
);

class CommissionInvoicesNotifier extends Notifier<List<CommissionInvoiceModel>> {
  @override
  List<CommissionInvoiceModel> build() =>
      List.from(MockDatabase.initialInvoices);

  void payInvoice(String invoiceId) {
    state = state.map((inv) {
      if (inv.id == invoiceId) {
        return inv.copyWith(status: InvoiceStatus.paid);
      }
      return inv;
    }).toList();
  }
}

// Filtered products for current merchant
final merchantProductsProvider = Provider<List<ProductModel>>((ref) {
  final currentStore = ref.watch(currentMerchantStoreProvider);
  final allProducts = ref.watch(productsProvider);
  return allProducts.where((p) => p.storeId == currentStore.id).toList();
});
