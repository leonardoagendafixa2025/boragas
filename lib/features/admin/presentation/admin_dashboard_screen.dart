import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/commission_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/providers/customer_providers.dart';
import '../../merchant/providers/merchant_providers.dart';
import 'widgets/sales_chart_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(storesProvider);
    final orders = ref.watch(ordersProvider);
    final invoices = ref.watch(commissionInvoicesProvider);

    final totalGMV = orders.fold(0.0, (sum, o) => sum + o.totalAmount);
    final totalCommissions = orders.fold(
      0.0,
      (sum, o) => sum + (o.totalAmount * (o.commissionRatePercent / 100)),
    );
    final pendingCommissions = invoices
        .where((i) => i.status != InvoiceStatus.paid)
        .fold(0.0, (sum, i) => sum + i.totalCommissionDue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão Geral & Comissões (Sem Mensalidade)'),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 18),
            label: const Text(
              'Desligar / Sair',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 13),
            ),
            onPressed: () async {
              final router = GoRouter.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  title: const Text('Desligar / Sair do Super Admin', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Deseja realmente encerrar a sessão administrativa e sair da conta?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Desligar e Sair', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authProvider.notifier).logout();
                router.go('/login');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Grid
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'GMV TOTAL (VENDAS)',
                    value: 'R\$ ${totalGMV.toStringAsFixed(2).replaceAll('.', ',')}',
                    subtitle: '100% repassado às lojas',
                    color: AppColors.primary,
                    icon: Icons.currency_exchange_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'RECEITA DE COMISSÕES',
                    value: 'R\$ ${totalCommissions.toStringAsFixed(2).replaceAll('.', ',')}',
                    subtitle: 'Média de 8% por pedido',
                    color: AppColors.success,
                    icon: Icons.savings_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'COMISSÕES A RECEBER',
                    value: 'R\$ ${pendingCommissions.toStringAsFixed(2).replaceAll('.', ',')}',
                    subtitle: 'Faturas em aberto/vencidas',
                    color: AppColors.accentFlame,
                    icon: Icons.pending_actions_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'DISTRIBUIDORAS ATIVAS',
                    value: '${stores.length} Lojas',
                    subtitle: '100% operando com BYOK',
                    color: const Color(0xFF6554C0),
                    icon: Icons.storefront_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Sales & Commission Evolution Chart (Calculado de Pedidos Reais)
            SalesChartWidget(orders: orders),

            const SizedBox(height: 24),

            // Revenue Ledger Breakdown
            const Text(
              'EXTRATO CONSOLIDADO DE REPASSES POR DISTRIBUIDORA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            stores.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6554C0).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            size: 32,
                            color: Color(0xFF6554C0),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhuma Distribuidora Cadastrada',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Cadastre suas primeiras distribuidoras na aba "Lojas" para iniciar as operações reais e repasses de comissões.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  )
                : Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stores.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final store = stores[index];
                        final storeOrders = orders.where((o) => o.storeId == store.id).toList();
                        final storeOrdersCount = storeOrders.length;
                        final storeSales = storeOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
                        final storeCommission = storeSales * (store.commissionRate / 100);

                        return ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.surfaceVariant,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(store.logoUrl, fit: BoxFit.cover),
                            ),
                          ),
                          title: Text(
                            store.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Taxa: ${store.commissionRate}% • $storeOrdersCount pedidos entregues',
                            style: AppTypography.bodySmall,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'R\$ ${storeCommission.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(
                                'Comissão Admin',
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 24),

            // Card de Desligar Sessão / Logout do Admin
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sessão de Controle Master Ativa',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF991B1B)),
                        ),
                        Text(
                          'Desconecte seu acesso de administrador para segurança.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () async {
                      final router = GoRouter.of(context);
                      await ref.read(authProvider.notifier).logout();
                      router.go('/login');
                    },
                    icon: const Icon(Icons.power_settings_new_rounded, size: 16),
                    label: const Text('Desligar Sessão', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
