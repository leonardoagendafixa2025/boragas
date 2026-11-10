import 'package:flutter/material.dart';

// 1. Stories Model
class StorySlideModel {
  final String id;
  final String title;
  final String subtitle;
  final String? promoCode;
  final String ctaLabel;
  final String? ctaRoute;
  final IconData icon;
  final LinearGradient gradient;

  const StorySlideModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.promoCode,
    required this.ctaLabel,
    this.ctaRoute,
    required this.icon,
    required this.gradient,
  });
}

class StoryGroupModel {
  final String id;
  final String label;
  final IconData icon;
  final bool isUnseen;
  final List<Color> ringGradientColors;
  final List<StorySlideModel> slides;

  const StoryGroupModel({
    required this.id,
    required this.label,
    required this.icon,
    this.isUnseen = true,
    required this.ringGradientColors,
    required this.slides,
  });
}

// 2. Flash Deal Model
class FlashDealModel {
  final String id;
  final String storeId;
  final String storeName;
  final String productName;
  final String brand;
  final double originalPrice;
  final double promotionalPrice;
  final DateTime endsAt;
  final int totalStock;
  final int remainingStock;
  final String neighborhood;

  const FlashDealModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.productName,
    required this.brand,
    required this.originalPrice,
    required this.promotionalPrice,
    required this.endsAt,
    required this.totalStock,
    required this.remainingStock,
    required this.neighborhood,
  });

  double get discountPercent =>
      ((originalPrice - promotionalPrice) / originalPrice) * 100;

  double get stockProgress => remainingStock / totalStock;

  Duration get remainingDuration {
    final diff = endsAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

// 3. Loyalty Model
class LoyaltyCardModel {
  final int currentStamps;
  final int totalStampsRequired;
  final String rewardDescription;
  final double rewardDiscountValue;
  final List<String> completedOrders;

  const LoyaltyCardModel({
    this.currentStamps = 3,
    this.totalStampsRequired = 5,
    this.rewardDescription = 'R\$ 25 OFF no próximo pedido ou 1 Galão 20L Grátis',
    this.rewardDiscountValue = 25.00,
    this.completedOrders = const ['#BGR-8921', '#BGR-7650', '#BGR-6120'],
  });

  bool get isRewardReady => currentStamps >= totalStampsRequired;
  int get remainingStamps => (totalStampsRequired - currentStamps).clamp(0, totalStampsRequired);
  double get progress => (currentStamps / totalStampsRequired).clamp(0.0, 1.0);

  LoyaltyCardModel copyWith({
    int? currentStamps,
    int? totalStampsRequired,
    String? rewardDescription,
    double? rewardDiscountValue,
    List<String>? completedOrders,
  }) {
    return LoyaltyCardModel(
      currentStamps: currentStamps ?? this.currentStamps,
      totalStampsRequired: totalStampsRequired ?? this.totalStampsRequired,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      rewardDiscountValue: rewardDiscountValue ?? this.rewardDiscountValue,
      completedOrders: completedOrders ?? this.completedOrders,
    );
  }
}

// 4. Referral / Member-Get-Member Model
class ReferralWalletModel {
  final String userReferralCode;
  final double creditBalance;
  final int friendsInvited;
  final double friendBonusAmount;
  final double userBonusPerFriend;

  const ReferralWalletModel({
    this.userReferralCode = 'BORAVIZINHO10',
    this.creditBalance = 20.00,
    this.friendsInvited = 2,
    this.friendBonusAmount = 10.00,
    this.userBonusPerFriend = 10.00,
  });

  ReferralWalletModel copyWith({
    String? userReferralCode,
    double? creditBalance,
    int? friendsInvited,
    double? friendBonusAmount,
    double? userBonusPerFriend,
  }) {
    return ReferralWalletModel(
      userReferralCode: userReferralCode ?? this.userReferralCode,
      creditBalance: creditBalance ?? this.creditBalance,
      friendsInvited: friendsInvited ?? this.friendsInvited,
      friendBonusAmount: friendBonusAmount ?? this.friendBonusAmount,
      userBonusPerFriend: userBonusPerFriend ?? this.userBonusPerFriend,
    );
  }
}
