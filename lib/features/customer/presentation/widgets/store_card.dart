import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/store_model.dart';
import '../../../../core/widgets/status_badge.dart';

class StoreCard extends StatelessWidget {
  final StoreModel store;

  const StoreCard({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () => context.push('/store/${store.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Store Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.surfaceVariant,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    store.logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Store Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (store.isVerified) ...[
                          const SizedBox(width: 4),
                          StatusBadge.verified(),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Rating, Distance & Time
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFAB00),
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          ' (${store.reviewsCount})',
                          style: AppTypography.bodySmall,
                        ),
                        const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                        Text(
                          '${store.distanceKm.toStringAsFixed(1)} km',
                          style: AppTypography.bodySmall,
                        ),
                        const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                        Text(
                          '${store.estimatedTimeMin} min',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Delivery Fee
                    Row(
                      children: [
                        Icon(
                          Icons.delivery_dining_rounded,
                          size: 14,
                          color: store.deliveryFee == 0
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          store.deliveryFee == 0
                              ? 'Entrega Grátis'
                              : 'Frete: R\$ ${store.deliveryFee.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: store.deliveryFee == 0
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
