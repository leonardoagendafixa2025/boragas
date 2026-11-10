import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_providers.dart';
import '../../../core/widgets/interactive_scale_button.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/category_horizontal_bar.dart';
import 'widgets/home_header.dart';
import 'widgets/marketing/flash_deal_card.dart';
import 'widgets/marketing/loyalty_card_widget.dart';
import 'widgets/marketing/stories_bar.dart';
import 'widgets/price_comparison_card.dart';
import 'widgets/store_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(homeViewModeProvider);
    final filteredStores = ref.watch(filteredStoresProvider);
    final priceComparisonItems = ref.watch(priceComparisonListProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Smart Header (Address & Fast Actions)
            const HomeHeader(),

            // Main Scrollable Area
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // 1. Stories Bar (Instagram-style Ofertas & Dicas)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: StoriesBar(),
                    ),
                  ),

                  // 2. Oferta Chama Relâmpago com Cronômetro Regressivo
                  const SliverToBoxAdapter(
                    child: FlashDealCard(),
                  ),

                  // 3. Promotional Banners Carousel
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: BannerCarousel(),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          ref.read(searchQueryProvider.notifier).set(val);
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar distribuidora ou produto (P13, Água, Liquigás...)',
                          hintStyle: AppTypography.bodySmall,
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(searchQueryProvider.notifier).set('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Categories Horizontal Bar
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: CategoryHorizontalBar(),
                    ),
                  ),

                  // Dual View Mode Selector (Segmented Button / Toggle)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildToggleTab(
                                title: 'Por Lojas (Distribuidoras)',
                                icon: Icons.storefront_rounded,
                                isSelected: viewMode == HomeViewMode.stores,
                                onTap: () {
                                  ref.read(homeViewModeProvider.notifier).set(HomeViewMode.stores);
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildToggleTab(
                                title: 'Comparador de Preço',
                                icon: Icons.compare_arrows_rounded,
                                isSelected: viewMode == HomeViewMode.items,
                                badge: 'MENOR VALOR',
                                onTap: () {
                                  ref.read(homeViewModeProvider.notifier).set(HomeViewMode.items);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. Cartão Selo Fidelidade Gamificado
                  const SliverToBoxAdapter(
                    child: LoyaltyCardWidget(),
                  ),

                  // Clube BoraGás Quick Strip
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: InkWell(
                        onTap: () => context.push('/subscription-club'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.accentFlame.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.loyalty_rounded, color: AppColors.accentFlame, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Clube BoraGás • Recorrência',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                                    ),
                                    Text(
                                      'Abastecimento automático com 5% OFF garantido',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Section Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            viewMode == HomeViewMode.stores
                                ? 'Distribuidoras Próximas (${filteredStores.length})'
                                : 'Melhores Ofertas por Item (${priceComparisonItems.length})',
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            viewMode == HomeViewMode.stores
                                ? 'Tempo & Frete'
                                : 'Ordenado por Menor Preço',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // View Content: Tab 1 Stores List OR Tab 2 Price Comparison
                  if (viewMode == HomeViewMode.stores) ...[
                    if (filteredStores.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'Nenhuma distribuidora encontrada.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return InteractiveScaleButton(
                              child: StoreCard(store: filteredStores[index]),
                            );
                          },
                          childCount: filteredStores.length,
                        ),
                      ),
                  ] else ...[
                    if (priceComparisonItems.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'Nenhum item encontrado para esta categoria.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return PriceComparisonCard(
                              item: priceComparisonItems[index],
                              isCheapest: index == 0,
                            );
                          },
                          childCount: priceComparisonItems.length,
                        ),
                      ),
                  ],

                  // Bottom padding for scroll
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 90),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Floating Cart Floating Bar
      bottomSheet: !cart.isEmpty
          ? Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.totalItemCount} item(ns) em ${cart.store?.name ?? ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Total: R\$ ${cart.total.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push('/cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Ver Sacola'),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildToggleTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (badge != null) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accentFlame.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentFlame,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
