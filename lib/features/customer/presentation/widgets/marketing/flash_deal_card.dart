import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:boragas/core/constants/app_colors.dart';
import 'package:boragas/core/models/product_model.dart';
import 'package:boragas/features/customer/providers/cart_provider.dart';
import 'package:boragas/features/customer/providers/customer_providers.dart';
import 'package:boragas/features/customer/providers/marketing_providers.dart';

class FlashDealCard extends ConsumerStatefulWidget {
  const FlashDealCard({super.key});

  @override
  ConsumerState<FlashDealCard> createState() => _FlashDealCardState();
}

class _FlashDealCardState extends ConsumerState<FlashDealCard> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    final deal = ref.read(flashDealProvider);
    _remaining = deal != null ? deal.remainingDuration : const Duration(hours: 2, minutes: 45);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining.inSeconds > 0) {
        setState(() {
          _remaining = _remaining - const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _claimFlashDeal() {
    final deal = ref.read(flashDealProvider);
    if (deal == null) return;

    final stores = ref.read(storesProvider);
    final products = ref.read(productsProvider);

    final store = stores.firstWhere(
      (s) => s.id == deal.storeId,
      orElse: () => stores.first,
    );

    final product = products.firstWhere(
      (p) => p.storeId == deal.storeId && p.category == ProductCategory.p13,
      orElse: () => products.first,
    );

    // Add to cart with promotional price
    ref.read(cartProvider.notifier).addItem(
          product: product.copyWith(refillPrice: deal.promotionalPrice),
          store: store,
          quantity: 1,
          isRefillOnly: true,
        );

    ref.read(flashDealProvider.notifier).decrementStock();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ Oferta Relâmpago de ${deal.productName} adicionada à sacola!'),
        backgroundColor: AppColors.accentFlame,
        action: SnackBarAction(
          label: 'Ver Sacola',
          textColor: Colors.white,
          onPressed: () => context.go('/cart'),
        ),
      ),
    );

    context.go('/cart');
  }

  @override
  Widget build(BuildContext context) {
    final deal = ref.watch(flashDealProvider);
    if (deal == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F1D1D), Color(0xFF991B1B), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Badge + Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: AppColors.accentFlame, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'CHAMA RELÂMPAGO',
                          style: TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white30),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(_remaining),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Deal Details Row
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/app_icon_v2.png',
                    width: 44,
                    height: 44,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${deal.productName} • ${deal.brand}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${deal.storeName} (${deal.neighborhood})',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'De R\$ ${deal.originalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Por R\$ ${deal.promotionalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${deal.discountPercent.round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stock Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Restam apenas ${deal.remainingStock} de ${deal.totalStock} botijões',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Queima Rápida',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: deal.stockProgress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                  minHeight: 6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF991B1B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _claimFlashDeal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flash_on_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Garantir por R\$ ${deal.promotionalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
