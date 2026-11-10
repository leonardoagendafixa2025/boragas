class HomeBannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String imageUrl;
  final String actionType; // 'open_store', 'open_category', 'promo_code'
  final String actionTarget;
  final bool isActive;
  final int sortOrder;

  const HomeBannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.imageUrl,
    required this.actionType,
    required this.actionTarget,
    this.isActive = true,
    this.sortOrder = 1,
  });

  HomeBannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? badgeText,
    String? imageUrl,
    String? actionType,
    String? actionTarget,
    bool? isActive,
    int? sortOrder,
  }) {
    return HomeBannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      badgeText: badgeText ?? this.badgeText,
      imageUrl: imageUrl ?? this.imageUrl,
      actionType: actionType ?? this.actionType,
      actionTarget: actionTarget ?? this.actionTarget,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class HomeCategoryModel {
  final String id;
  final String title;
  final String slug;
  final String iconName;
  final bool isActive;
  final int sortOrder;

  const HomeCategoryModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.iconName,
    this.isActive = true,
    this.sortOrder = 1,
  });

  HomeCategoryModel copyWith({
    String? id,
    String? title,
    String? slug,
    String? iconName,
    bool? isActive,
    int? sortOrder,
  }) {
    return HomeCategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
