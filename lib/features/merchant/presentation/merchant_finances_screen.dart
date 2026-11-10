import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/commission_model.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/merchant_providers.dart';

class MerchantFinancesScreen extends ConsumerWidget {
  const MerchantFinancesScreen({super.key});

  void _payInvoice(BuildContext context, WidgetRef ref, CommissionInvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.pix_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Pagar Fatura ${invoice.period}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pague a comissão de R\$ ${invoice.totalCommissionDue.toStringAsFixed(2).replaceAll('.', ',')} referente aos pedidos entregues via BoraGás:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 140, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invoice.pixCopyPaste));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código PIX Copia e Cola copiado!')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copiar Código PIX'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(commissionInvoicesProvider.notifier).payInvoice(invoice.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fatura quitada com sucesso! Visibilidade da loja 100% ativa.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Simular Pagamento Concluído'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStore = ref.watch(currentMerchantStoreProvider);
    final invoices = ref.watch(commissionInvoicesProvider)
        .where((inv) => inv.storeId == currentStore.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extrato & Comissões da Plataforma'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL VENDIDO NESTE MÊS (100% NA SUA CONTA)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'R\$ 28.690,00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Taxa BoraGás', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text(
                            '${currentStore.commissionRate}% por pedido',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mensalidade Fixa', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('R\$ 0,00 (Zero)', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'FATURAS DE COMISSÃO DA PLATAFORMA (LEDGER)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            ...invoices.map((inv) {
              final isOpen = inv.status == InvoiceStatus.open;
              final isOverdue = inv.status == InvoiceStatus.overdue;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isOverdue ? AppColors.error : AppColors.border,
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
                            inv.period,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: inv.status == InvoiceStatus.paid
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : (isOverdue ? AppColors.error.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              inv.status == InvoiceStatus.paid
                                  ? 'PAGA'
                                  : (isOverdue ? 'VENCIDA' : 'EM ABERTO'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: inv.status == InvoiceStatus.paid
                                    ? AppColors.success
                                    : (isOverdue ? AppColors.error : const Color(0xFFB78103)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total vendido pela loja: R\$ ${inv.totalStoreSales.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comissão devida (${inv.commissionPercent}%): R\$ ${inv.totalCommissionDue.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isOpen || isOverdue)
                        AppButton(
                          label: 'Pagar Fatura via PIX',
                          height: 44,
                          icon: Icons.pix_rounded,
                          onPressed: () => _payInvoice(context, ref, inv),
                        ),
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
