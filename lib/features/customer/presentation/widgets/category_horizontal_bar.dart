import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/customer_providers.dart';

class CategoryHorizontalBar extends ConsumerWidget {
  const CategoryHorizontalBar({super.key});

  IconData _getIconForCategory(String iconName) {
    switch (iconName) {
      case 'gas_cylinder':
        return Icons.local_fire_department_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'factory':
        return Icons.factory_rounded;
      case 'forklift':
        return Icons.electric_bolt_rounded;
      case 'build_circle':
        return Icons.build_circle_rounded;
      case 'savings':
        return Icons.price_check_rounded;
      case 'local_shipping':
        return Icons.electric_moped_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(homeCategoriesProvider);
    final selectedSlug = ref.watch(selectedCategorySlugProvider);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isAllSelected = selectedSlug == 'all';
            return _buildCategoryChip(
              label: 'Todos',
              icon: Icons.apps_rounded,
              isSelected: isAllSelected,
              onTap: () {
                ref.read(selectedCategorySlugProvider.notifier).set('all');
              },
            );
          }

          final cat = categories[index - 1];
          final isSelected = selectedSlug == cat.slug;

          return _buildCategoryChip(
            label: cat.title,
            icon: _getIconForCategory(cat.iconName),
            isSelected: isSelected,
            onTap: () {
              if (isSelected) {
                ref.read(selectedCategorySlugProvider.notifier).set('all');
              } else {
                ref.read(selectedCategorySlugProvider.notifier).set(cat.slug);
                if (cat.slug == 'lowest_price') {
                  ref.read(homeViewModeProvider.notifier).set(HomeViewMode.items);
                }
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
