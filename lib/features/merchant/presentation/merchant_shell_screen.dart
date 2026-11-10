import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/audio_alert_service.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).switchDemoRole(UserRole.merchant);
    });
  }

  final List<Widget> _pages = const [
    MerchantKanbanScreen(),
    MerchantCatalogScreen(),
    MerchantPaymentConfigScreen(),
    MerchantFinancesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 750;
    final currentStore = ref.watch(currentMerchantStoreProvider);
    final allStores = ref.watch(storesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            // Badge Portal do Lojista
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 3),
                  Text(
                    'PORTAL LOJISTA',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Seletor da Distribuidora Ativa (Protegido por Expanded para NUNCA colidir)
            Expanded(
              child: allStores.length > 1
                  ? Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentStore.id,
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
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null) {
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
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
            ),
          ],
        ),
        actions: [
          // Alerta Sonoro de Novo Pedido
          IconButton(
            tooltip: 'Alerta Sonoro de Novo Pedido',
            icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFF6B00), size: 20),
            onPressed: () {
              ref.read(currentMerchantStoreProvider);
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

          // Menu de Alternância de Módulo (Compacto, sem texto sobreposto)
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22),
            tooltip: 'Alternar Módulo',
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF334155)),
            ),
            onSelected: (val) {
              if (val == 'client') {
                ref.read(authProvider.notifier).switchDemoRole(UserRole.customer);
                context.go('/home');
              } else if (val == 'courier') {
                ref.read(authProvider.notifier).switchDemoRole(UserRole.courier);
                context.go('/courier');
              } else if (val == 'admin') {
                ref.read(authProvider.notifier).switchDemoRole(UserRole.admin);
                context.go('/admin');
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'client',
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: Color(0xFF38BDF8), size: 18),
                    SizedBox(width: 10),
                    Text('App do Cliente', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'courier',
                child: Row(
                  children: [
                    Icon(Icons.two_wheeler_rounded, color: Color(0xFFFF6B00), size: 18),
                    SizedBox(width: 10),
                    Text('Rota do Entregador', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'admin',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 10),
                    Text('Super Admin Master', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              backgroundColor: const Color(0xFF0F172A),
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              labelType: NavigationRailLabelType.all,
              indicatorColor: const Color(0xFFFF6B00).withValues(alpha: 0.2),
              selectedIconTheme: const IconThemeData(color: Color(0xFFFF6B00)),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF64748B)),
              selectedLabelTextStyle: const TextStyle(color: Color(0xFFFF6B00), fontSize: 12, fontWeight: FontWeight.w800),
              unselectedLabelTextStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Pedidos (Kanban)'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: Text('Meus Produtos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments_rounded),
                  label: Text('Pagamentos BYOK'),
                ),
                NavigationRailDestination(
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
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: const Color(0xFF0F172A),
                  indicatorColor: const Color(0xFFFF6B00).withValues(alpha: 0.18),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(color: Color(0xFFFF6B00), fontSize: 11, fontWeight: FontWeight.w800);
                    }
                    return const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500);
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const IconThemeData(color: Color(0xFFFF6B00), size: 22);
                    }
                    return const IconThemeData(color: Color(0xFF64748B), size: 22);
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: 'Pedidos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2_rounded),
                      label: 'Produtos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.payments_outlined),
                      selectedIcon: Icon(Icons.payments_rounded),
                      label: 'Pagamentos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                      label: 'Finanças',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
