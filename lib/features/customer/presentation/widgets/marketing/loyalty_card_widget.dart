import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:boragas/core/constants/app_colors.dart';
import 'package:boragas/features/customer/providers/marketing_providers.dart';

class LoyaltyCardWidget extends ConsumerWidget {
  const LoyaltyCardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyalty = ref.watch(loyaltyCardProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cartão Fidelidade BoraGás',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      Text(
                        'Junte 5 selos e ganhe recompensa',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/loyalty'),
                child: const Text(
                  'Ver Regras',
                  style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 5 Stamp Slots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(loyalty.totalStampsRequired, (index) {
              final isCollected = index < loyalty.currentStamps;
              final isTarget = index == loyalty.totalStampsRequired - 1;

              return Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isCollected
                          ? AppColors.primary
                          : (isTarget
                              ? const Color(0xFFFEF3C7)
                              : AppColors.surfaceVariant),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCollected
                            ? AppColors.primary
                            : (isTarget ? const Color(0xFFF59E0B) : AppColors.border),
                        width: isCollected || isTarget ? 2 : 1,
                      ),
                      boxShadow: isCollected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isCollected
                          ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28)
                          : (isTarget
                              ? const Icon(Icons.card_giftcard_rounded, color: Color(0xFFD97706), size: 24)
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                )),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTarget ? 'Prêmio!' : 'Selo ${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isTarget ? FontWeight.w800 : FontWeight.w600,
                      color: isCollected || isTarget
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 14),

          // Progress & Encouragement
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: AppColors.accentFlame, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loyalty.isRewardReady
                        ? '🎉 Parabéns! Sua recompensa está disponível para resgate!'
                        : 'Faltam apenas ${loyalty.remainingStamps} pedidos para resgatar R\$ 25 OFF!',
                    style: const TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => context.push('/loyalty'),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
