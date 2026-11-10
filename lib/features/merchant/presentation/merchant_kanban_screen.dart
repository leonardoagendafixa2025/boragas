import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/audio_alert_service.dart';
import '../../../core/widgets/status_badge.dart';
import '../../customer/providers/customer_providers.dart';
import '../providers/merchant_providers.dart';

class MerchantKanbanScreen extends ConsumerStatefulWidget {
  const MerchantKanbanScreen({super.key});

  @override
  ConsumerState<MerchantKanbanScreen> createState() =>
      _MerchantKanbanScreenState();
}

class _MerchantKanbanScreenState extends ConsumerState<MerchantKanbanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _advanceOrder(OrderModel order) {
    OrderStatus next;
    if (order.status == OrderStatus.pending || order.status == OrderStatus.accepted) {
      next = OrderStatus.preparing;
    } else if (order.status == OrderStatus.preparing) {
      next = OrderStatus.outForDelivery;
    } else if (order.status == OrderStatus.outForDelivery) {
      next = OrderStatus.delivered;
    } else {
      return;
    }

    final updated = order.copyWith(
      status: next,
      deliveredAt: next == OrderStatus.delivered ? DateTime.now() : null,
      courierName: next == OrderStatus.outForDelivery
          ? 'Marcos Oliveira (Moto 160)'
          : order.courierName,
    );

    ref.read(ordersProvider.notifier).update(
          (list) => list.map((o) => o.id == order.id ? updated : o).toList(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido ${order.orderNumber} atualizado para "${next.name}"!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStore = ref.watch(currentMerchantStoreProvider);
    final allOrders = ref.watch(ordersProvider);

    final storeOrders =
        allOrders.where((o) => o.storeId == currentStore.id).toList();

    final newOrders = storeOrders
        .where((o) =>
            o.status == OrderStatus.pending || o.status == OrderStatus.accepted)
        .toList();

    final inTransitOrders = storeOrders
        .where((o) =>
            o.status == OrderStatus.preparing ||
            o.status == OrderStatus.outForDelivery)
        .toList();

    final completedOrders = storeOrders
        .where((o) =>
            o.status == OrderStatus.delivered ||
            o.status == OrderStatus.cancelled)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kanban de Pedidos', style: TextStyle(fontSize: 16)),
            Text(
              currentStore.name,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Simular Som de Novo Pedido',
            icon: const Icon(Icons.notifications_active_rounded, color: AppColors.accentFlame),
            onPressed: () {
              AudioAlertService.playNewOrderAlert();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔔 Alerta sonoro e vibração de novo pedido acionado!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Novos'),
                  if (newOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.accentFlame,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${newOrders.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Em Rota'),
                  if (inTransitOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${inTransitOrders.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'Concluídos (${completedOrders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(newOrders, emptyMessage: 'Nenhum pedido novo no momento.'),
          _buildOrdersList(inTransitOrders, emptyMessage: 'Nenhum pedido em rota agora.'),
          _buildOrdersList(completedOrders, emptyMessage: 'Nenhum pedido concluído recentemente.'),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, {required String emptyMessage}) {
    if (orders.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: order.status == OrderStatus.accepted
                  ? AppColors.accentFlame
                  : AppColors.border,
              width: order.status == OrderStatus.accepted ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    StatusBadge.fromOrderStatus(order.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Cliente: ${order.customerName} • ${order.customerPhone}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Endereço: ${order.deliveryAddress}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),

                // Items list
                ...order.items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${i.quantity}x ${i.productName}', style: const TextStyle(fontSize: 13)),
                          Text(
                            'R\$ ${i.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 10),

                // Payment mode & PIN
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payment_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            order.paymentMode.name,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Text('PIN de Entrega: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          order.deliveryConfirmationCode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Action buttons
                if (order.status != OrderStatus.delivered &&
                    order.status != OrderStatus.cancelled) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _advanceOrder(order),
                      icon: Icon(
                        order.status == OrderStatus.accepted
                            ? Icons.inventory_2_outlined
                            : (order.status == OrderStatus.preparing
                                ? Icons.two_wheeler_rounded
                                : Icons.check_circle_outline_rounded),
                        size: 18,
                      ),
                      label: Text(
                        order.status == OrderStatus.accepted
                            ? 'Iniciar Separação'
                            : (order.status == OrderStatus.preparing
                                ? 'Despachar para Entrega'
                                : 'Confirmar Entrega Concluída'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: order.status == OrderStatus.accepted
                            ? AppColors.accentFlame
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
