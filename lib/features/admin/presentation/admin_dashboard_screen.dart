import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/commission_model.dart';
import '../../../core/widgets/ui/bora_button.dart';
import '../../../core/widgets/ui/bora_card.dart';
import '../../../core/widgets/ui/bora_empty_state.dart';
import '../../../core/widgets/ui/bora_kpi_card.dart';
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
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visão Geral & Comissões',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Monitoramento em tempo real de GMV, taxas e repasses',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6554C0).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'SEM MENSALIDADE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6554C0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Horizontal Scrollable KPI Row (Zero Truncation on any mobile screen)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  BoraKpiCard(
                    label: 'GMV Total (Vendas)',
                    value: 'R\$ ${totalGMV.toStringAsFixed(2).replaceAll('.', ',')}',
                    icon: Icons.currency_exchange_rounded,
                    iconColor: AppColors.primary,
                    subtitle: '100% repassado às lojas',
                  ),
                  const SizedBox(width: 10),
                  BoraKpiCard(
                    label: 'Receita de Comissões',
                    value: 'R\$ ${totalCommissions.toStringAsFixed(2).replaceAll('.', ',')}',
                    icon: Icons.savings_rounded,
                    iconColor: AppColors.success,
                    subtitle: 'Média de 8% por pedido',
                  ),
                  const SizedBox(width: 10),
                  BoraKpiCard(
                    label: 'Comissões a Receber',
                    value: 'R\$ ${pendingCommissions.toStringAsFixed(2).replaceAll('.', ',')}',
                    icon: Icons.pending_actions_rounded,
                    iconColor: AppColors.accentFlame,
                    subtitle: 'Faturas em aberto/vencidas',
                  ),
                  const SizedBox(width: 10),
                  BoraKpiCard(
                    label: 'Distribuidoras Ativas',
                    value: '${stores.length} Lojas',
                    icon: Icons.storefront_rounded,
                    iconColor: const Color(0xFF6554C0),
                    subtitle: 'Operando via BYOK',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sales & Commission Evolution Chart
            SalesChartWidget(orders: orders),

            const SizedBox(height: 24),

            // Revenue Ledger Breakdown
            const Text(
              'EXTRATO CONSOLIDADO DE REPASSES POR DISTRIBUIDORA',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            stores.isEmpty
                ? const BoraEmptyState(
                    icon: Icons.storefront_rounded,
                    iconColor: Color(0xFF6554C0),
                    title: 'Nenhuma Distribuidora Cadastrada',
                    description: 'Cadastre suas primeiras distribuidoras na aba "Lojas" para iniciar as operações reais e repasses de comissões.',
                  )
                : BoraCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stores.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final store = stores[index];
                        final storeOrders = orders.where((o) => o.storeId == store.id).toList();
                        final storeOrdersCount = storeOrders.length;
                        final storeSales = storeOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
                        final storeCommission = storeSales * (store.commissionRate / 100);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 44,
                              height: 44,
                              color: AppColors.surfaceVariant,
                              child: Image.asset(store.logoUrl, fit: BoxFit.cover),
                            ),
                          ),
                          title: Text(
                            store.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Taxa: ${store.commissionRate}% • $storeOrdersCount pedidos entregues',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'R\$ ${storeCommission.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Text(
                                'Comissão Admin',
                                style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 24),

            // Card de Desligar Sessão
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 26),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sessão Master Ativa',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF991B1B)),
                        ),
                        Text(
                          'Desconecte o acesso de administrador ao finalizar.',
                          style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                        ),
                      ],
                    ),
                  ),
                  BoraButton.danger(
                    text: 'Desligar',
                    icon: Icons.power_settings_new_rounded,
                    height: 40,
                    borderRadius: 12,
                    onPressed: () async {
                      final router = GoRouter.of(context);
                      await ref.read(authProvider.notifier).logout();
                      router.go('/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
