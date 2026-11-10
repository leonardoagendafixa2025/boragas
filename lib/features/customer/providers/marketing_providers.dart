import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/marketing_model.dart';

// 1. Stories Notifier
class StoriesNotifier extends Notifier<List<StoryGroupModel>> {
  @override
  List<StoryGroupModel> build() {
    return [
      const StoryGroupModel(
        id: 'flash_deals',
        label: 'Relâmpago',
        icon: Icons.bolt_rounded,
        isUnseen: true,
        ringGradientColors: [Color(0xFFFF7A00), Color(0xFFFF0055)],
        slides: [
          StorySlideModel(
            id: 's_flash_1',
            title: '⚡ QUEIMA DE ESTOQUE',
            subtitle: 'Ultragaz 13kg com R\$ 15 de desconto direto! Apenas hoje enquanto durarem os últimos 8 botijões da distribuidora Jardins.',
            promoCode: 'RELAMPAGO15',
            ctaLabel: 'Garantir com Desconto',
            ctaRoute: '/home',
            icon: Icons.local_fire_department_rounded,
            gradient: LinearGradient(
              colors: [Color(0xFF831843), Color(0xFFBE123C), Color(0xFFE11D48)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
      const StoryGroupModel(
        id: 'coupons',
        label: 'Cupons',
        icon: Icons.confirmation_number_rounded,
        isUnseen: true,
        ringGradientColors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
        slides: [
          StorySlideModel(
            id: 's_coupon_1',
            title: '🎁 SEU CUPOM DE HOJE',
            subtitle: 'Use o código BORA10 no carrinho para garantir R\$ 10,00 de desconto no seu botijão P13 ou galão de água!',
            promoCode: 'BORA10',
            ctaLabel: 'Copiar Cupom & Comprar',
            ctaRoute: '/home',
            icon: Icons.redeem_rounded,
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF38BDF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
      const StoryGroupModel(
        id: 'combos',
        label: 'Combos',
        icon: Icons.all_inclusive_rounded,
        isUnseen: true,
        ringGradientColors: [Color(0xFF059669), Color(0xFF10B981)],
        slides: [
          StorySlideModel(
            id: 's_combo_1',
            title: '💧 COMBO RESIDENCIAL',
            subtitle: 'Peça 1 Botijão P13 + 1 Galão 20L Bonafont e ganhe frete grátis + prioridade de entrega no mesmo motoboy!',
            promoCode: 'COMBOTOP',
            ctaLabel: 'Ver Combos',
            ctaRoute: '/subscription-club',
            icon: Icons.water_drop_rounded,
            gradient: LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF34D399)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
      const StoryGroupModel(
        id: 'safety',
        label: 'Segurança',
        icon: Icons.shield_rounded,
        isUnseen: false,
        ringGradientColors: [Color(0xFFD97706), Color(0xFFF59E0B)],
        slides: [
          StorySlideModel(
            id: 's_safe_1',
            title: '🛡️ TESTE DA ESPUMA DE SABÃO',
            subtitle: 'Nunca use fósforo ou isqueiro para checar vazamentos! Passe esponja com espuma na válvula. Se fizer bolhas, reaperte o registro.',
            ctaLabel: 'Entendido, Dica Salva!',
            icon: Icons.verified_user_rounded,
            gradient: LinearGradient(
              colors: [Color(0xFF451A03), Color(0xFFB45309), Color(0xFFF59E0B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
      const StoryGroupModel(
        id: 'referral',
        label: 'Ganhe R\$10',
        icon: Icons.people_alt_rounded,
        isUnseen: true,
        ringGradientColors: [Color(0xFF9333EA), Color(0xFFEC4899)],
        slides: [
          StorySlideModel(
            id: 's_ref_1',
            title: '👥 INDIQUE SEU VIZINHO',
            subtitle: 'Envie seu código de indicação no WhatsApp do condomínio: seu vizinho ganha R\$ 10 OFF e você ganha R\$ 10 de saldo!',
            ctaLabel: 'Compartilhar no WhatsApp',
            ctaRoute: '/referral',
            icon: Icons.volunteer_activism_rounded,
            gradient: LinearGradient(
              colors: [Color(0xFF581C87), Color(0xFF9333EA), Color(0xFFF43F5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    ];
  }

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

// 2. Flash Deal Notifier
class FlashDealNotifier extends Notifier<FlashDealModel?> {
  @override
  FlashDealModel? build() {
    return FlashDealModel(
      id: 'fd-001',
      storeId: 'store-1',
      storeName: 'Ultragaz Jardins Express',
      productName: 'Botijão GLP 13kg (Troca)',
      brand: 'Ultragaz',
      originalPrice: 110.00,
      promotionalPrice: 94.90,
      endsAt: DateTime.now().add(const Duration(hours: 2, minutes: 45)),
      totalStock: 15,
      remainingStock: 6,
      neighborhood: 'Jardins / Cerqueira César',
    );
  }

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

// 3. Loyalty Card Notifier
class LoyaltyCardNotifier extends Notifier<LoyaltyCardModel> {
  @override
  LoyaltyCardModel build() {
    return const LoyaltyCardModel(
      currentStamps: 3,
      totalStampsRequired: 5,
      rewardDescription: 'R\$ 25 OFF no próximo pedido ou 1 Galão 20L Grátis',
      rewardDiscountValue: 25.00,
      completedOrders: ['#BGR-8921', '#BGR-7650', '#BGR-6120'],
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

// 4. Referral Wallet Notifier
class ReferralWalletNotifier extends Notifier<ReferralWalletModel> {
  @override
  ReferralWalletModel build() {
    return const ReferralWalletModel(
      userReferralCode: 'BORAVIZINHO10',
      creditBalance: 20.00,
      friendsInvited: 2,
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
