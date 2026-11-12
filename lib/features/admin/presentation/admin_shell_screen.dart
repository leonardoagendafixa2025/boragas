import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../core/widgets/change_password_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../support/providers/support_providers.dart';
import 'admin_dashboard_screen.dart';
import 'admin_home_manager_screen.dart';
import 'admin_push_marketing_screen.dart';
import 'admin_remote_config_screen.dart';
import 'admin_stores_screen.dart';
import 'admin_support_screen.dart';
import 'admin_whatsapp_screen.dart';

class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  bool _isDesktopSidebarVisible = true;

  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    AdminStoresScreen(),
    AdminHomeManagerScreen(),
    AdminRemoteConfigScreen(),
    AdminWhatsAppScreen(),
    AdminSupportScreen(),
    AdminPushMarketingScreen(),
  ];

  static const List<({String title, String subtitle, IconData icon})> _menuItems = [
    (
      title: 'Comissões & GMV',
      subtitle: 'Monitoramento financeiro e repasses',
      icon: Icons.query_stats_rounded,
    ),
    (
      title: 'Gestão de Lojas',
      subtitle: 'Distribuidoras parceiras e status',
      icon: Icons.storefront_rounded,
    ),
    (
      title: 'Banners & Vitrine',
      subtitle: 'Carrossel e destaques da home',
      icon: Icons.view_carousel_rounded,
    ),
    (
      title: 'Ajustes da Plataforma',
      subtitle: 'Taxas, regras e configurações',
      icon: Icons.tune_rounded,
    ),
    (
      title: 'WhatsApp & Baileys',
      subtitle: 'Conexão QR e disparo de mensagens',
      icon: Icons.chat_rounded,
    ),
    (
      title: 'Helpdesk & Suporte',
      subtitle: 'Chamados reais e atendimento direto',
      icon: Icons.headset_mic_rounded,
    ),
    (
      title: 'Marketing & Push',
      subtitle: 'Disparo de notificações nativas e PWA',
      icon: Icons.campaign_rounded,
    ),
  ];

  Future<void> _confirmLogout(BuildContext context) async {
    HapticFeedback.lightImpact();
    final router = GoRouter.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Desligar / Sair do Super Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
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
            child: const Text(
              'Desligar e Sair',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      router.go('/login');
    }
  }

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

    final isWide = MediaQuery.of(context).size.width > 900;
    final currentItem = _menuItems[_currentIndex];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B0F19),
      // Menu Lateral Recolhível (Drawer em Modo Hambúrguer)
      drawer: _buildCollapsibleDrawer(context, auth),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Menu Lateral',
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (isWide) {
              setState(() => _isDesktopSidebarVisible = !_isDesktopSidebarVisible);
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6554C0), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6554C0).withValues(alpha: 0.35),
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
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                currentItem.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Atalho rápido Helpdesk & Chamados
          IconButton(
            tooltip: 'Helpdesk & Chamados de Suporte',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.headset_mic_rounded, size: 18, color: Color(0xFF8B5CF6)),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = 5);
            },
          ),
          const SizedBox(width: 6),

          // Atalho rápido WhatsApp QR
          IconButton(
            tooltip: 'WhatsApp QR & Instância',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: Color(0xFF25D366)),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = 4);
            },
          ),
          const SizedBox(width: 6),

          // Alterar Senha Master
          IconButton(
            tooltip: 'Alterar Senha Master',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.lock_reset_rounded, size: 18, color: Color(0xFFF59E0B)),
            onPressed: () => ChangePasswordDialog.show(context),
          ),
          const SizedBox(width: 6),

          // Botão Desligar / Sair com confirmação
          IconButton(
            tooltip: 'Desligar / Sair do Super Admin',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.power_settings_new_rounded, size: 18, color: Color(0xFFEF4444)),
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          if (isWide && _isDesktopSidebarVisible)
            _buildDesktopSidebar(context, auth),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
    );
  }

  /// Menu Lateral Recolhível Tático (Drawer)
  Widget _buildCollapsibleDrawer(BuildContext context, AuthState auth) {
    final drawerWidth = math.min(MediaQuery.of(context).size.width * 0.85, 330.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            // Header do Menu Lateral com visual executivo
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B00), Color(0xFFFF8800)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B00).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                            SizedBox(width: 5),
                            Text(
                              'MASTER ATIVO',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar Menu',
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'BoraGás Master Control',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    auth.user?.name ?? 'Super Administrador',
                    style: const TextStyle(
                      color: Color(0xFFA78BFA),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    auth.user?.email ?? 'admin@boragas.app',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Itens de Navegação Principais
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 6, 10, 8),
                    child: Text(
                      'NAVEGAÇÃO PRINCIPAL',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  for (int i = 0; i < _menuItems.length; i++)
                    _buildDrawerItem(
                      index: i,
                      item: _menuItems[i],
                      isSelected: _currentIndex == i,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                        setState(() => _currentIndex = i);
                      },
                    ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFF1E293B), height: 1),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: Text(
                      'PORTAIS & ACESSOS RÁPIDOS',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // Atalho App do Cliente (Home)
                  _buildQuickAccessTile(
                    icon: Icons.shopping_bag_outlined,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'App do Cliente (Vitrine)',
                    subtitle: 'Ver aplicativo como consumidor',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      context.go('/home');
                    },
                  ),

                  // Atalho Portal Lojista (Merchant)
                  _buildQuickAccessTile(
                    icon: Icons.storefront_rounded,
                    iconColor: AppColors.accentFlame,
                    title: 'Portal do Lojista',
                    subtitle: 'Kanban, pedidos e estoque',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      context.push('/merchant');
                    },
                  ),

                  // Atalho Cockpit Entregador (Courier)
                  _buildQuickAccessTile(
                    icon: Icons.two_wheeler_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Cockpit do Entregador',
                    subtitle: 'GPS real e rotas ativas',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      context.push('/courier');
                    },
                  ),
                ],
              ),
            ),

            // Rodapé do Menu com Botão de Desligar / Logout
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
                color: Color(0xFF0B0F19),
              ),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFF334155)),
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ChangePasswordDialog.show(context);
                    },
                    icon: const Icon(Icons.lock_reset_rounded, size: 18, color: Color(0xFFF59E0B)),
                    label: const Text(
                      'Alterar Senha Master',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmLogout(context);
                    },
                    icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                    label: const Text(
                      'Encerrar Sessão Master',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'BoraGás Cloud Master • v2.4.0',
                    style: TextStyle(color: Color(0xFF475569), fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra Lateral Persistente no Desktop (Expansível / Recolhível)
  Widget _buildDesktopSidebar(BuildContext context, AuthState auth) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        children: [
          for (int i = 0; i < _menuItems.length; i++)
            _buildDrawerItem(
              index: i,
              item: _menuItems[i],
              isSelected: _currentIndex == i,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentIndex = i);
              },
            ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 12),
          _buildQuickAccessTile(
            icon: Icons.shopping_bag_outlined,
            iconColor: const Color(0xFF38BDF8),
            title: 'App do Cliente',
            subtitle: 'Vitrine de compras',
            onTap: () => context.go('/home'),
          ),
          _buildQuickAccessTile(
            icon: Icons.storefront_rounded,
            iconColor: AppColors.accentFlame,
            title: 'Portal Lojista',
            subtitle: 'Kanban e catálogo',
            onTap: () => context.push('/merchant'),
          ),
          _buildQuickAccessTile(
            icon: Icons.two_wheeler_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Cockpit Entregador',
            subtitle: 'Rotas e telemetria',
            onTap: () => context.push('/courier'),
          ),
          _buildQuickAccessTile(
            icon: Icons.lock_reset_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Alterar Senha Master',
            subtitle: 'Segurança da conta',
            onTap: () => ChangePasswordDialog.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required int index,
    required ({String title, String subtitle, IconData icon}) item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6554C0).withValues(alpha: 0.22) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF8B5CF6).withValues(alpha: 0.45) : Colors.transparent,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            item.icon,
            size: 18,
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          item.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? const Color(0xFFC4B5FD) : const Color(0xFF64748B),
            fontSize: 10.5,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index == 5) ...[
              Consumer(
                builder: (context, ref, _) {
                  final openCount = ref
                      .watch(supportTicketsProvider)
                      .where((t) => t.status == TicketStatus.open)
                      .length;
                  if (openCount == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$openCount',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
            ],
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildQuickAccessTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w700, fontSize: 12.5),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF475569)),
        onTap: onTap,
      ),
    );
  }
}
