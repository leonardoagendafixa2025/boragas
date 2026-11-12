import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/apk_download_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final cart = ref.watch(cartProvider);
    final auth = ref.watch(authProvider);

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
                  Text(
                    auth.user?.name ?? 'Cliente BoraGás',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    auth.user?.phone.isNotEmpty == true
                        ? auth.user!.phone
                        : (auth.user?.email.isNotEmpty == true ? auth.user!.email : 'BoraGás Marketplace'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'PORTAIS & ACESSO RÁPIDO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFFEA580C), size: 20),
              ),
              title: const Text('Portal da Distribuidora (Lojista)'),
              subtitle: const Text('Acessar com e-mail e senha (/merchant)'),
              onTap: () async {
                Navigator.pop(context);
                if (auth.user?.role == UserRole.merchant || auth.user?.role == UserRole.admin) {
                  context.go('/merchant');
                } else {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF7C3AED), size: 20),
              ),
              title: const Text('Super Admin Master'),
              subtitle: const Text('Acessar com e-mail e senha (/admin)'),
              onTap: () async {
                Navigator.pop(context);
                if (auth.user?.role == UserRole.admin) {
                  context.go('/admin');
                } else {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF059669), size: 20),
              ),
              title: const Text('App do Entregador'),
              subtitle: const Text('Acessar com e-mail e senha (/courier)'),
              onTap: () async {
                Navigator.pop(context);
                if (auth.user?.role == UserRole.courier || auth.user?.role == UserRole.admin) {
                  context.go('/courier');
                } else {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.login_rounded, color: Color(0xFF6C5CE7), size: 20),
              ),
              title: const Text('Entrar / Login Cósmico'),
              subtitle: const Text('Acessar tela de autenticação (/login)'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.android_rounded, color: Color(0xFF10B981), size: 20),
              ),
              title: const Text('Baixar App Android (APK)', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Instalar aplicativo nativo no celular'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'OFICIAL',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                ApkDownloadService.downloadApk(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Sair da Conta', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
              onTap: () async {
                final router = GoRouter.of(context);
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sair da Conta'),
                    content: const Text('Deseja realmente sair da sua conta BoraGás?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sair', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: widget.child),
          const FloatingOrderTracker(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 66,
            indicatorColor: AppColors.primary.withValues(alpha: 0.14),
            indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800);
              }
              return const TextStyle(color: Color(0xFF64748B), fontSize: 10.5, fontWeight: FontWeight.w600);
            }),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            backgroundColor: Colors.white,
            elevation: 8,
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
        ),
      ),
    );
  }
}
