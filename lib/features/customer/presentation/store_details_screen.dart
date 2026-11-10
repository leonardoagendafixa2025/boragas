import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/store_model.dart';
import '../../../core/widgets/product_image_preview.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_providers.dart';
import 'widgets/product_bottom_sheet.dart';

class StoreDetailsScreen extends ConsumerStatefulWidget {
  final String storeId;

  const StoreDetailsScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends ConsumerState<StoreDetailsScreen> {
  ProductCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storesProvider);
    final products = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);

    final store = stores.firstWhere(
      (s) => s.id == widget.storeId,
      orElse: () => stores.first,
    );

    final storeProducts = products.where((p) => p.storeId == store.id).toList();

    final filteredProducts = _selectedCategory == null
        ? storeProducts
        : storeProducts.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible App Bar with Cover Banner
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: AppColors.textPrimary, size: 20),
                ),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    store.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Store Header Info
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store Logo
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(store.logoUrl, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    store.name,
                                    style: AppTypography.titleLarge.copyWith(
                                      fontSize: 18,
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
                            const SizedBox(height: 4),
                            Text(
                              store.address,
                              style: AppTypography.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFAB00)),
                                const SizedBox(width: 3),
                                Text(
                                  '${store.rating} (${store.reviewsCount} avaliações)',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                                Text(
                                  '${store.distanceKm} km',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),

                  // Delivery Highlights
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHighlightItem(
                        icon: Icons.schedule_rounded,
                        title: 'Tempo Médio',
                        subtitle: '${store.estimatedTimeMin} min',
                      ),
                      _buildHighlightItem(
                        icon: Icons.delivery_dining_rounded,
                        title: 'Taxa de Entrega',
                        subtitle: store.deliveryFee == 0
                            ? 'Grátis'
                            : 'R\$ ${store.deliveryFee.toStringAsFixed(2).replaceAll('.', ',')}',
                        isGreen: store.deliveryFee == 0,
                      ),
                      _buildHighlightItem(
                        icon: Icons.verified_user_rounded,
                        title: 'Garantia',
                        subtitle: 'Lacre Aferido',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Category Chips for this Store
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.background,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Todos os Itens',
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Botijões de Gás',
                      isSelected: _selectedCategory == ProductCategory.p13 ||
                          _selectedCategory == ProductCategory.p45 ||
                          _selectedCategory == ProductCategory.p20,
                      onTap: () => setState(() => _selectedCategory = ProductCategory.p13),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Água Mineral',
                      isSelected: _selectedCategory == ProductCategory.water20l,
                      onTap: () => setState(() => _selectedCategory = ProductCategory.water20l),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Acessórios & Válvulas',
                      isSelected: _selectedCategory == ProductCategory.accessories,
                      onTap: () => setState(() => _selectedCategory = ProductCategory.accessories),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Products List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final prod = filteredProducts[index];
                return _buildProductListItem(prod, store);
              },
              childCount: filteredProducts.length,
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 90),
          ),
        ],
      ),

      // Sticky Cart Button
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
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.totalItemCount} item(ns) na sacola',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          'Total: R\$ ${cart.total.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Ir para Checkout'),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHighlightItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isGreen = false,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: isGreen ? AppColors.success : AppColors.primary),
        const SizedBox(height: 4),
        Text(title, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isGreen ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildProductListItem(ProductModel prod, StoreModel store) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImagePreview(
                imageUrl: prod.imageUrl,
                width: 80,
                height: 80,
                borderRadius: 12,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prod.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prod.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Troca: R\$ ${prod.refillPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            if (prod.shellPrice != prod.refillPrice)
                              Text(
                                'Casco completo: R\$ ${prod.shellPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: AppTypography.bodySmall.copyWith(fontSize: 11),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentFlame,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 14),
                              SizedBox(width: 2),
                              Text(
                                'Adicionar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
