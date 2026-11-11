import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/marketing_model.dart';

// 1. Stories Notifier (Produção inicia vazia sem dados mockados)
class StoriesNotifier extends Notifier<List<StoryGroupModel>> {
  @override
  List<StoryGroupModel> build() => const <StoryGroupModel>[];

  void setStories(List<StoryGroupModel> stories) => state = stories;

  void markSeen(String id) {
    state = [
      for (final s in state)
        if (s.id == id)
          StoryGroupModel(
            id: s.id,
            label: s.label,
            icon: s.icon,
            isUnseen: false,
            ringGradientColors: [AppColors.border, AppColors.textMuted],
            slides: s.slides,
          )
        else
          s
    ];
  }
}

final storiesProvider =
    NotifierProvider<StoriesNotifier, List<StoryGroupModel>>(StoriesNotifier.new);

// 2. Flash Deal Notifier (Produção inicia nula sem oferta artificial)
class FlashDealNotifier extends Notifier<FlashDealModel?> {
  @override
  FlashDealModel? build() => null;

  void setFlashDeal(FlashDealModel? deal) => state = deal;

  void decrementStock() {
    if (state != null && state!.remainingStock > 0) {
      state = FlashDealModel(
        id: state!.id,
        storeId: state!.storeId,
        storeName: state!.storeName,
        productName: state!.productName,
        brand: state!.brand,
        originalPrice: state!.originalPrice,
        promotionalPrice: state!.promotionalPrice,
        endsAt: state!.endsAt,
        totalStock: state!.totalStock,
        remainingStock: state!.remainingStock - 1,
        neighborhood: state!.neighborhood,
      );
    }
  }
}

final flashDealProvider =
    NotifierProvider<FlashDealNotifier, FlashDealModel?>(FlashDealNotifier.new);

// 3. Loyalty Card Notifier (Produção inicia com 0 selos e sem pedidos fake)
class LoyaltyCardNotifier extends Notifier<LoyaltyCardModel> {
  @override
  LoyaltyCardModel build() {
    return const LoyaltyCardModel(
      currentStamps: 0,
      totalStampsRequired: 5,
      rewardDescription: 'R\$ 25 OFF no 5º pedido ou 1 Galão 20L Grátis',
      rewardDiscountValue: 25.00,
      completedOrders: <String>[],
    );
  }

  void addStamp(String orderNumber) {
    final nextStamps = (state.currentStamps + 1).clamp(0, state.totalStampsRequired);
    final updatedList = List<String>.from(state.completedOrders)..add(orderNumber);
    state = state.copyWith(currentStamps: nextStamps, completedOrders: updatedList);
  }

  void redeemReward() {
    state = state.copyWith(currentStamps: 0);
  }
}

final loyaltyCardProvider =
    NotifierProvider<LoyaltyCardNotifier, LoyaltyCardModel>(LoyaltyCardNotifier.new);

// 4. Referral Wallet Notifier (Produção inicia com saldo R$ 0,00 e 0 indicados)
class ReferralWalletNotifier extends Notifier<ReferralWalletModel> {
  @override
  ReferralWalletModel build() {
    return const ReferralWalletModel(
      userReferralCode: 'BORAVIZINHO10',
      creditBalance: 0.00,
      friendsInvited: 0,
      friendBonusAmount: 10.00,
      userBonusPerFriend: 10.00,
    );
  }

  void simulateFriendJoined() {
    state = state.copyWith(
      creditBalance: state.creditBalance + state.userBonusPerFriend,
      friendsInvited: state.friendsInvited + 1,
    );
  }

  void applyCredits(double amount) {
    final remaining = (state.creditBalance - amount).clamp(0.0, double.infinity);
    state = state.copyWith(creditBalance: remaining);
  }
}

final referralWalletProvider =
    NotifierProvider<ReferralWalletNotifier, ReferralWalletModel>(ReferralWalletNotifier.new);
