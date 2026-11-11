import 'package:flutter/material.dart';
import '../models/order_model.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final BoxBorder? border;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.border,
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

  factory StatusBadge.gas({String label = 'GÁS GLP'}) {
    return StatusBadge(
      label: label,
      backgroundColor: const Color(0xFFFF5630).withValues(alpha: 0.15),
      textColor: const Color(0xFFFF5630),
      icon: Icons.local_fire_department_rounded,
      border: Border.all(color: const Color(0xFFFF5630).withValues(alpha: 0.3), width: 1),
    );
  }

  factory StatusBadge.water({String label = 'ÁGUA 20L'}) {
    return StatusBadge(
      label: label,
      backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
      textColor: const Color(0xFF38BDF8),
      icon: Icons.water_drop_rounded,
      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3), width: 1),
    );
  }

  factory StatusBadge.storeOpen({required bool isOpen}) {
    return StatusBadge(
      label: isOpen ? 'LOJA ABERTA' : 'DESLIGADA',
      backgroundColor: isOpen
          ? const Color(0xFF10B981).withValues(alpha: 0.16)
          : const Color(0xFFEF4444).withValues(alpha: 0.16),
      textColor: isOpen ? const Color(0xFF34D399) : const Color(0xFFF87171),
      icon: isOpen ? Icons.check_circle_rounded : Icons.power_settings_new_rounded,
      border: Border.all(
        color: isOpen
            ? const Color(0xFF10B981).withValues(alpha: 0.4)
            : const Color(0xFFEF4444).withValues(alpha: 0.4),
        width: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: border,
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
