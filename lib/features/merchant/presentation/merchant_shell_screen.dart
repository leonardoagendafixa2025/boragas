import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import 'merchant_catalog_screen.dart';
import 'merchant_finances_screen.dart';
import 'merchant_kanban_screen.dart';
import 'merchant_payment_config_screen.dart';

class MerchantShellScreen extends StatefulWidget {
  const MerchantShellScreen({super.key});

  @override
  State<MerchantShellScreen> createState() => _MerchantShellScreenState();
}

class _MerchantShellScreenState extends State<MerchantShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MerchantKanbanScreen(),
    MerchantCatalogScreen(),
    MerchantPaymentConfigScreen(),
    MerchantFinancesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

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
                'LOJISTA',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Portal do Distribuidor BoraGás', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            label: const Text('Voltar ao App Cliente', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
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
                  label: Text('Kanban'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: Text('Catálogo'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.payment_outlined),
                  selectedIcon: Icon(Icons.payment_rounded),
                  label: Text('API & POS'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: Text('Comissões'),
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
                  label: 'Kanban',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                  label: 'Catálogo',
                ),
                NavigationDestination(
                  icon: Icon(Icons.payment_outlined),
                  selectedIcon: Icon(Icons.payment_rounded, color: AppColors.primary),
                  label: 'API & POS',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                  label: 'Comissões',
                ),
              ],
            ),
    );
  }
}
