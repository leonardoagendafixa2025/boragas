import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/banner_model.dart';
import '../../../core/models/order_model.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_providers.dart';
import '../providers/marketing_providers.dart';
import '../../../core/widgets/interactive_scale_button.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/category_horizontal_bar.dart';
import 'widgets/customer_drawer.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getCategoryTitle(String slug, List<HomeCategoryModel> categories) {
    for (final c in categories) {
      if (c.slug == slug) return c.title;
    }
    return slug;
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(homeViewModeProvider);
    final filteredStores = ref.watch(filteredStoresProvider);
    final priceComparisonItems = ref.watch(priceComparisonListProvider);
    final cart = ref.watch(cartProvider);
    final orders = ref.watch(ordersProvider);
    final stories = ref.watch(storiesProvider);
    final flashDeal = ref.watch(flashDealProvider);
    final selectedSlug = ref.watch(selectedCategorySlugProvider);
    final categories = ref.watch(homeCategoriesProvider);
    final hasActiveOrder = orders.any((o) =>
        o.status == OrderStatus.outForDelivery ||
        o.status == OrderStatus.preparing ||
        o.status == OrderStatus.accepted);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomerDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Smart Header (Address & Fast Actions)
            HomeHeader(
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),

            // Main Scrollable Area
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // 1. Stories Bar (apenas quando houver campanhas cadastradas)
                  if (stories.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: StoriesBar(),
                      ),
                    ),

                  // 2. Oferta Chama Relâmpago (apenas quando houver oferta ativa configurada)
                  if (flashDeal != null)
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

                  // Indicador visual de filtro por categoria ativo
                  if (selectedSlug != 'all')
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_alt_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Filtrando por: ${_getCategoryTitle(selectedSlug, categories)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => ref.read(selectedCategorySlugProvider.notifier).set('all'),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Limpar',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.close_rounded, size: 14, color: AppColors.textPrimary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.storefront_outlined, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  selectedSlug != 'all'
                                      ? 'Nenhuma distribuidora com ${_getCategoryTitle(selectedSlug, categories)} encontrada no momento.'
                                      : 'Nenhuma distribuidora cadastrada na região.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                                if (selectedSlug != 'all') ...[
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    onPressed: () => ref.read(selectedCategorySlugProvider.notifier).set('all'),
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Ver todas as distribuidoras'),
                                  ),
                                ],
                              ],
                            ),
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
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  selectedSlug != 'all'
                                      ? 'Nenhum produto em estoque para a categoria selecionada.'
                                      : 'Nenhum item disponível para comparação no momento.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                                if (selectedSlug != 'all') ...[
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    onPressed: () => ref.read(selectedCategorySlugProvider.notifier).set('all'),
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Limpar filtro de categoria'),
                                  ),
                                ],
                              ],
                            ),
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

      // Floating Cart Floating Bar (exibido apenas se não houver rastreamento ativo em rota para evitar colisões)
      bottomSheet: (!cart.isEmpty && !hasActiveOrder)
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
