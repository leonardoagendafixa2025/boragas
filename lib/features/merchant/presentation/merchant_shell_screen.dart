import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/audio_alert_service.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customer/providers/customer_providers.dart';
import '../providers/merchant_providers.dart';
import 'merchant_catalog_screen.dart';
import 'merchant_finances_screen.dart';
import 'merchant_kanban_screen.dart';
import 'merchant_payment_config_screen.dart';

class MerchantShellScreen extends ConsumerStatefulWidget {
  const MerchantShellScreen({super.key});

  @override
  ConsumerState<MerchantShellScreen> createState() => _MerchantShellScreenState();
}

class _MerchantShellScreenState extends ConsumerState<MerchantShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MerchantKanbanScreen(),
    MerchantCatalogScreen(),
    MerchantPaymentConfigScreen(),
    MerchantFinancesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Bloqueio de segurança em camadas: Se não for lojista ou admin autenticado, redireciona para login
    if (GoRouter.maybeOf(context) != null && (!auth.isAuthenticated || (auth.user?.role != UserRole.merchant && auth.user?.role != UserRole.admin))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return const Scaffold(
        backgroundColor: AppColors.merchantCanvas,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentFlame),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 750;
    final currentStore = ref.watch(currentMerchantStoreProvider);
    final allStores = ref.watch(storesProvider);
    final allOrders = ref.watch(ordersProvider);

    // Contagem de pedidos novos para badge na bottom bar
    final pendingOrdersCount = allOrders
        .where((o) => o.storeId == currentStore.id && (o.status == OrderStatus.pending || o.status == OrderStatus.accepted))
        .length;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.merchantCanvas,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accentFlame,
          surface: AppColors.merchantCard,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.merchantCanvas,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            // Badge Portal do Lojista
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.flameGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentFlame.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded, color: Colors.white, size: 14),
                  if (isWide) ...[
                    const SizedBox(width: 4),
                    const Text(
                      'PORTAL LOJISTA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Seletor da Distribuidora Ativa
            Expanded(
              child: allStores.length > 1
                  ? Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: allStores.any((s) => s.id == currentStore.id)
                              ? currentStore.id
                              : allStores.first.id,
                          dropdownColor: const Color(0xFF1E293B),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 18),
                          items: allStores.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                s.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null) {
                              HapticFeedback.selectionClick();
                              final found = allStores.firstWhere((s) => s.id == newId);
                              ref.read(currentMerchantStoreProvider.notifier).set(found);
                            }
                          },
                        ),
                      ),
                    )
                  : Text(
                      currentStore.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
            ),
          ],
        ),
        actions: [
          // Se for Super Admin inspecionando o lojista, botão para voltar ao Painel Admin
          if (auth.user?.role == UserRole.admin) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B5CF6),
                side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.shield_rounded, size: 14),
              label: const Text('Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () {
                HapticFeedback.selectionClick();
                context.go('/admin');
              },
            ),
            const SizedBox(width: 4),
          ],

          // Interruptor da Loja (Ligar / Desligar Loja para Pedidos)
          InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              final newStatus = ref.read(currentMerchantStoreProvider.notifier).toggleOpen();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(newStatus
                      ? '🟢 Loja Ligada: Recebendo novos pedidos normalmente!'
                      : '🔴 Loja Desligada (Pausada): Clientes verão que está fechado.'),
                  backgroundColor: newStatus ? AppColors.success : AppColors.error,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: StatusBadge.storeOpen(isOpen: currentStore.isOpen),
          ),
          const SizedBox(width: 4),

          // Alerta Sonoro de Novo Pedido (Teste / Toque)
          IconButton(
            tooltip: 'Alerta Sonoro de Pedido',
            icon: const Icon(Icons.notifications_active_rounded, color: AppColors.accentFlame, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              AudioAlertService.playNewOrderAlert();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔔 Alerta sonoro de novo pedido acionado!'),
                  backgroundColor: Color(0xFF1E293B),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          // Sair da Loja / Desligar Sessão
          IconButton(
            tooltip: 'Desligar / Sair da Loja',
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 20),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final router = GoRouter.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF111827),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Desligar / Sair do Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  content: const Text(
                    'Deseja realmente encerrar a sessão da sua distribuidora e sair da conta?',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              backgroundColor: const Color(0xFF0F172A),
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) {
                HapticFeedback.selectionClick();
                setState(() => _currentIndex = idx);
              },
              labelType: NavigationRailLabelType.all,
              indicatorColor: AppColors.accentFlame.withValues(alpha: 0.18),
              selectedIconTheme: const IconThemeData(color: AppColors.accentFlame),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF64748B)),
              selectedLabelTextStyle: const TextStyle(color: AppColors.accentFlame, fontSize: 12, fontWeight: FontWeight.w800),
              unselectedLabelTextStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              destinations: [
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: pendingOrdersCount > 0,
                    label: Text('$pendingOrdersCount'),
                    backgroundColor: AppColors.accentFlame,
                    child: const Icon(Icons.dashboard_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: pendingOrdersCount > 0,
                    label: Text('$pendingOrdersCount'),
                    backgroundColor: AppColors.accentFlame,
                    child: const Icon(Icons.dashboard_rounded),
                  ),
                  label: const Text('Pedidos'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: Text('Produtos'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments_rounded),
                  label: Text('Pagamentos'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: Text('Finanças'),
                ),
              ],
            ),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(top: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: const Color(0xFF0F172A),
                  indicatorColor: AppColors.accentFlame.withValues(alpha: 0.18),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(color: AppColors.accentFlame, fontSize: 11, fontWeight: FontWeight.w800);
                    }
                    return const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500);
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const IconThemeData(color: AppColors.accentFlame, size: 22);
                    }
                    return const IconThemeData(color: Color(0xFF64748B), size: 22);
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) {
                    HapticFeedback.selectionClick();
                    setState(() => _currentIndex = idx);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: pendingOrdersCount > 0,
                        label: Text('$pendingOrdersCount'),
                        backgroundColor: AppColors.accentFlame,
                        child: const Icon(Icons.dashboard_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: pendingOrdersCount > 0,
                        label: Text('$pendingOrdersCount'),
                        backgroundColor: AppColors.accentFlame,
                        child: const Icon(Icons.dashboard_rounded),
                      ),
                      label: 'Pedidos',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2_rounded),
                      label: 'Produtos',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.payments_outlined),
                      selectedIcon: Icon(Icons.payments_rounded),
                      label: 'Pagamentos',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                      label: 'Finanças',
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
