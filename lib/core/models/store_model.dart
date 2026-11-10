class StoreModel {
  final String id;
  final String name;
  final String cnpj;
  final String phone;
  final String logoUrl;
  final String coverUrl;
  final String address;
  final double distanceKm;
  final double rating;
  final int reviewsCount;
  final int estimatedTimeMin;
  final double deliveryFee;
  final bool isVerified;
  final bool isOpen;
  final double commissionRate; // e.g. 8.0 %
  final bool isSuspendedForNonPayment;

  const StoreModel({
    required this.id,
    required this.name,
    required this.cnpj,
    required this.phone,
    required this.logoUrl,
    required this.coverUrl,
    required this.address,
    required this.distanceKm,
    required this.rating,
    required this.reviewsCount,
    required this.estimatedTimeMin,
    required this.deliveryFee,
    this.isVerified = true,
    this.isOpen = true,
    this.commissionRate = 8.0,
    this.isSuspendedForNonPayment = false,
  });

  StoreModel copyWith({
    String? id,
    String? name,
    String? cnpj,
    String? phone,
    String? logoUrl,
    String? coverUrl,
    String? address,
    double? distanceKm,
    double? rating,
    int? reviewsCount,
    int? estimatedTimeMin,
    double? deliveryFee,
    bool? isVerified,
    bool? isOpen,
    double? commissionRate,
    bool? isSuspendedForNonPayment,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      phone: phone ?? this.phone,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      address: address ?? this.address,
      distanceKm: distanceKm ?? this.distanceKm,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      estimatedTimeMin: estimatedTimeMin ?? this.estimatedTimeMin,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isVerified: isVerified ?? this.isVerified,
      isOpen: isOpen ?? this.isOpen,
      commissionRate: commissionRate ?? this.commissionRate,
      isSuspendedForNonPayment:
          isSuspendedForNonPayment ?? this.isSuspendedForNonPayment,
    );
  }
}
