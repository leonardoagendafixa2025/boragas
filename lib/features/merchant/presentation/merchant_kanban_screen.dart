import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/order_model.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/ui/bora_button.dart';
import '../../../core/widgets/ui/bora_card.dart';
import '../../../core/widgets/ui/bora_empty_state.dart';
import '../../../core/widgets/ui/bora_pulsing_halo.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/providers/customer_providers.dart';
import '../providers/merchant_providers.dart';

class MerchantKanbanScreen extends ConsumerStatefulWidget {
  const MerchantKanbanScreen({super.key});

  @override
  ConsumerState<MerchantKanbanScreen> createState() => _MerchantKanbanScreenState();
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

  Future<void> _whatsappCustomer(String phone, String orderNumber) async {
    try {
      HapticFeedback.lightImpact();
      String clean = phone.replaceAll(RegExp(r'\D'), '');
      if (!clean.startsWith('55')) clean = '55$clean';
      final uri = Uri.parse(
        'https://wa.me/$clean?text=${Uri.encodeComponent("Olá! É da distribuidora BoraGás sobre o seu pedido $orderNumber.")}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _callCustomer(String phone) async {
    try {
      HapticFeedback.lightImpact();
      final clean = phone.replaceAll(RegExp(r'\D'), '');
      final uri = Uri.parse('tel:$clean');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _advanceOrder(OrderModel order) {
    HapticFeedback.mediumImpact();
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
          ? (order.courierName?.isNotEmpty == true ? order.courierName : 'Marcos Oliveira (Honda Fan 160)')
          : order.courierName,
      courierPhone: next == OrderStatus.outForDelivery
          ? (order.courierPhone?.isNotEmpty == true ? order.courierPhone : '(11) 97722-1199')
          : order.courierPhone,
    );

    ref.read(ordersProvider.notifier).update(
          (list) => list.map((o) => o.id == order.id ? updated : o).toList(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pedido ${order.orderNumber} avançou para: ${next.name.toUpperCase()}!',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _cancelOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Recusar Pedido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          'Deseja realmente recusar o pedido ${order.orderNumber}? O cliente será notificado imediatamente.',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Recusar Pedido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updated = order.copyWith(status: OrderStatus.cancelled);
      ref.read(ordersProvider.notifier).update(
            (list) => list.map((o) => o.id == order.id ? updated : o).toList(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedido ${order.orderNumber} cancelado.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _isGasItem(String name) {
    final lower = name.toLowerCase();
    return lower.contains('gás') || lower.contains('gas') || lower.contains('p13') || lower.contains('p45') || lower.contains('glp');
  }

  @override
  Widget build(BuildContext context) {
    final currentStore = ref.watch(currentMerchantStoreProvider);
    final allOrders = ref.watch(ordersProvider);
    final authUser = ref.watch(authProvider).user;

    final storeOrders = allOrders.where((o) => o.storeId == currentStore.id).toList();

    final newOrders = storeOrders
        .where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.accepted)
        .toList();

    final inTransitOrders = storeOrders
        .where((o) => o.status == OrderStatus.preparing || o.status == OrderStatus.outForDelivery)
        .toList();

    final completedOrders = storeOrders
        .where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled)
        .toList();

    final totalRevenue = storeOrders
        .where((o) => o.status != OrderStatus.cancelled)
        .fold<double>(0.0, (acc, item) => acc + item.totalAmount);

    return Container(
      color: AppColors.merchantCanvas,
      child: Column(
        children: [
          // 1. Cockpit Ribbon: Faturamento & Despacho
          _buildCockpitRibbon(
            totalRevenue: totalRevenue,
            activeCount: newOrders.length + inTransitOrders.length,
            courierName: authUser?.role == UserRole.courier
                ? (authUser?.name ?? 'Marcos Oliveira')
                : 'Marcos Oliveira',
            courierVehicle: authUser?.vehicleModel ?? 'Honda Fan 160',
          ),

          // 2. Segmented Navigation Tab Bar
          _buildSegmentedTabBar(
            newCount: newOrders.length,
            inTransitCount: inTransitOrders.length,
            completedCount: completedOrders.length,
          ),

          // 3. Tab Contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewOrdersTab(newOrders, currentStore.id),
                _buildOrdersList(inTransitOrders, isTransitTab: true),
                _buildOrdersList(completedOrders, isCompletedTab: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Cockpit Ribbon: Faturamento e Despacho
  Widget _buildCockpitRibbon({
    required double totalRevenue,
    required int activeCount,
    required String courierName,
    required String courierVehicle,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.merchantCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.merchantCardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Faturamento Hoje
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'FATURAMENTO HOJE',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${totalRevenue.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '100% repassado à loja • Taxa 8%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Divisor Vertical
          Container(
            height: 44,
            width: 1,
            color: const Color(0x1FFFFFFF),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Despacho & Frota
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.two_wheeler_rounded, color: AppColors.accentFlame, size: 14),
                    const SizedBox(width: 5),
                    const Text(
                      'DESPACHO',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activeCount > 0 ? '$activeCount em rota' : 'Depósito Pronto',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: activeCount > 0 ? const Color(0xFF38BDF8) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$courierName ($courierVehicle)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Segmented Tab Bar com Indicador Animado
  Widget _buildSegmentedTabBar({
    required int newCount,
    required int inTransitCount,
    required int completedCount,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.merchantCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.merchantCardBorder, width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.accentFlame,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentFlame.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Novos'),
                if (newCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$newCount',
                      style: const TextStyle(
                        color: AppColors.accentFlame,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
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
                if (inTransitCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$inTransitCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Text('Concluídos ($completedCount)'),
          ),
        ],
      ),
    );
  }

  /// 3. Aba de Novos Pedidos (Empty State ou Lista com Halo de Pulso)
  Widget _buildNewOrdersTab(List<OrderModel> orders, String storeId) {
    if (orders.isEmpty) {
      return const BoraEmptyState(
        icon: Icons.radar_rounded,
        iconColor: AppColors.accentFlame,
        title: 'Radar de Vendas Ativo',
        description: 'Sua distribuidora está aberta e recebendo pedidos normalmente. Quando um cliente fizer um pedido, o alerta sonoro tocará aqui.',
      );
    }

    return _buildOrdersList(orders, isNewTab: true);
  }

  /// 4. Lista de Pedidos
  Widget _buildOrdersList(
    List<OrderModel> orders, {
    bool isNewTab = false,
    bool isTransitTab = false,
    bool isCompletedTab = false,
  }) {
    if (orders.isEmpty) {
      return BoraEmptyState(
        icon: isTransitTab ? Icons.two_wheeler_rounded : Icons.check_circle_outline_rounded,
        iconColor: isTransitTab ? const Color(0xFF38BDF8) : AppColors.success,
        title: isTransitTab ? 'Nenhum pedido em rota' : 'Nenhum pedido concluído',
        description: isTransitTab
            ? 'Assim que você aceitar e despachar pedidos, eles aparecerão aqui com o motoboy.'
            : 'Os pedidos entregues ou finalizados do dia ficarão registrados aqui.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isPending = order.status == OrderStatus.pending;
        final isAccepted = order.status == OrderStatus.accepted;
        final isNewAction = isPending || isAccepted;

        final cardContent = BoraCard(
          color: AppColors.merchantCard,
          borderColor: isNewAction ? AppColors.accentFlame.withValues(alpha: 0.5) : AppColors.merchantCardBorder,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do Card: Número do Pedido + Tempo + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isNewAction ? AppColors.accentFlame : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          order.orderNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Há ${index == 0 ? "3" : "10"} min',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  StatusBadge.fromOrderStatus(order.status),
                ],
              ),

              const SizedBox(height: 12),

              // Bloco do Cliente: Nome, Telefone, Ações de 1 toque (WhatsApp e Ligar)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E293B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: Color(0xFF38BDF8), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            order.customerPhone,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    // Botão WhatsApp Oficial de 1 Toque
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        minimumSize: const Size(0, 34),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _whatsappCustomer(order.customerPhone, order.orderNumber),
                      icon: const Icon(Icons.chat_rounded, size: 14),
                      label: const Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 6),
                    // Botão Ligar de 1 Toque
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(34, 34),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _callCustomer(order.customerPhone),
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      tooltip: 'Ligar para cliente',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Endereço de Entrega
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.accentFlame, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.deliveryAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Divider(height: 1, color: AppColors.merchantDivider),
              const SizedBox(height: 10),

              // Itens do Pedido com Distinção Gás x Água
              ...order.items.map((i) {
                final isGas = _isGasItem(i.productName);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Badge Semântico Gás x Água
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isGas ? AppColors.gasTagBgDark : AppColors.waterTagBgDark,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isGas ? AppColors.accentFlame.withValues(alpha: 0.3) : const Color(0xFF0284C7).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGas ? Icons.local_fire_department_rounded : Icons.water_drop_rounded,
                              size: 11,
                              color: isGas ? AppColors.accentFlame : const Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isGas ? 'GÁS' : 'ÁGUA',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: isGas ? AppColors.accentFlame : const Color(0xFF38BDF8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${i.quantity}x ${i.productName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        'R\$ ${i.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(color: Color(0xFF34D399), fontSize: 13.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 10),

              // Pagamento & PIN de Segurança
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payment_rounded, size: 15, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 6),
                        Text(
                          order.paymentMode.name.toUpperCase(),
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('PIN de Entrega: ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        Text(
                          order.deliveryConfirmationCode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accentFlame,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (order.courierName != null && order.courierName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.two_wheeler_rounded, color: Color(0xFF94A3B8), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Entregador: ${order.courierName}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Ações Principais ao alcance do Polegar (48px a 52px)
              if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) ...[
                if (isPending) ...[
                  Row(
                    children: [
                      // Botão Recusar
                      Expanded(
                        flex: 3,
                        child: BoraButton.danger(
                          text: 'Recusar',
                          icon: Icons.close_rounded,
                          height: 48,
                          onPressed: () => _cancelOrder(order),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botão Aceitar Gigante
                      Expanded(
                        flex: 6,
                        child: BoraButton.flame(
                          text: 'Aceitar Pedido',
                          icon: Icons.check_circle_rounded,
                          height: 52,
                          onPressed: () => _advanceOrder(order),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: BoraButton(
                      text: order.status == OrderStatus.accepted
                          ? 'Iniciar Preparo & Separação'
                          : (order.status == OrderStatus.preparing
                              ? 'Despachar para Entrega'
                              : 'Confirmar Entrega Concluída'),
                      icon: order.status == OrderStatus.accepted
                          ? Icons.inventory_2_rounded
                          : (order.status == OrderStatus.preparing
                              ? Icons.two_wheeler_rounded
                              : Icons.task_alt_rounded),
                      variant: order.status == OrderStatus.accepted
                          ? BoraButtonVariant.primaryFlame
                          : (order.status == OrderStatus.preparing
                              ? BoraButtonVariant.primaryRoyal
                              : BoraButtonVariant.primarySuccess),
                      height: 50,
                      onPressed: () => _advanceOrder(order),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: isPending ? BoraPulsingHalo(child: cardContent) : cardContent,
        );
      },
    );
  }
}
