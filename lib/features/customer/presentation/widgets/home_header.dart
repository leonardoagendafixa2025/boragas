import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../providers/customer_providers.dart';
import '../address_selection_sheet.dart';
import 'gas_consumption_calculator.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAddress = ref.watch(currentAddressProvider);
    final remoteConfig = ref.watch(remoteConfigProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Address Selector and Fast Actions
          Row(
            children: [
              // Address Selector
              Expanded(
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) => const AddressSelectionSheet(),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    currentAddress.label,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                              Text(
                                '${currentAddress.street}, ${currentAddress.number}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Gas Calculator Button
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => GasConsumptionCalculatorSheet(
                      onOrderNow: () {
                        ref.read(homeViewModeProvider.notifier).set(HomeViewMode.items);
                      },
                    ),
                  );
                },
                tooltip: 'Calculadora de Gás',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accentFlame.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.accentFlame,
                  size: 20,
                ),
              ),

            ],
          ),

          // Announcement Banner from Remote Config (Controlled by Admin)
          if (remoteConfig.showAnnouncementBanner &&
              remoteConfig.announcementBannerText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    remoteConfig.seasonalAccentColor.withValues(alpha: 0.15),
                    AppColors.accentFlame.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: remoteConfig.seasonalAccentColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.campaign_rounded,
                    size: 18,
                    color: AppColors.accentFlame,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remoteConfig.announcementBannerText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
