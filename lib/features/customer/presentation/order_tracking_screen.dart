import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/order_model.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/customer_providers.dart';
import 'widgets/live_tracking_map_widget.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  void _advanceOrderSimulation(OrderModel order) {
    OrderStatus nextStatus = order.status;
    switch (order.status) {
      case OrderStatus.pending:
        nextStatus = OrderStatus.accepted;
        break;
      case OrderStatus.accepted:
        nextStatus = OrderStatus.preparing;
        break;
      case OrderStatus.preparing:
        nextStatus = OrderStatus.outForDelivery;
        break;
      case OrderStatus.outForDelivery:
        nextStatus = OrderStatus.delivered;
        break;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return;
    }

    final updated = order.copyWith(
      status: nextStatus,
      deliveredAt: nextStatus == OrderStatus.delivered ? DateTime.now() : null,
      courierName: nextStatus == OrderStatus.outForDelivery
          ? 'Marcos Oliveira (Honda Fan 160)'
          : order.courierName,
    );

    ref.read(ordersProvider.notifier).update(
          (list) => list.map((o) => o.id == order.id ? updated : o).toList(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulação Realtime: Pedido avançou para "${updated.status.name}"!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final order = orders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => orders.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Acompanhar ${order.orderNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Avançar Simulação (Realtime)',
            onPressed: () => _advanceOrderSimulation(order),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      StatusBadge.fromOrderStatus(order.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getStatusHeading(order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getStatusSubheading(order.status),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),

                  // Delivery confirmation code (Security pin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CÓDIGO DE CONFIRMAÇÃO',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Informe ao entregador na porta:',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          order.deliveryConfirmationCode,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Live Tracking Animated GPS Map (BoraGas Realtime + OSRM)
            LiveTrackingMapWidget(
              orderId: order.id,
              courierName: order.courierName ?? 'Marcos Oliveira (Honda Fan 160)',
              storeName: order.storeName,
              destinationAddress: order.deliveryAddress,
            ),

            const SizedBox(height: 24),

            // Stepper
            const Text(
              'PROGRESSO DA ENTREGA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            _buildOrderStepper(order.status),

            const SizedBox(height: 24),

            // Courier / Store Action Card
            if (order.courierName != null &&
                order.status == OrderStatus.outForDelivery) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Entregador Autorizado',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          Text(
                            order.courierName ?? 'Entregador BoraGás',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                      onPressed: () => context.push('/support'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Order details summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Distribuidora',
                        style: AppTypography.bodySmall,
                      ),
                      Text(
                        order.storeName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Endereço de Entrega', style: AppTypography.bodySmall),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Forma de Pagamento', style: AppTypography.bodySmall),
                      Text(
                        _getPaymentModeText(order.paymentMode),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  ...order.items.map((i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${i.quantity}x ${i.productName}', style: const TextStyle(fontSize: 13)),
                            Text('R\$ ${i.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pago', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(
                        'R\$ ${order.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Support & Helpdesk CTA
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Precisa de Ajuda?',
                    isSecondary: true,
                    icon: Icons.support_agent_rounded,
                    onPressed: () => context.push('/support'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Voltar ao Início',
                    onPressed: () => context.go('/home'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStepper(OrderStatus status) {
    final steps = [
      {'title': 'Pedido Confirmado', 'desc': 'A distribuidora recebeu seu pedido'},
      {'title': 'Em Preparação', 'desc': 'Botijão aferido e separado para o motoqueiro'},
      {'title': 'A Caminho ⚡', 'desc': 'O entregador está em trânsito até você'},
      {'title': 'Entregue com Sucesso', 'desc': 'Pedido concluído com lacre verificado'},
    ];

    int activeIndex = 0;
    if (status == OrderStatus.accepted) activeIndex = 0;
    if (status == OrderStatus.preparing) activeIndex = 1;
    if (status == OrderStatus.outForDelivery) activeIndex = 2;
    if (status == OrderStatus.delivered) activeIndex = 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final isPast = index <= activeIndex;
          final isCurrent = index == activeIndex;
          final isLast = index == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPast
                          ? (isCurrent ? AppColors.accentFlame : AppColors.primary)
                          : AppColors.surfaceVariant,
                    ),
                    child: Center(
                      child: Icon(
                        isPast ? Icons.check_rounded : Icons.circle_rounded,
                        size: 14,
                        color: isPast ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 34,
                      color: isPast && !isCurrent ? AppColors.primary : AppColors.border,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[index]['title']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isCurrent
                              ? AppColors.textPrimary
                              : (isPast ? AppColors.textPrimary : AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        steps[index]['desc']!,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color: isPast ? AppColors.textSecondary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _getStatusHeading(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return 'Pedido Confirmado!';
      case OrderStatus.preparing:
        return 'Separando seu Gás...';
      case OrderStatus.outForDelivery:
        return 'Entregador a Caminho! ⚡';
      case OrderStatus.delivered:
        return 'Entrega Concluída!';
      case OrderStatus.cancelled:
        return 'Pedido Cancelado';
    }
  }

  String _getStatusSubheading(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return 'A loja já está agendando a saída do seu botijão.';
      case OrderStatus.preparing:
        return 'O lacre foi inspecionado e o entregador está saindo.';
      case OrderStatus.outForDelivery:
        return 'Previsão de chegada em aproximadamente 12 minutos.';
      case OrderStatus.delivered:
        return 'Obrigado por pedir com o BoraGás!';
      case OrderStatus.cancelled:
        return 'Se houver dúvidas, contate o nosso suporte.';
    }
  }

  String _getPaymentModeText(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.onlinePix:
        return 'PIX Online (Direto à Loja)';
      case PaymentMode.onlineCard:
        return 'Cartão Online';
      case PaymentMode.posOnDelivery:
        return 'Maquininha na Entrega';
      case PaymentMode.cashOnDelivery:
        return 'Dinheiro na Entrega';
    }
  }
}
