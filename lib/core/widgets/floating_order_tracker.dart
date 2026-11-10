import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../models/order_model.dart';
import '../../features/customer/providers/customer_providers.dart';

class FloatingOrderTracker extends ConsumerStatefulWidget {
  const FloatingOrderTracker({super.key});

  @override
  ConsumerState<FloatingOrderTracker> createState() => _FloatingOrderTrackerState();
}

class _FloatingOrderTrackerState extends ConsumerState<FloatingOrderTracker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final orders = ref.watch(ordersProvider);
    final activeOrder = orders.cast<OrderModel?>().firstWhere(
          (o) =>
              o != null &&
              (o.status == OrderStatus.outForDelivery ||
                  o.status == OrderStatus.preparing ||
                  o.status == OrderStatus.accepted),
          orElse: () => null,
        );

    if (activeOrder == null) return const SizedBox.shrink();

    final isOutForDelivery = activeOrder.status == OrderStatus.outForDelivery;

    return Dismissible(
      key: Key('floating-order-${activeOrder.id}'),
      direction: DismissDirection.down,
      onDismissed: (_) {
        setState(() => _isDismissed = true);
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOutForDelivery
                    ? AppColors.accentFlame.withValues(alpha: 0.6)
                    : AppColors.gasCyan.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isOutForDelivery ? AppColors.accentFlame : AppColors.primary)
                      .withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  context.push('/tracking/${activeOrder.id}');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      // Animated Indicator
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isOutForDelivery ? AppColors.accentFlame : AppColors.primary)
                                .withValues(alpha: 0.2),
                          ),
                          child: Center(
                            child: Icon(
                              isOutForDelivery
                                  ? Icons.two_wheeler_rounded
                                  : Icons.propane_tank_rounded,
                              color: isOutForDelivery ? AppColors.accentFlame : AppColors.gasCyan,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Text Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isOutForDelivery
                                        ? AppColors.accentFlame
                                        : AppColors.gasCyan,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOutForDelivery
                                      ? 'Entrega em Rota (~12 min)'
                                      : 'Preparando Botijão...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activeOrder.orderNumber} • ${activeOrder.storeName}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Action Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Rastrear',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
