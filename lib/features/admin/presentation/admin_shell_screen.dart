import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
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
    final auth = ref.watch(authProvider);

    // Bloqueio de segurança em camadas: Se não for admin autenticado, redireciona para login
    if (GoRouter.maybeOf(context) != null && (!auth.isAuthenticated || auth.user?.role != UserRole.admin)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 750;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 14,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6554C0), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6554C0).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'SUPER ADMIN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 12),
              const Text('BoraGás Master Control', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ],
        ),
        actions: [
          // Atalho App do Cliente (Home)
          IconButton(
            tooltip: 'Ir para o App do Cliente (Home)',
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white70, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go('/home');
            },
          ),
          const SizedBox(width: 4),

          // Atalho Portal Lojista (Admin pode inspecionar o Kanban/Produtos)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentFlame,
              side: const BorderSide(color: AppColors.accentFlame, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/merchant');
            },
            icon: const Icon(Icons.storefront_rounded, size: 14),
            label: const Text('Lojista', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 6),

          // Atalho WhatsApp QR
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
              side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = 4);
            },
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 15),
            label: const Text('WhatsApp QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 6),

          // Botão Desligar / Sair
          IconButton(
            tooltip: 'Desligar / Sair do Super Admin',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.power_settings_new_rounded, size: 18, color: Color(0xFFEF4444)),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final router = GoRouter.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF111827),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Desligar / Sair do Super Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  content: const Text(
                    'Deseja realmente encerrar a sessão administrativa master?',
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
              selectedIndex: _currentIndex,
              backgroundColor: const Color(0xFF0F172A),
              selectedIconTheme: const IconThemeData(color: Color(0xFF8B5CF6)),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
              selectedLabelTextStyle: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.w800),
              unselectedLabelTextStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              onDestinationSelected: (idx) {
                HapticFeedback.selectionClick();
                setState(() => _currentIndex = idx);
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.query_stats_rounded),
                  selectedIcon: Icon(Icons.query_stats_rounded),
                  label: Text('Comissões'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.storefront_rounded),
                  selectedIcon: Icon(Icons.storefront_rounded),
                  label: Text('Lojas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.view_carousel_rounded),
                  selectedIcon: Icon(Icons.view_carousel_rounded),
                  label: Text('Vitrine'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_rounded),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: Text('Ajustes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat_rounded),
                  selectedIcon: Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
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
                color: Color(0xFF0F172A),
                border: Border(top: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  height: 64,
                  backgroundColor: const Color(0xFF0F172A),
                  indicatorColor: const Color(0xFF6554C0).withValues(alpha: 0.25),
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
                      return const IconThemeData(color: Color(0xFF8B5CF6), size: 22);
                    }
                    return const IconThemeData(color: Color(0xFF94A3B8), size: 21);
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) {
                    HapticFeedback.selectionClick();
                    setState(() => _currentIndex = idx);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.query_stats_rounded),
                      selectedIcon: Icon(Icons.query_stats_rounded),
                      label: 'Comissões',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.storefront_rounded),
                      selectedIcon: Icon(Icons.storefront_rounded),
                      label: 'Lojas',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.view_carousel_rounded),
                      selectedIcon: Icon(Icons.view_carousel_rounded),
                      label: 'Vitrine',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.tune_rounded),
                      selectedIcon: Icon(Icons.tune_rounded),
                      label: 'Ajustes',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.chat_rounded),
                      selectedIcon: Icon(Icons.chat_rounded),
                      label: 'WhatsApp',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
