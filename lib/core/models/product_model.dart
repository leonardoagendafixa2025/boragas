enum ProductCategory { p13, p20, p45, water20l, accessories }

class ProductModel {
  final String id;
  final String storeId;
  final String storeName;
  final ProductCategory category;
  final String name;
  final String brandName;
  final String description;
  final double refillPrice; // Price for refill/exchange only (já tem vasilhame)
  final double shellPrice; // Price for full container + gas (sem vasilhame)
  final bool inStock;
  final String imageUrl;
  final double rating;

  const ProductModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.category,
    required this.name,
    required this.brandName,
    required this.description,
    required this.refillPrice,
    required this.shellPrice,
    this.inStock = true,
    required this.imageUrl,
    this.rating = 4.8,
  });

  ProductModel copyWith({
    String? id,
    String? storeId,
    String? storeName,
    ProductCategory? category,
    String? name,
    String? brandName,
    String? description,
    double? refillPrice,
    double? shellPrice,
    bool? inStock,
    String? imageUrl,
    double? rating,
  }) {
    return ProductModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      category: category ?? this.category,
      name: name ?? this.name,
      brandName: brandName ?? this.brandName,
      description: description ?? this.description,
      refillPrice: refillPrice ?? this.refillPrice,
      shellPrice: shellPrice ?? this.shellPrice,
      inStock: inStock ?? this.inStock,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
    );
  }
}
