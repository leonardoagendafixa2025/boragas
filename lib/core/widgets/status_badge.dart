import 'package:flutter/material.dart';
import '../models/order_model.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.fromOrderStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const StatusBadge(
          label: 'Aguardando Loja',
          backgroundColor: Color(0xFFFFF0B3),
          textColor: Color(0xFF172B4D),
          icon: Icons.hourglass_top_rounded,
        );
      case OrderStatus.accepted:
        return const StatusBadge(
          label: 'Aceito pela Loja',
          backgroundColor: Color(0xFFDEEBFF),
          textColor: Color(0xFF0747A6),
          icon: Icons.check_circle_outline,
        );
      case OrderStatus.preparing:
        return const StatusBadge(
          label: 'Em Preparação',
          backgroundColor: Color(0xFFEAE6FF),
          textColor: Color(0xFF403294),
          icon: Icons.inventory_2_outlined,
        );
      case OrderStatus.outForDelivery:
        return const StatusBadge(
          label: 'A Caminho ⚡',
          backgroundColor: Color(0xFFFFEBE6),
          textColor: Color(0xFFBF2600),
          icon: Icons.two_wheeler_rounded,
        );
      case OrderStatus.delivered:
        return const StatusBadge(
          label: 'Entregue',
          backgroundColor: Color(0xFFE3FCEF),
          textColor: Color(0xFF006644),
          icon: Icons.task_alt_rounded,
        );
      case OrderStatus.cancelled:
        return const StatusBadge(
          label: 'Cancelado',
          backgroundColor: Color(0xFFFFEBE6),
          textColor: Color(0xFFBF2600),
          icon: Icons.cancel_outlined,
        );
    }
  }

  factory StatusBadge.verified() {
    return const StatusBadge(
      label: 'Verificado',
      backgroundColor: Color(0xFFE3FCEF),
      textColor: Color(0xFF006644),
      icon: Icons.verified_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
