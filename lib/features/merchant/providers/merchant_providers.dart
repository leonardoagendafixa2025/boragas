import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/commission_model.dart';
import '../../../core/models/payment_config_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/store_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/mock_database.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/providers/customer_providers.dart';

// Currently logged in merchant store (Vinculada à loja real do comerciante)
class CurrentMerchantStoreNotifier extends Notifier<StoreModel> {
  String? _selectedStoreId;
  bool? _overrideIsOpen;

  @override
  StoreModel build() {
    final stores = ref.watch(storesProvider);
    final auth = ref.watch(authProvider);
    final userStoreId = auth.user?.storeId;

    if (stores.isEmpty) {
      return StoreModel(
        id: _selectedStoreId ?? userStoreId ?? 'store-merchant-1',
        name: auth.user?.name.isNotEmpty == true && auth.user?.name != 'Usuário BoraGás'
            ? auth.user!.name
            : 'Minha Distribuidora',
        cnpj: '00.000.000/0001-00',
        phone: auth.user?.phone.isNotEmpty == true ? auth.user!.phone : '(11) 98765-4321',
        logoUrl: 'assets/images/app_icon.png',
        coverUrl: 'assets/images/brand_lockup.png',
        address: auth.user?.address ?? 'São Paulo - SP',
        distanceKm: 2.0,
        rating: 5.0,
        reviewsCount: 1,
        estimatedTimeMin: 25,
        deliveryFee: 0.0,
        isVerified: true,
        isOpen: _overrideIsOpen ?? true,
        commissionRate: 8.0,
      );
    }

    final targetId = _selectedStoreId ?? userStoreId ?? stores.first.id;
    _selectedStoreId ??= targetId;

    final found = stores.firstWhere(
      (s) => s.id == targetId,
      orElse: () => stores.first,
    );

    if (_overrideIsOpen != null) {
      return found.copyWith(isOpen: _overrideIsOpen!);
    }
    return found;
  }

  void set(StoreModel s) {
    _selectedStoreId = s.id;
    _overrideIsOpen = s.isOpen;
    state = s;
  }

  bool toggleOpen() {
    final newStatus = !state.isOpen;
    _overrideIsOpen = newStatus;
    _selectedStoreId = state.id;
    final updated = state.copyWith(isOpen: newStatus);
    state = updated;

    // Sincroniza em storesProvider para que toda a aplicação veja
    ref.read(storesProvider.notifier).update((stores) {
      if (stores.any((s) => s.id == updated.id)) {
        return stores.map((s) => s.id == updated.id ? updated : s).toList();
      } else {
        return [updated, ...stores];
      }
    });

    // Sincroniza no Supabase em background se configurado
    if (SupabaseService.isConfigured && SupabaseService.isInitialized && updated.id.isNotEmpty) {
      SupabaseService.client
          .from('stores')
          .update({'is_open': newStatus})
          .eq('id', updated.id)
          .catchError((_) {});
    }

    return newStatus;
  }

  /// Atualiza as configurações de frete decididas pela distribuidora (Base, KM, Raio Máx, Isenção e Bairros)
  Future<bool> updateDeliveryConfig({
    required double baseDeliveryFee,
    required double feePerKm,
    required double maxDeliveryRadiusKm,
    required double? freeDeliveryThreshold,
    required Map<String, double> neighborhoodFees,
    required bool isNeighborhoodPricingEnabled,
  }) async {
    final updated = state.copyWith(
      deliveryFee: baseDeliveryFee,
      feePerKm: feePerKm,
      maxDeliveryRadiusKm: maxDeliveryRadiusKm,
      freeDeliveryThreshold: freeDeliveryThreshold,
      clearFreeDeliveryThreshold: freeDeliveryThreshold == null,
      neighborhoodFees: neighborhoodFees,
      isNeighborhoodPricingEnabled: isNeighborhoodPricingEnabled,
    );

    _selectedStoreId = updated.id;
    state = updated;

    // Sincroniza imediatamente em storesProvider para todo o ecossistema (cliente, checkout, etc.)
    ref.read(storesProvider.notifier).update((stores) {
      if (stores.any((s) => s.id == updated.id)) {
        return stores.map((s) => s.id == updated.id ? updated : s).toList();
      } else {
        return [updated, ...stores];
      }
    });

    // Persistência em banco de dados Supabase real
    if (SupabaseService.isConfigured && SupabaseService.isInitialized && updated.id.isNotEmpty) {
      try {
        await SupabaseService.client.from('stores').update({
          'base_delivery_fee': baseDeliveryFee,
          'fee_per_km': feePerKm,
          'max_delivery_radius_km': maxDeliveryRadiusKm,
          'free_delivery_threshold': freeDeliveryThreshold,
          'neighborhood_fees': neighborhoodFees,
          'is_neighborhood_pricing_enabled': isNeighborhoodPricingEnabled,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', updated.id);
        return true;
      } catch (err) {
        // Fallback resiliente
        return false;
      }
    }

    return true;
  }
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
