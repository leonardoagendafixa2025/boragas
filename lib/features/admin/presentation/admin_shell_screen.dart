import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'admin_dashboard_screen.dart';
import 'admin_home_manager_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_remote_config_screen.dart';
import 'admin_stores_screen.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    AdminOrdersScreen(),
    AdminProductsScreen(),
    AdminStoresScreen(),
    AdminHomeManagerScreen(),
    AdminRemoteConfigScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 750;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6554C0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'SUPER ADMIN',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            const Text('BoraGás Master Control', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/merchant'),
            icon: const Icon(Icons.storefront_rounded, color: Colors.white, size: 16),
            label: const Text('Portal Lojista', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
            label: const Text('App do Cliente', style: TextStyle(color: Colors.white, fontSize: 12)),
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
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics_rounded),
                  label: Text('Comissões'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: Text('Pedidos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: Text('Produtos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.store_mall_directory_outlined),
                  selectedIcon: Icon(Icons.store_mall_directory_rounded),
                  label: Text('Lojas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.view_carousel_outlined),
                  selectedIcon: Icon(Icons.view_carousel_rounded),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_remote_outlined),
                  selectedIcon: Icon(Icons.settings_remote_rounded),
                  label: Text('Remote'),
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
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF6554C0)),
                  label: 'Comissões',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded, color: Color(0xFF6554C0)),
                  label: 'Pedidos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded, color: Color(0xFF6554C0)),
                  label: 'Produtos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.store_mall_directory_outlined),
                  selectedIcon: Icon(Icons.store_mall_directory_rounded, color: Color(0xFF6554C0)),
                  label: 'Lojas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.view_carousel_outlined),
                  selectedIcon: Icon(Icons.view_carousel_rounded, color: Color(0xFF6554C0)),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_remote_outlined),
                  selectedIcon: Icon(Icons.settings_remote_rounded, color: Color(0xFF6554C0)),
                  label: 'Remote',
                ),
              ],
            ),
    );
  }
}
