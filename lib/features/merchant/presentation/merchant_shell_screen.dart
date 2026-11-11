import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/audio_alert_service.dart';
import '../../../core/services/supabase_service.dart';
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
          // Interruptor da Loja (Ligar / Desligar Loja para Pedidos)
          InkWell(
            onTap: () {
              final newStatus = !currentStore.isOpen;
              final updated = currentStore.copyWith(isOpen: newStatus);
              ref.read(currentMerchantStoreProvider.notifier).set(updated);
              ref.read(storesProvider.notifier).update((stores) =>
                  stores.map((s) => s.id == currentStore.id ? updated : s).toList());

              if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
                SupabaseService.client
                    .from('stores')
                    .update({'is_open': newStatus})
                    .eq('id', currentStore.id)
                    .catchError((_) {});
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(newStatus
                      ? '🟢 Loja Ligada: Recebendo novos pedidos normalmente!'
                      : '🔴 Loja Desligada (Pausada): Clientes verão que está fechado.'),
                  backgroundColor: newStatus ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: currentStore.isOpen
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: currentStore.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentStore.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    currentStore.isOpen ? 'ABERTA' : 'DESLIGADA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: currentStore.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Alerta Sonoro de Novo Pedido
          IconButton(
            tooltip: 'Alerta Sonoro de Novo Pedido',
            icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFFF6B00), size: 19),
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

          // Sair da Loja / Desligar Sessão
          IconButton(
            tooltip: 'Desligar / Sair da Loja',
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 20),
            onPressed: () async {
              final router = GoRouter.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  title: const Text('Desligar / Sair do Portal', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Deseja realmente encerrar a sessão da sua distribuidora e sair da conta?',
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
