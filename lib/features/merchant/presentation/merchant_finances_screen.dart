import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/commission_model.dart';
import '../../../core/models/order_model.dart';
import '../../../core/widgets/ui/bora_button.dart';
import '../../../core/widgets/ui/bora_card.dart';
import '../../../core/widgets/ui/bora_empty_state.dart';
import '../../customer/providers/customer_providers.dart';
import '../providers/merchant_providers.dart';

class MerchantFinancesScreen extends ConsumerWidget {
  const MerchantFinancesScreen({super.key});

  void _payInvoice(BuildContext context, WidgetRef ref, CommissionInvoiceModel invoice) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0x1FFFFFFF), width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pix_rounded, color: Color(0xFF38BDF8), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pagar Fatura • ${invoice.period}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const Text(
                        'Taxa de intermediação sobre vendas entregues',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: Column(
                children: [
                  const Text('VALOR DA COMISSÃO', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${invoice.totalCommissionDue.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, size: 140, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  BoraButton.outline(
                    text: 'Copiar Chave PIX Copia e Cola',
                    icon: Icons.copy_rounded,
                    height: 44,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: invoice.pixCopyPaste));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código PIX Copia e Cola copiado!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BoraButton.flame(
              text: 'Confirmar Pagamento Realizado',
              icon: Icons.check_circle_rounded,
              height: 50,
              onPressed: () {
                ref.read(commissionInvoicesProvider.notifier).payInvoice(invoice.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fatura quitada com sucesso! Visibilidade da loja 100% ativa.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStore = ref.watch(currentMerchantStoreProvider);
    final allOrders = ref.watch(ordersProvider);
    final invoices = ref.watch(commissionInvoicesProvider)
        .where((inv) => inv.storeId == currentStore.id)
        .toList();

    // Cálculo dinâmico das vendas totais entregues da loja
    final storeDeliveredOrders = allOrders
        .where((o) => o.storeId == currentStore.id && o.status == OrderStatus.delivered)
        .toList();

    final totalDeliveredSales = storeDeliveredOrders.fold<double>(
      0.0,
      (acc, o) => acc + o.totalAmount,
    );

    return Container(
      color: AppColors.merchantCanvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Financeiro
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Extrato & Repasses',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currentStore.name} • 100% repassado à sua conta',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hero Card Financeiro (Linear / Nubank style)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x1FFFFFFF), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL FATURADO (VENDAS)',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, color: AppColors.success, size: 11),
                            SizedBox(width: 3),
                            Text(
                              'BYOK ATIVO',
                              style: TextStyle(color: AppColors.success, fontSize: 9.5, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'R\$ ${totalDeliveredSales.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0x14FFFFFF), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Taxa Plataforma', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            '${currentStore.commissionRate}% por pedido',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                          ),
                        ],
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Mensalidade Fixa', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          SizedBox(height: 2),
                          Text(
                            'R\$ 0,00 (Zero)',
                            style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w800, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Título Seção Faturas
            const Text(
              'FATURAS DE COMISSÃO DA PLATAFORMA',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            if (invoices.isEmpty)
              const BoraEmptyState(
                icon: Icons.receipt_long_rounded,
                iconColor: Color(0xFF38BDF8),
                title: 'Nenhuma fatura pendente',
                description: 'Todas as suas taxas de comissão estão em dia! Quando houver um fechamento quinzenal ou mensal, a fatura aparecerá aqui.',
              )
            else
              ...invoices.map((inv) {
                final isOpen = inv.status == InvoiceStatus.open;
                final isOverdue = inv.status == InvoiceStatus.overdue;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BoraCard(
                    color: AppColors.merchantCard,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              inv.period,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: inv.status == InvoiceStatus.paid
                                    ? AppColors.success.withValues(alpha: 0.16)
                                    : (isOverdue ? AppColors.error.withValues(alpha: 0.16) : AppColors.warning.withValues(alpha: 0.16)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: inv.status == InvoiceStatus.paid
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : (isOverdue ? AppColors.error.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.3)),
                                ),
                              ),
                              child: Text(
                                inv.status == InvoiceStatus.paid
                                    ? 'PAGA'
                                    : (isOverdue ? 'VENCIDA' : 'EM ABERTO'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: inv.status == InvoiceStatus.paid
                                      ? AppColors.success
                                      : (isOverdue ? AppColors.error : AppColors.warning),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total vendido pela loja: R\$ ${inv.totalStoreSales.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Comissão (${inv.commissionPercent}%): R\$ ${inv.totalCommissionDue.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                        if (isOpen || isOverdue) ...[
                          const SizedBox(height: 12),
                          BoraButton.flame(
                            text: 'Pagar Fatura via PIX',
                            icon: Icons.pix_rounded,
                            height: 44,
                            onPressed: () => _payInvoice(context, ref, inv),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
