import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/order_model.dart';
import '../../customer/providers/customer_providers.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _searchQuery = '';
  OrderStatus? _selectedStatusFilter;

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month às $hour:$min';
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.accepted:
      case OrderStatus.preparing:
        return const Color(0xFF3B82F6);
      case OrderStatus.outForDelivery:
        return AppColors.primary;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendente';
      case OrderStatus.accepted:
        return 'Aceito';
      case OrderStatus.preparing:
        return 'Em Preparo';
      case OrderStatus.outForDelivery:
        return 'Em Rota';
      case OrderStatus.delivered:
        return 'Entregue';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  String _getPaymentModeLabel(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.onlinePix:
        return 'Pix Online (AbacatePay/Mercado Pago)';
      case PaymentMode.onlineCard:
        return 'Cartão Online (Mercado Pago)';
      case PaymentMode.posOnDelivery:
        return 'Maquininha na Entrega';
      case PaymentMode.cashOnDelivery:
        return 'Dinheiro na Entrega';
    }
  }

  void _showChangeStatusDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: Color(0xFF6554C0)),
            const SizedBox(width: 8),
            Text('Alterar Status: ${order.orderNumber}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Como Super Admin, você pode intervir manualmente no status deste pedido:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...OrderStatus.values.map((st) {
              final isCurrent = order.status == st;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isCurrent ? _getStatusColor(st) : AppColors.textSecondary,
                ),
                title: Text(
                  _getStatusLabel(st),
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? _getStatusColor(st) : AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  ref.read(ordersProvider.notifier).update(
                        (list) => list
                            .map((o) => o.id == order.id
                                ? o.copyWith(
                                    status: st,
                                    deliveredAt: st == OrderStatus.delivered ? DateTime.now() : o.deliveredAt,
                                  )
                                : o)
                            .toList(),
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Status do pedido ${order.orderNumber} alterado para ${_getStatusLabel(st)}'),
                      backgroundColor: _getStatusColor(st),
                    ),
                  );
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(ordersProvider);

    // Metrics
    final totalOrders = allOrders.length;
    final totalGmv = allOrders.fold<double>(0.0, (acc, o) => acc + o.totalAmount);
    final totalCommission = allOrders.fold<double>(0.0, (acc, o) => acc + o.platformCommissionAmount);
    final deliveredOrders = allOrders.where((o) => o.status == OrderStatus.delivered).length;

    // Filtering
    final filtered = allOrders.where((o) {
      if (_selectedStatusFilter != null && o.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchNum = o.orderNumber.toLowerCase().contains(q);
        final matchCust = o.customerName.toLowerCase().contains(q);
        final matchStore = o.storeName.toLowerCase().contains(q);
        final matchPhone = o.customerPhone.toLowerCase().contains(q);
        return matchNum || matchCust || matchStore || matchPhone;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor de Pedidos da Rede'),
      ),
      body: Column(
        children: [
          // Header Metrics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Total Pedidos',
                    value: '$totalOrders',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF6554C0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'GMV Transacionado',
                    value: 'R\$ ${totalGmv.toStringAsFixed(0)}',
                    icon: Icons.payments_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Comissões (8%)',
                    value: 'R\$ ${totalCommission.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Entregues',
                    value: '$deliveredOrders',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Search & Status Chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Buscar por pedido #BG, cliente, distribuidora ou WhatsApp...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip('Todos (${allOrders.length})', null),
                      const SizedBox(width: 8),
                      ...OrderStatus.values.map((st) {
                        final count = allOrders.where((o) => o.status == st).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildStatusFilterChip('${_getStatusLabel(st)} ($count)', st),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhum pedido encontrado',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ajuste os filtros de busca ou aguarde novos pedidos no app.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      final statusColor = _getStatusColor(order.status);
                      final storeRepasse = order.totalAmount - order.platformCommissionAmount;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: AppColors.border),
                        ),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Bar: Order Number, Date, Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(8),
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
                                        _formatDate(order.createdAt),
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getStatusLabel(order.status).toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 12),

                              // Store & Customer info
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF6554C0)),
                                            const SizedBox(width: 4),
                                            const Text('Distribuidora:',
                                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          order.storeName,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.person_rounded, size: 14, color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            const Text('Cliente:',
                                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${order.customerName} (${order.customerPhone})',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Endereço
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      order.deliveryAddress,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Itens
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...order.items.map((item) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppColors.border),
                                                ),
                                                child: Text(
                                                  '${item.quantity}x',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '${item.productName} (${item.isRefillOnly ? "Troca do Vazio" : "Comprar Casco Completo"})',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                              Text(
                                                'R\$ ${item.totalPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Pagamento & PIN
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Método de Pagamento',
                                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                      Text(
                                        _getPaymentModeLabel(order.paymentMode),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.pin_rounded, size: 14, color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              'PIN: ${order.deliveryConfirmationCode}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 10),

                              // Split Financeiro (Loja vs Plataforma)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Repasse à Distribuidora',
                                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      Text(
                                        'R\$ ${storeRepasse.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Split BoraGás (${order.commissionRatePercent}%)',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      Text(
                                        'R\$ ${order.platformCommissionAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: Color(0xFF6554C0),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Valor Total do Pedido',
                                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      Text(
                                        'R\$ ${order.totalAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Botão de Intervenção Super Admin
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    label: const Text('Copiar Tel. WhatsApp'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: order.customerPhone));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Telefone ${order.customerPhone} copiado!'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.tune_rounded, size: 14),
                                    label: const Text('Modificar Status'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6554C0),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () => _showChangeStatusDialog(order),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, OrderStatus? status) {
    final isSelected = _selectedStatusFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatusFilter = status),
      selectedColor: const Color(0xFF6554C0).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? const Color(0xFF6554C0) : AppColors.textSecondary,
      ),
    );
  }
}
