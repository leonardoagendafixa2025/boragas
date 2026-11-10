import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/audio_alert_service.dart';
import '../../../core/widgets/status_badge.dart';
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
      final clean = phone.replaceAll(RegExp(r'\D'), '');
      final uri = Uri.parse('tel:$clean');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
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
          ? 'Marcos Oliveira (Honda Fan 160)'
          : order.courierName,
      courierPhone: next == OrderStatus.outForDelivery
          ? '(11) 97722-1199'
          : order.courierPhone,
    );

    ref.read(ordersProvider.notifier).update(
          (list) => list.map((o) => o.id == order.id ? updated : o).toList(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido ${order.orderNumber} atualizado para "${next.name}"!'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _simulateNewOrder(String storeId, String storeName) {
    final randNum = 8844 + (DateTime.now().millisecondsSinceEpoch % 100);
    final simulatedOrder = OrderModel(
      id: 'ord-sim-$randNum',
      orderNumber: '#BG-$randNum',
      customerId: 'usr-sim-02',
      customerName: 'Fernanda Lima',
      customerPhone: '(11) 98765-4321',
      storeId: storeId,
      storeName: storeName,
      items: const [
        OrderItemModel(
          productId: 'prod-1',
          productName: 'Botijão P13 (13kg) - Troca de Vasilhame',
          quantity: 1,
          isRefillOnly: true,
          unitPrice: 104.90,
          totalPrice: 104.90,
        ),
      ],
      deliveryAddress: 'Alameda Santos, 1200 - Cerqueira César, São Paulo - SP',
      subtotal: 104.90,
      deliveryFee: 0.0,
      totalAmount: 104.90,
      status: OrderStatus.accepted,
      paymentMode: PaymentMode.onlinePix,
      paymentStatus: PaymentStatus.paidDirectlyToStore,
      commissionRatePercent: 8.0,
      platformCommissionAmount: 8.39,
      deliveryConfirmationCode: '7281',
      createdAt: DateTime.now(),
    );

    ref.read(ordersProvider.notifier).update((list) => [simulatedOrder, ...list]);
    AudioAlertService.playNewOrderAlert();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔔 Novo pedido #BG-$randNum recebido na distribuidora!'),
        backgroundColor: const Color(0xFFFF6B00),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStore = ref.watch(currentMerchantStoreProvider);
    final allOrders = ref.watch(ordersProvider);
    final authUser = ref.watch(authProvider).user;

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

    // Cálculo real do Faturamento Hoje da Distribuidora
    final totalRevenue = storeOrders
        .where((o) => o.status != OrderStatus.cancelled)
        .fold<double>(0.0, (acc, item) => acc + item.totalAmount);

    return Container(
      color: const Color(0xFF0B1120),
      child: Column(
        children: [
          // 1. HUD de Faturamento & Operação Tática da Distribuidora (Cockpit Ribbon)
          _buildExecutiveStatsRibbon(
            totalRevenue: totalRevenue,
            activeCount: newOrders.length + inTransitOrders.length,
            courierName: authUser?.role == UserRole.courier
                ? (authUser?.name ?? 'Marcos Oliveira')
                : 'Marcos Oliveira',
            courierVehicle: authUser?.vehicleModel ?? 'Honda Fan 160',
          ),

          // 2. Barra de Segmentos (Tabs Táticas: Novos, Em Rota, Concluídos)
          _buildSegmentedTabBar(
            newCount: newOrders.length,
            inTransitCount: inTransitOrders.length,
            completedCount: completedOrders.length,
          ),

          // 3. Conteúdo das Abas (Kanban)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewOrdersTab(newOrders, currentStore.id, currentStore.name),
                _buildOrdersList(inTransitOrders, isTransitTab: true),
                _buildOrdersList(completedOrders, isCompletedTab: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1. HUD Executivo de Faturamento e Frota
  Widget _buildExecutiveStatsRibbon({
    required double totalRevenue,
    required int activeCount,
    required String courierName,
    required String courierVehicle,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E3D56)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bloco Faturamento Hoje (O que traz o dinheiro!)
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'FATURAMENTO HOJE',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'R\$ ${totalRevenue.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '100% repassado à sua conta • Taxa 8% BoraGás',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 38,
            width: 1,
            color: const Color(0xFF2E3D56),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),

          // Bloco Despacho & Frota
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.two_wheeler_rounded, color: Color(0xFFFF6B00), size: 12),
                    const SizedBox(width: 4),
                    const Text(
                      'DESPACHO & FROTA',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  activeCount > 0 ? '$activeCount em andamento' : 'Depósito Pronto',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: activeCount > 0 ? const Color(0xFF38BDF8) : Colors.white,
                    fontSize: 13,
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
                    fontSize: 9.5,
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

  /// 2. Segmented Tab Bar Tática
  Widget _buildSegmentedTabBar({
    required int newCount,
    required int inTransitCount,
    required int completedCount,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E3D56)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFFFF6B00),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Novos'),
                if (newCount > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$newCount',
                      style: const TextStyle(
                        color: Color(0xFFFF6B00),
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
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(8),
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

  /// 3. Aba de Novos Pedidos (Com Radar Ativo e Simulação de Teste)
  Widget _buildNewOrdersTab(List<OrderModel> orders, String storeId, String storeName) {
    if (orders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Radar Visual Glow
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
                  border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.35), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.radar_rounded,
                    color: Color(0xFFFF6B00),
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Radar de Vendas Ativo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Sua distribuidora está aberta e visível no raio de até 8 km. Novos pedidos via App ou WhatsApp acionarão o alarme sonoro instantaneamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              // Botão para simular pedido e testar o fluxo de ponta a ponta
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: const Color(0xFFFF6B00),
                  side: const BorderSide(color: Color(0xFFFF6B00)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _simulateNewOrder(storeId, storeName),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                label: const Text(
                  'Simular Novo Pedido (Teste)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildOrdersList(orders, isNewTab: true);
  }

  /// Lista de Pedidos com Cards Táticos
  Widget _buildOrdersList(
    List<OrderModel> orders, {
    bool isNewTab = false,
    bool isTransitTab = false,
    bool isCompletedTab = false,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          isTransitTab
              ? 'Nenhum pedido em rota agora.'
              : 'Nenhum pedido concluído recentemente.',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isPendingAction = order.status == OrderStatus.accepted || order.status == OrderStatus.pending;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161F30),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPendingAction ? const Color(0xFFFF6B00) : const Color(0xFF2E3D56),
              width: isPendingAction ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha 1: Pedido + StatusBadge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B00),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.orderNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Há ${index == 0 ? "4" : "12"} min',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                    StatusBadge.fromOrderStatus(order.status),
                  ],
                ),

                const SizedBox(height: 12),

                // Linha 2: Contato do Cliente (Com Botões WhatsApp e Ligar Rápidos)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Color(0xFF38BDF8), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              order.customerPhone,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      // Botão WhatsApp Oficial
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _whatsappCustomer(order.customerPhone, order.orderNumber),
                        icon: const Icon(Icons.chat_rounded, size: 13),
                        label: const Text('WhatsApp', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 6),
                      // Botão Ligar
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(32, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _callCustomer(order.customerPhone),
                        icon: const Icon(Icons.phone, size: 14),
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
                    const Icon(Icons.location_on_rounded, color: Color(0xFFFF6B00), size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.deliveryAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFF2E3D56)),
                const SizedBox(height: 10),

                // Lista de Itens do Pedido
                ...order.items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${i.quantity}x ${i.productName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            'R\$ ${i.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 10),

                // Linha de Meio de Pagamento & PIN de Segurança
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payment_rounded, size: 14, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 5),
                          Text(
                            order.paymentMode.name.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('PIN de Entrega: ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          Text(
                            order.deliveryConfirmationCode,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF6B00),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Se houver entregador atribuído
                if (order.courierName != null && order.courierName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.two_wheeler_rounded, color: Color(0xFF94A3B8), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Entregador: ${order.courierName}',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Botão de Avanço do Fluxo Operacional
                if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) ...[
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
                        size: 17,
                      ),
                      label: Text(
                        order.status == OrderStatus.accepted
                            ? 'Aceitar e Iniciar Separação'
                            : (order.status == OrderStatus.preparing
                                ? 'Despachar com Motoboy Marcos'
                                : 'Confirmar Entrega Concluída (PIN)'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: order.status == OrderStatus.accepted
                            ? const Color(0xFFFF6B00)
                            : (order.status == OrderStatus.preparing
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF10B981)),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
