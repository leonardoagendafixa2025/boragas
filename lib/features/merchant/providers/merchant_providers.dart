import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/commission_model.dart';
import '../../../core/models/payment_config_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/store_model.dart';
import '../../../core/services/supabase_service.dart';
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
  StorePaymentConfigModel build() {
    _loadFromSupabase();
    return MockDatabase.initialPaymentConfig;
  }

  Future<void> _loadFromSupabase() async {
    if (!SupabaseService.isConfigured || !SupabaseService.isInitialized) return;
    try {
      final currentStore = ref.read(currentMerchantStoreProvider);
      final res = await SupabaseService.client
          .from('store_payment_configs')
          .select('*')
          .eq('store_id', currentStore.id)
          .maybeSingle();

      if (res != null) {
        state = StorePaymentConfigModel(
          storeId: currentStore.id,
          gatewayProvider: res['gateway_provider'] ?? 'mercadopago',
          publicKey: res['public_key'] ?? '',
          accessToken: res['access_token'] ?? '',
          webhookSecret: res['webhook_secret'] ?? '',
          posTerminalProvider: res['pos_terminal_provider'] ?? 'Mercado Pago Point Smart',
          posDeviceSerialId: res['pos_device_serial_id'] ?? '',
          acceptsOnlinePix: res['accepts_online_pix'] ?? true,
          acceptsOnlineCard: res['accepts_online_card'] ?? true,
          acceptsPosOnDelivery: res['accepts_pos_on_delivery'] ?? true,
          acceptsCashOnDelivery: res['accepts_cash_on_delivery'] ?? true,
          isGatewayConnected: (res['access_token'] as String?)?.isNotEmpty == true,
        );
      }
    } catch (_) {}
  }

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
      isGatewayConnected: accessToken.isNotEmpty,
    );

    if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
      SupabaseService.client.from('store_payment_configs').upsert({
        'store_id': state.storeId,
        'gateway_provider': gatewayProvider,
        'public_key': publicKey,
        'access_token': accessToken,
        'webhook_secret': webhookSecret,
        'pos_terminal_provider': posTerminalProvider,
        'pos_device_serial_id': posDeviceSerialId,
        'accepts_online_pix': state.acceptsOnlinePix,
        'accepts_online_card': state.acceptsOnlineCard,
        'accepts_pos_on_delivery': state.acceptsPosOnDelivery,
        'accepts_cash_on_delivery': state.acceptsCashOnDelivery,
        'updated_at': DateTime.now().toIso8601String(),
      }).catchError((_) {});
    }
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
