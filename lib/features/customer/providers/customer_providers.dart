import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/banner_model.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/store_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/mock_database.dart';
import '../../auth/providers/auth_provider.dart';

enum HomeViewMode { stores, items }

class AddressModel {
  final String id;
  final String label;
  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String state;
  final String cep;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.cep,
    this.isDefault = false,
  });

  String get formatted => '$street, $number - $neighborhood, $city';
}

// 1. Saved Addresses (Vinculado ao endereço real do cliente logado)
class SavedAddressesNotifier extends Notifier<List<AddressModel>> {
  @override
  List<AddressModel> build() {
    final auth = ref.watch(authProvider);
    final userAddr = auth.user?.address;
    if (userAddr != null && userAddr.trim().isNotEmpty) {
      return [
        AddressModel(
          id: 'addr-user',
          label: 'Meu Endereço de Entrega',
          street: userAddr.trim(),
          number: '',
          neighborhood: '',
          city: 'São Paulo',
          state: 'SP',
          cep: '',
          isDefault: true,
        ),
      ];
    }
    return const [
      AddressModel(
        id: 'addr-default',
        label: 'Endereço Principal',
        street: 'Toque para selecionar seu endereço de entrega',
        number: '',
        neighborhood: '',
        city: 'São Paulo',
        state: 'SP',
        cep: '',
        isDefault: true,
      ),
    ];
  }

  void set(List<AddressModel> list) => state = list;
  void update(List<AddressModel> Function(List<AddressModel>) fn) => state = fn(state);
}

final savedAddressesProvider =
    NotifierProvider<SavedAddressesNotifier, List<AddressModel>>(SavedAddressesNotifier.new);

// 2. Current Address
class CurrentAddressNotifier extends Notifier<AddressModel> {
  @override
  AddressModel build() {
    final addresses = ref.watch(savedAddressesProvider);
    return addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
  }

  void set(AddressModel addr) => state = addr;
}

final currentAddressProvider =
    NotifierProvider<CurrentAddressNotifier, AddressModel>(CurrentAddressNotifier.new);

// 3. Home View Mode
class HomeViewModeNotifier extends Notifier<HomeViewMode> {
  @override
  HomeViewMode build() => HomeViewMode.stores;

  void set(HomeViewMode mode) => state = mode;
}

final homeViewModeProvider =
    NotifierProvider<HomeViewModeNotifier, HomeViewMode>(HomeViewModeNotifier.new);

// 4. Selected Category Slug
class SelectedCategorySlugNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void set(String slug) => state = slug;
}

final selectedCategorySlugProvider =
    NotifierProvider<SelectedCategorySlugNotifier, String>(SelectedCategorySlugNotifier.new);

// 5. Search Query
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// 6. Master Stores (Sincronizado em tempo real com o banco Supabase)
class StoresNotifier extends Notifier<List<StoreModel>> {
  @override
  List<StoreModel> build() {
    _loadStoresFromSupabase();
    return List.from(MockDatabase.initialStores);
  }

  Future<void> _loadStoresFromSupabase() async {
    if (!SupabaseService.isConfigured || !SupabaseService.isInitialized) return;
    try {
      final res = await SupabaseService.client
          .from('stores')
          .select('*')
          .order('created_at', ascending: false);

      if (res.isNotEmpty) {
        final list = res.map((item) => StoreModel(
          id: item['id'].toString(),
          name: item['name'] as String? ?? 'Distribuidora',
          cnpj: item['cnpj'] as String? ?? '00.000.000/0001-00',
          phone: item['phone'] as String? ?? '',
          logoUrl: item['logo_url'] as String? ?? 'assets/images/app_icon.png',
          coverUrl: item['cover_url'] as String? ?? 'assets/images/brand_lockup.png',
          address: item['address'] as String? ?? 'São Paulo - SP',
          distanceKm: (item['distance_km'] as num?)?.toDouble() ?? 2.5,
          rating: (item['rating'] as num?)?.toDouble() ?? 5.0,
          reviewsCount: (item['reviews_count'] as num?)?.toInt() ?? 12,
          estimatedTimeMin: (item['estimated_time_min'] as num?)?.toInt() ?? 25,
          deliveryFee: (item['base_delivery_fee'] as num?)?.toDouble() ?? 0.0,
          isVerified: item['is_verified'] == true,
          isOpen: item['is_open'] == true,
          commissionRate: (item['commission_rate_percent'] as num?)?.toDouble() ??
              (item['commission_rate'] as num?)?.toDouble() ??
              8.0,
          isSuspendedForNonPayment: item['status'] == 'suspended',
        )).toList();
        state = list;
      }
    } catch (_) {}
  }

  void set(List<StoreModel> stores) => state = stores;
  void update(List<StoreModel> Function(List<StoreModel>) fn) => state = fn(state);
}

final storesProvider =
    NotifierProvider<StoresNotifier, List<StoreModel>>(StoresNotifier.new);

// 7. Master Products (Sincronizado com o banco Supabase)
class ProductsNotifier extends Notifier<List<ProductModel>> {
  @override
  List<ProductModel> build() {
    _loadProductsFromSupabase();
    return List.from(MockDatabase.initialProducts);
  }

  Future<void> _loadProductsFromSupabase() async {
    if (!SupabaseService.isConfigured || !SupabaseService.isInitialized) return;
    try {
      final res = await SupabaseService.client.from('products').select('*');
      if (res.isNotEmpty) {
        final list = res.map((item) => ProductModel(
          id: item['id'].toString(),
          storeId: item['store_id']?.toString() ?? 'store-1',
          storeName: item['store_name'] ?? 'Distribuidora',
          category: _mapSlugToCategory(item['category_slug'] ?? 'p13'),
          name: item['name'] ?? 'Botijão P13',
          brandName: item['brand_name'] ?? 'Marca Certificada',
          description: item['description'] ?? '',
          refillPrice: (item['refill_price'] as num?)?.toDouble() ?? 104.90,
          shellPrice: (item['shell_price'] as num?)?.toDouble() ?? 280.0,
          imageUrl: item['image_url'] ?? 'assets/images/app_icon.png',
          rating: (item['rating'] as num?)?.toDouble() ?? 5.0,
        )).toList();
        state = list;
      }
    } catch (_) {}
  }

  static ProductCategory _mapSlugToCategory(String slug) {
    switch (slug) {
      case 'p13':
        return ProductCategory.p13;
      case 'p20':
        return ProductCategory.p20;
      case 'p45':
        return ProductCategory.p45;
      case 'water20l':
        return ProductCategory.water20l;
      default:
        return ProductCategory.accessories;
    }
  }

  void set(List<ProductModel> prods) => state = prods;
  void update(List<ProductModel> Function(List<ProductModel>) fn) => state = fn(state);
}

final productsProvider =
    NotifierProvider<ProductsNotifier, List<ProductModel>>(ProductsNotifier.new);

// 8. Banners (Sincronizado com o banco Supabase)
class HomeBannersNotifier extends Notifier<List<HomeBannerModel>> {
  @override
  List<HomeBannerModel> build() {
    _loadBannersFromSupabase();
    return List.from(MockDatabase.initialBanners);
  }

  Future<void> _loadBannersFromSupabase() async {
    if (!SupabaseService.isConfigured || !SupabaseService.isInitialized) return;
    try {
      final res = await SupabaseService.client.from('home_banners').select('*').order('sort_order');
      if (res.isNotEmpty) {
        final list = res.map((b) => HomeBannerModel(
          id: b['id'].toString(),
          title: b['title'] ?? '',
          subtitle: b['subtitle'] ?? '',
          badgeText: b['badge_text'] ?? 'DESTAQUE',
          imageUrl: b['image_url'] ?? 'assets/images/app_icon.png',
          actionType: b['action_type'] ?? 'promo_code',
          actionTarget: b['action_target'] ?? 'BORAGAS10',
          isActive: b['is_active'] == true,
          sortOrder: (b['sort_order'] as num?)?.toInt() ?? 1,
        )).toList();
        state = list;
      }
    } catch (_) {}
  }

  void set(List<HomeBannerModel> banners) => state = banners;
  void update(List<HomeBannerModel> Function(List<HomeBannerModel>) fn) => state = fn(state);
}

final homeBannersProvider =
    NotifierProvider<HomeBannersNotifier, List<HomeBannerModel>>(HomeBannersNotifier.new);

// 9. Categories
class HomeCategoriesNotifier extends Notifier<List<HomeCategoryModel>> {
  @override
  List<HomeCategoryModel> build() => List.from(MockDatabase.initialCategories);

  void set(List<HomeCategoryModel> cats) => state = cats;
  void update(List<HomeCategoryModel> Function(List<HomeCategoryModel>) fn) => state = fn(state);
}

final homeCategoriesProvider =
    NotifierProvider<HomeCategoriesNotifier, List<HomeCategoryModel>>(HomeCategoriesNotifier.new);

// 10. Orders (Persistidos e Sincronizados com Supabase)
class OrdersNotifier extends Notifier<List<OrderModel>> {
  @override
  List<OrderModel> build() {
    _loadOrdersFromSupabase();
    return List.from(MockDatabase.initialOrders);
  }

  Future<void> _loadOrdersFromSupabase() async {
    if (!SupabaseService.isConfigured || !SupabaseService.isInitialized) return;
    try {
      final res = await SupabaseService.client
          .from('orders')
          .select('*')
          .order('created_at', ascending: false);
      if (res.isNotEmpty) {
        state = res.map((row) => OrderModel.fromJson(row)).toList();
      }
    } catch (_) {}
  }

  void set(List<OrderModel> orders) => state = orders;
  void update(List<OrderModel> Function(List<OrderModel>) fn) => state = fn(state);
}

final ordersProvider =
    NotifierProvider<OrdersNotifier, List<OrderModel>>(OrdersNotifier.new);

// Filtered Stores for Home
final filteredStoresProvider = Provider<List<StoreModel>>((ref) {
  final stores = ref.watch(storesProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return stores.where((s) {
    if (s.isSuspendedForNonPayment) return false;
    if (query.isEmpty) return true;
    return s.name.toLowerCase().contains(query) ||
        s.address.toLowerCase().contains(query);
  }).toList();
});

// Price Comparison Items
class PriceComparisonItem {
  final ProductModel product;
  final StoreModel store;
  final double totalPrice;

  const PriceComparisonItem({
    required this.product,
    required this.store,
    required this.totalPrice,
  });
}

final priceComparisonListProvider = Provider<List<PriceComparisonItem>>((ref) {
  final products = ref.watch(productsProvider);
  final stores = ref.watch(storesProvider);
  final categorySlug = ref.watch(selectedCategorySlugProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  final storeMap = {for (var s in stores) s.id: s};

  List<PriceComparisonItem> items = [];

  for (final prod in products) {
    final store = storeMap[prod.storeId];
    if (store == null || store.isSuspendedForNonPayment) continue;

    if (categorySlug != 'all' &&
        categorySlug != 'lowest_price' &&
        categorySlug != 'free_delivery') {
      if (categorySlug == 'p13' && prod.category != ProductCategory.p13) continue;
      if (categorySlug == 'water20l' && prod.category != ProductCategory.water20l) continue;
      if (categorySlug == 'p45' && prod.category != ProductCategory.p45) continue;
      if (categorySlug == 'p20' && prod.category != ProductCategory.p20) continue;
      if (categorySlug == 'accessories' && prod.category != ProductCategory.accessories) continue;
    }

    if (categorySlug == 'free_delivery' && store.deliveryFee > 0) {
      continue;
    }

    if (query.isNotEmpty) {
      final matchesProd = prod.name.toLowerCase().contains(query) ||
          prod.brandName.toLowerCase().contains(query);
      final matchesStore = store.name.toLowerCase().contains(query);
      if (!matchesProd && !matchesStore) continue;
    }

    items.add(
      PriceComparisonItem(
        product: prod,
        store: store,
        totalPrice: prod.refillPrice + store.deliveryFee,
      ),
    );
  }

  items.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
  return items;
});
