import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentFlame,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PORTAL DO LOJISTA',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            // Seletor da Distribuidora Ativa
            if (allStores.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentStore.id,
                    dropdownColor: const Color(0xFF1E293B),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                    items: allStores.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          s.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
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
            else
              Text(
                currentStore.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () {
              ref.read(authProvider.notifier).switchDemoRole(UserRole.admin);
              context.go('/admin');
            },
            icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
            label: const Text('Super Admin', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () {
              ref.read(authProvider.notifier).switchDemoRole(UserRole.customer);
              context.go('/home');
            },
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('App do Cliente', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              labelType: NavigationRailLabelType.all,
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
                  icon: Icon(Icons.payment_outlined),
                  selectedIcon: Icon(Icons.payment_rounded),
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
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
                  label: 'Pedidos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                  label: 'Produtos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.payment_outlined),
                  selectedIcon: Icon(Icons.payment_rounded, color: AppColors.primary),
                  label: 'Pagamentos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                  label: 'Finanças',
                ),
              ],
            ),
    );
  }
}
