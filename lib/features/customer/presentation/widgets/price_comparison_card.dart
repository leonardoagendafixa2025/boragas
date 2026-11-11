import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/product_image_preview.dart';
import '../../providers/customer_providers.dart';
import 'product_bottom_sheet.dart';

class PriceComparisonCard extends ConsumerWidget {
  final PriceComparisonItem item;
  final bool isCheapest;

  const PriceComparisonCard({
    super.key,
    required this.item,
    this.isCheapest = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prod = item.product;
    final store = item.store;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCheapest
              ? AppColors.success.withValues(alpha: 0.6)
              : AppColors.border,
          width: isCheapest ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            if (isCheapest) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_down_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'MENOR PREÇO TOTAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product & Store Visual
                Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ProductImagePreview(
                        imageUrl: prod.imageUrl,
                        width: 72,
                        height: 72,
                        borderRadius: 14,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            store.logoUrl,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        store.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFAB00)),
                          const SizedBox(width: 2),
                          Text(
                            store.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                          Text(
                            '${store.estimatedTimeMin} min',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                          Text(
                            store.deliveryFee == 0
                                ? 'Frete Grátis'
                                : 'Frete R\$ ${store.deliveryFee.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: store.deliveryFee == 0 ? AppColors.success : AppColors.textSecondary,
                              fontWeight: store.deliveryFee == 0 ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),

            // Price & Quick Buy Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Troca a partir de',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            'R\$ ${prod.refillPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: AppTypography.priceHighlight.copyWith(fontSize: 18),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'c/ frete: R\$ ${item.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) => ProductBottomSheet(
                        product: prod,
                        store: store,
                      ),
                    );
                  },
                  icon: const Icon(Icons.flash_on_rounded, size: 15),
                  label: const Text('Comprar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentFlame,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
