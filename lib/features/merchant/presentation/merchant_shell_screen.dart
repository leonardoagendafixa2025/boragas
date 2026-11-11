import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/store_model.dart';
import '../../../core/services/audio_alert_service.dart';
import '../../../core/widgets/status_badge.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  bool _isDesktopSidebarVisible = true;

  final List<Widget> _pages = const [
    MerchantKanbanScreen(),
    MerchantCatalogScreen(),
    MerchantPaymentConfigScreen(),
    MerchantFinancesScreen(),
  ];

  static const List<({String title, String subtitle, IconData icon})> _menuItems = [
    (
      title: 'Kanban de Pedidos',
      subtitle: 'Fluxo em tempo real: Aceite, Preparo e Despacho',
      icon: Icons.dashboard_rounded,
    ),
    (
      title: 'Produtos & Estoque',
      subtitle: 'Gestão de botijões GLP, água mineral e preços',
      icon: Icons.inventory_2_rounded,
    ),
    (
      title: 'Maquininha & Pagamentos',
      subtitle: 'Configurações de Pix, Cartão e POS na entrega',
      icon: Icons.payments_rounded,
    ),
    (
      title: 'Extrato & Finanças',
      subtitle: 'Vendas brutas, comissões e repasses líquidos',
      icon: Icons.account_balance_wallet_rounded,
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
          'Desligar / Sair do Portal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Deseja realmente encerrar a sessão da sua distribuidora e sair da conta?',
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

    // Bloqueio de segurança em camadas: Se não for lojista ou admin autenticado, redireciona para login
    if (GoRouter.maybeOf(context) != null &&
        (!auth.isAuthenticated ||
            (auth.user?.role != UserRole.merchant && auth.user?.role != UserRole.admin))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return const Scaffold(
        backgroundColor: AppColors.merchantCanvas,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentFlame),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 900;
    final currentStore = ref.watch(currentMerchantStoreProvider);
    final allStores = ref.watch(storesProvider);
    final allOrders = ref.watch(ordersProvider);

    // Contagem de pedidos novos para badge
    final pendingOrdersCount = allOrders
        .where((o) =>
            o.storeId == currentStore.id &&
            (o.status == OrderStatus.pending || o.status == OrderStatus.accepted))
        .length;

    final currentItem = _menuItems[_currentIndex];

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.merchantCanvas,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accentFlame,
          surface: AppColors.merchantCard,
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.merchantCanvas,
        // Menu Lateral Recolhível Tático (Drawer)
        drawer: _buildCollapsibleDrawer(
          context,
          auth,
          currentStore,
          allStores,
          pendingOrdersCount,
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            tooltip: 'Menu Lateral Hambúrguer',
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
              // Badge Portal do Lojista
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.flameGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentFlame.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'LOJISTA',
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
              const SizedBox(width: 8),

              // Título da Aba Atual ou Nome da Loja
              Expanded(
                child: Text(
                  isWide ? '${currentStore.name} • ${currentItem.title}' : currentItem.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Interruptor da Loja (Ligar / Desligar Loja para Pedidos)
            InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                final newStatus = ref.read(currentMerchantStoreProvider.notifier).toggleOpen();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newStatus
                        ? '🟢 Loja Ligada: Recebendo novos pedidos normalmente!'
                        : '🔴 Loja Desligada (Pausada): Clientes verão que está fechado.'),
                    backgroundColor: newStatus ? AppColors.success : AppColors.error,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: StatusBadge.storeOpen(isOpen: currentStore.isOpen),
            ),
            const SizedBox(width: 4),

            // Alerta Sonoro de Novo Pedido
            IconButton(
              tooltip: 'Alerta Sonoro de Pedido',
              icon: const Icon(Icons.notifications_active_rounded,
                  color: AppColors.accentFlame, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
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

            // Ir para o App do Cliente (Home)
            IconButton(
              tooltip: 'Ver Vitrine do Consumidor (Home)',
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white70, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.go('/home');
              },
            ),

            // Desligar / Sair da Sessão
            IconButton(
              tooltip: 'Desligar / Sair da Loja',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.power_settings_new_rounded, color: Color(0xFFEF4444), size: 18),
              onPressed: () => _confirmLogout(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(
          children: [
            if (isWide && _isDesktopSidebarVisible)
              _buildDesktopSidebar(
                context,
                auth,
                currentStore,
                allStores,
                pendingOrdersCount,
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
                    backgroundColor: const Color(0xFF0F172A),
                    indicatorColor: AppColors.accentFlame.withValues(alpha: 0.18),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const TextStyle(
                            color: AppColors.accentFlame, fontSize: 11, fontWeight: FontWeight.w800);
                      }
                      return const TextStyle(
                          color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500);
                    }),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const IconThemeData(color: AppColors.accentFlame, size: 22);
                      }
                      return const IconThemeData(color: Color(0xFF64748B), size: 22);
                    }),
                  ),
                  child: NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (idx) {
                      HapticFeedback.selectionClick();
                      setState(() => _currentIndex = idx);
                    },
                    destinations: [
                      NavigationDestination(
                        icon: Badge(
                          isLabelVisible: pendingOrdersCount > 0,
                          label: Text('$pendingOrdersCount'),
                          backgroundColor: AppColors.accentFlame,
                          child: const Icon(Icons.dashboard_outlined),
                        ),
                        selectedIcon: Badge(
                          isLabelVisible: pendingOrdersCount > 0,
                          label: Text('$pendingOrdersCount'),
                          backgroundColor: AppColors.accentFlame,
                          child: const Icon(Icons.dashboard_rounded),
                        ),
                        label: 'Pedidos',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.inventory_2_outlined),
                        selectedIcon: Icon(Icons.inventory_2_rounded),
                        label: 'Produtos',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.payments_outlined),
                        selectedIcon: Icon(Icons.payments_rounded),
                        label: 'Pagamentos',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.account_balance_wallet_outlined),
                        selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                        label: 'Finanças',
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// Menu Lateral Recolhível Tático (Drawer) para Lojista
  Widget _buildCollapsibleDrawer(
    BuildContext context,
    AuthState auth,
    StoreModel currentStore,
    List<StoreModel> allStores,
    int pendingOrdersCount,
  ) {
    final drawerWidth = math.min(MediaQuery.of(context).size.width * 0.85, 330.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            // Header do Menu Lateral do Lojista
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
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
                          gradient: AppColors.flameGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentFlame.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (currentStore.isOpen ? AppColors.success : AppColors.error)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (currentStore.isOpen ? AppColors.success : AppColors.error)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 3,
                              backgroundColor: currentStore.isOpen ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              currentStore.isOpen ? 'LOJA ABERTA' : 'LOJA FECHADA',
                              style: TextStyle(
                                color: currentStore.isOpen ? const Color(0xFF34D399) : const Color(0xFFF87171),
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
                  Text(
                    currentStore.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'CNPJ: ${currentStore.cnpj}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    currentStore.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),

                  // Seletor de Loja (se houver mais de uma)
                  if (allStores.length > 1) ...[
                    const SizedBox(height: 10),
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: allStores.any((s) => s.id == currentStore.id)
                              ? currentStore.id
                              : allStores.first.id,
                          dropdownColor: const Color(0xFF1E293B),
                          isExpanded: true,
                          icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 16),
                          items: allStores.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                s.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null) {
                              HapticFeedback.selectionClick();
                              final found = allStores.firstWhere((s) => s.id == newId);
                              ref.read(currentMerchantStoreProvider.notifier).set(found);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
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
                      'GESTÃO DA DISTRIBUIDORA',
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
                      badgeCount: i == 0 ? pendingOrdersCount : 0,
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
                      'FERRAMENTAS & ATALHOS',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // Alerta Sonoro de Teste
                  _buildQuickAccessTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: AppColors.accentFlame,
                    title: 'Testar Som de Pedido',
                    subtitle: 'Toque para verificar campainha',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      AudioAlertService.playNewOrderAlert();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔔 Campainha de pedido reproduzida!'),
                          backgroundColor: Color(0xFF1E293B),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                  // Atalho App do Cliente (Home)
                  _buildQuickAccessTile(
                    icon: Icons.shopping_bag_outlined,
                    iconColor: const Color(0xFF38BDF8),
                    title: 'Ver Vitrine do Cliente',
                    subtitle: 'Visualizar como o cliente vê seu gás',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      context.go('/home');
                    },
                  ),

                  // Atalho Super Admin (se for admin)
                  if (auth.user?.role == UserRole.admin)
                    _buildQuickAccessTile(
                      icon: Icons.shield_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Painel Super Admin',
                      subtitle: 'Comissões globais e configurações',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        context.push('/admin');
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.accentFlame.withValues(alpha: 0.2),
                        child: const Icon(Icons.person_rounded, color: AppColors.accentFlame, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.name ?? 'Lojista',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              auth.user?.email ?? 'lojista@boragas.app',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmLogout(context);
                    },
                    icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                    label: const Text(
                      'Desligar / Sair da Loja',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Item de Navegação Principal do Drawer
  Widget _buildDrawerItem({
    required int index,
    required ({String title, String subtitle, IconData icon}) item,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accentFlame.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.accentFlame.withValues(alpha: 0.45)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentFlame
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
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
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          item.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected
                ? AppColors.accentFlame.withValues(alpha: 0.9)
                : const Color(0xFF64748B),
            fontSize: 10.5,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentFlame,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  /// Atalho de Acesso Rápido no Drawer
  Widget _buildQuickAccessTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF475569)),
        onTap: onTap,
      ),
    );
  }

  /// Sidebar Fixa e Recolhível para Desktop
  Widget _buildDesktopSidebar(
    BuildContext context,
    AuthState auth,
    StoreModel currentStore,
    List<StoreModel> allStores,
    int pendingOrdersCount,
  ) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        children: [
          // Header Desktop
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.flameGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentStore.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'CNPJ: ${currentStore.cnpj}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // Menu de Navegação Desktop
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                for (int i = 0; i < _menuItems.length; i++)
                  _buildDrawerItem(
                    index: i,
                    item: _menuItems[i],
                    badgeCount: i == 0 ? pendingOrdersCount : 0,
                    isSelected: _currentIndex == i,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _currentIndex = i);
                    },
                  ),
              ],
            ),
          ),

          // Rodapé Desktop
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                minimumSize: const Size.fromHeight(36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.power_settings_new_rounded, size: 16),
              label: const Text('Desligar Sessão', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
