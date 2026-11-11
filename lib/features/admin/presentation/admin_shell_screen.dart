import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_home_manager_screen.dart';
import 'admin_remote_config_screen.dart';
import 'admin_stores_screen.dart';
import 'admin_whatsapp_screen.dart';

class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    AdminStoresScreen(),
    AdminHomeManagerScreen(),
    AdminRemoteConfigScreen(),
    AdminWhatsAppScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 750;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6554C0),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6554C0).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'SUPER ADMIN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 10),
              const Text('BoraGás Master Control', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
              side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() => _currentIndex = 4);
            },
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 15),
            label: const Text('WhatsApp QR', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Desligar / Sair do Super Admin',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.power_settings_new_rounded, size: 18, color: Color(0xFFEF4444)),
            onPressed: () async {
              final router = GoRouter.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  title: const Text('Desligar / Sair do Super Admin', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Deseja realmente encerrar a sessão administrativa?',
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
              selectedIndex: _currentIndex,
              backgroundColor: const Color(0xFF0F172A),
              selectedIconTheme: const IconThemeData(color: Color(0xFF8B5CF6)),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
              selectedLabelTextStyle: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.w800),
              unselectedLabelTextStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.insights_rounded),
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: Text('Comissões'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront_rounded),
                  label: Text('Lojas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_customize_outlined),
                  selectedIcon: Icon(Icons.dashboard_customize_rounded),
                  label: Text('Vitrine'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_rounded),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: Text('Ajustes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
                  label: Text('WhatsApp'),
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
                  height: 66,
                  backgroundColor: const Color(0xFF0F172A),
                  indicatorColor: const Color(0xFF6554C0).withValues(alpha: 0.28),
                  indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      );
                    }
                    return const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const IconThemeData(color: Color(0xFF8B5CF6), size: 23);
                    }
                    return const IconThemeData(color: Color(0xFF94A3B8), size: 21);
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.insights_rounded),
                      selectedIcon: Icon(Icons.insights_rounded),
                      label: 'Comissões',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.storefront_outlined),
                      selectedIcon: Icon(Icons.storefront_rounded),
                      label: 'Lojas',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_customize_outlined),
                      selectedIcon: Icon(Icons.dashboard_customize_rounded),
                      label: 'Vitrine',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.tune_rounded),
                      selectedIcon: Icon(Icons.tune_rounded),
                      label: 'Ajustes',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.chat_bubble_outline_rounded),
                      selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
                      label: 'WhatsApp',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
