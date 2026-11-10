import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/banner_model.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/store_model.dart';
import '../../../data/mock_database.dart';

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

// 1. Saved Addresses
class SavedAddressesNotifier extends Notifier<List<AddressModel>> {
  @override
  List<AddressModel> build() {
    return const [
      AddressModel(
        id: 'addr-1',
        label: 'Casa',
        street: 'Av. Brigadeiro Luís Antônio',
        number: '2344, Apto 82',
        neighborhood: 'Jardim Paulista',
        city: 'São Paulo',
        state: 'SP',
        cep: '01402-000',
        isDefault: true,
      ),
      AddressModel(
        id: 'addr-2',
        label: 'Trabalho',
        street: 'Av. Paulista',
        number: '1000, 14º Andar',
        neighborhood: 'Bela Vista',
        city: 'São Paulo',
        state: 'SP',
        cep: '01310-100',
        isDefault: false,
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

// 6. Master Stores
class StoresNotifier extends Notifier<List<StoreModel>> {
  @override
  List<StoreModel> build() => List.from(MockDatabase.initialStores);

  void set(List<StoreModel> stores) => state = stores;
  void update(List<StoreModel> Function(List<StoreModel>) fn) => state = fn(state);
}

final storesProvider =
    NotifierProvider<StoresNotifier, List<StoreModel>>(StoresNotifier.new);

// 7. Master Products
class ProductsNotifier extends Notifier<List<ProductModel>> {
  @override
  List<ProductModel> build() => List.from(MockDatabase.initialProducts);

  void set(List<ProductModel> prods) => state = prods;
  void update(List<ProductModel> Function(List<ProductModel>) fn) => state = fn(state);
}

final productsProvider =
    NotifierProvider<ProductsNotifier, List<ProductModel>>(ProductsNotifier.new);

// 8. Banners
class HomeBannersNotifier extends Notifier<List<HomeBannerModel>> {
  @override
  List<HomeBannerModel> build() => List.from(MockDatabase.initialBanners);

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

// 10. Orders
class OrdersNotifier extends Notifier<List<OrderModel>> {
  @override
  List<OrderModel> build() => List.from(MockDatabase.initialOrders);

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
