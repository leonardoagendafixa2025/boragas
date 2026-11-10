import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/floating_order_tracker.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class CustomerShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const CustomerShellScreen({super.key, required this.child});

  @override
  ConsumerState<CustomerShellScreen> createState() =>
      _CustomerShellScreenState();
}

class _CustomerShellScreenState extends ConsumerState<CustomerShellScreen> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/support')) return 2;
    if (location.startsWith('/cart')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/orders');
        break;
      case 2:
        context.go('/support');
        break;
      case 3:
        context.go('/cart');
        break;
    }
  }

  void _showRoleSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Trocar Módulo do Ecossistema',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'O BoraGás possui 4 visões integradas no mesmo app:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ListTile(
              tileColor: AppColors.primary.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: const Icon(Icons.person_rounded, color: AppColors.primary),
              title: const Text('Cliente Final (Consumidor)', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Comprar gás/água, comparar preços e rastrear entrega'),
              trailing: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).switchDemoRole(UserRole.customer);
                context.go('/home');
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              leading: const Icon(Icons.store_rounded, color: AppColors.accentFlame),
              title: const Text('Painel da Distribuidora (Lojista)', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Kanban de pedidos, catálogo, BYOK API & Maquininha'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).switchDemoRole(UserRole.merchant);
                context.go('/merchant');
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              leading: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF0D9488)),
              title: const Text('App do Entregador (Motoboy)', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Rotas ativas, GPS Waze/Maps e validação de PIN de 4 dígitos'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).switchDemoRole(UserRole.courier);
                context.go('/courier');
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6554C0)),
              title: const Text('Painel Super Admin', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Controle de comissões sem mensalidade, gestão de banners e home'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).switchDemoRole(UserRole.admin);
                context.go('/admin');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'BoraGás Marketplace',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'Troca de Perfil & Navegação',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: AppColors.primary),
              title: const Text('App do Cliente (Início)'),
              selected: selectedIndex == 0,
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              title: const Text('Meus Pedidos'),
              selected: selectedIndex == 1,
              onTap: () {
                Navigator.pop(context);
                context.go('/orders');
              },
            ),
            ListTile(
              leading: const Icon(Icons.loyalty_rounded, color: AppColors.accentFlame),
              title: const Text('Clube BoraGás (Recorrência)'),
              subtitle: const Text('5% OFF em todo abastecimento'),
              onTap: () {
                Navigator.pop(context);
                context.push('/subscription-club');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_rounded, color: Color(0xFF9333EA)),
              title: const Text('Indique & Ganhe'),
              subtitle: const Text('Ganhe R\$ 10 por vizinho indicado'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('R\$ 20 saldo', style: TextStyle(color: Color(0xFF9333EA), fontSize: 10, fontWeight: FontWeight.w800)),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/referral');
              },
            ),
            ListTile(
              leading: const Icon(Icons.stars_rounded, color: Color(0xFFD97706)),
              title: const Text('Cartão Fidelidade'),
              subtitle: const Text('3 de 5 selos coletados'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('3/5', style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w900)),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/loyalty');
              },
            ),
            ListTile(
              leading: const Icon(Icons.headset_mic_rounded, color: AppColors.primary),
              title: const Text('Central de Ajuda'),
              selected: selectedIndex == 2,
              onTap: () {
                Navigator.pop(context);
                context.go('/support');
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'MÓDULOS OPERACIONAIS & GESTÃO',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF0D9488)),
              title: const Text('App do Entregador'),
              subtitle: const Text('Rotas ativas e PIN de entrega'),
              onTap: () {
                Navigator.pop(context);
                context.push('/courier');
              },
            ),
            ListTile(
              leading: const Icon(Icons.store_rounded, color: AppColors.accentFlame),
              title: const Text('Painel da Distribuidora'),
              subtitle: const Text('Kanban & Gateway BYOK'),
              onTap: () {
                Navigator.pop(context);
                context.go('/merchant');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6554C0)),
              title: const Text('Painel Super Admin'),
              subtitle: const Text('Comissões 8% & Home Manager'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: widget.child),
          const FloatingOrderTracker(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        tooltip: 'Trocar de Painel',
        elevation: 3,
        onPressed: () => _showRoleSwitcher(context),
        child: const Icon(Icons.swap_horiz_rounded),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Início',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            label: 'Pedidos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent_rounded, color: AppColors.primary),
            label: 'Ajuda',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: !cart.isEmpty,
              label: Text('${cart.totalItemCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: !cart.isEmpty,
              label: Text('${cart.totalItemCount}'),
              child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primary),
            ),
            label: 'Sacola',
          ),
        ],
      ),
    );
  }
}
