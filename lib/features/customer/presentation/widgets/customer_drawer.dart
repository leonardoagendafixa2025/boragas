import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/apk_download_service.dart';
import '../../../../core/widgets/change_password_dialog.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../address_selection_sheet.dart';

class CustomerDrawer extends ConsumerWidget {
  const CustomerDrawer({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final router = GoRouter.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sair da Conta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Deseja realmente desconectar sua conta deste dispositivo?',
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
              'Sair da Conta',
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
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isAuthenticated = auth.isAuthenticated && user != null;
    final cart = ref.watch(cartProvider);

    final drawerWidth = math.min(MediaQuery.of(context).size.width * 0.85, 330.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            // Header do Menu Lateral com visual premium
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
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isAuthenticated ? AppColors.success : const Color(0xFF64748B))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (isAuthenticated ? AppColors.success : const Color(0xFF64748B))
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 3,
                              backgroundColor: isAuthenticated ? AppColors.success : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isAuthenticated ? 'CLIENTE CONECTADO' : 'MODO VISITANTE',
                              style: TextStyle(
                                color: isAuthenticated ? const Color(0xFF34D399) : const Color(0xFFCBD5E1),
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

                  if (isAuthenticated) ...[
                    Text(
                      user.name.isNotEmpty ? user.name : 'Cliente BoraGás',
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
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (user.phone.isNotEmpty)
                      Text(
                        user.phone,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                  ] else ...[
                    const Text(
                      'Bem-vindo ao BoraGás!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Entre na sua conta para pedir gás e água com entrega rápida.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/login');
                      },
                      icon: const Icon(Icons.login_rounded, size: 16),
                      label: const Text('Entrar ou Criar Conta', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),

            // Itens de Navegação do Cliente
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 6, 10, 6),
                    child: Text(
                      'MEU APLICATIVO',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // Início
                  _buildMenuItem(
                    icon: Icons.storefront_rounded,
                    title: 'Início & Distribuidoras',
                    subtitle: 'Botijões P13, P45, Água 20L e mais',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/home');
                    },
                  ),

                  // Meus Pedidos
                  _buildMenuItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Meus Pedidos',
                    subtitle: 'Acompanhamento em tempo real',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/orders');
                    },
                  ),

                  // Cartão Fidelidade
                  _buildMenuItem(
                    icon: Icons.stars_rounded,
                    title: 'Cartão Fidelidade',
                    subtitle: 'Junte 5 selos e ganhe R\$ 25 OFF',
                    accentColor: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/loyalty');
                    },
                  ),

                  // Clube BoraGás
                  _buildMenuItem(
                    icon: Icons.loyalty_rounded,
                    title: 'Clube BoraGás (Recorrência)',
                    subtitle: 'Abastecimento automático com 5% OFF',
                    accentColor: AppColors.accentFlame,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/subscription-club');
                    },
                  ),

                  // Indique & Ganhe
                  _buildMenuItem(
                    icon: Icons.card_giftcard_rounded,
                    title: 'Indique & Ganhe R\$ 10',
                    subtitle: 'Convide vizinhos pelo WhatsApp',
                    accentColor: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/referral');
                    },
                  ),

                  // Minha Sacola
                  _buildMenuItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Minha Sacola',
                    subtitle: cart.isEmpty
                        ? 'Sacola vazia'
                        : '${cart.totalItemCount} item(s) • R\$ ${cart.total.toStringAsFixed(2).replaceAll('.', ',')}',
                    badgeText: cart.isEmpty ? null : '${cart.totalItemCount}',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/cart');
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFF1E293B), height: 1),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 4, 10, 6),
                    child: Text(
                      'PREFERÊNCIAS & AJUDA',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // Trocar Endereço
                  _buildMenuItem(
                    icon: Icons.location_on_rounded,
                    title: 'Endereço de Entrega',
                    subtitle: 'Alterar CEP ou local de entrega',
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) => const AddressSelectionSheet(),
                      );
                    },
                  ),

                  // Suporte
                  _buildMenuItem(
                    icon: Icons.headset_mic_rounded,
                    title: 'Suporte & Ajuda',
                    subtitle: 'Fale conosco ou tire dúvidas',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/support');
                    },
                  ),

                  // Baixar Aplicativo Android (APK)
                  _buildMenuItem(
                    icon: Icons.android_rounded,
                    title: 'Baixar App Android (APK)',
                    subtitle: 'Instale o app oficial no celular',
                    accentColor: const Color(0xFF10B981),
                    badgeText: 'OFICIAL',
                    onTap: () {
                      Navigator.pop(context);
                      ApkDownloadService.downloadApk(context);
                    },
                  ),

                  // Alterar Senha (Disponível quando autenticado)
                  if (isAuthenticated)
                    _buildMenuItem(
                      icon: Icons.lock_reset_rounded,
                      title: 'Alterar Senha',
                      subtitle: 'Atualizar senha de acesso',
                      accentColor: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(context);
                        ChangePasswordDialog.show(context);
                      },
                    ),

                  // Portais Administrativos / Lojista / Entregador (RBAC)
                  if (isAuthenticated &&
                      (user.role == UserRole.merchant ||
                          user.role == UserRole.admin ||
                          user.role == UserRole.courier)) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFF1E293B), height: 1),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 4, 10, 6),
                      child: Text(
                        'PORTAIS CORPORATIVOS',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    if (user.role == UserRole.merchant || user.role == UserRole.admin)
                      _buildMenuItem(
                        icon: Icons.storefront_rounded,
                        title: 'Portal do Lojista',
                        subtitle: 'Painel de pedidos e estoque',
                        accentColor: AppColors.accentFlame,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/merchant');
                        },
                      ),
                    if (user.role == UserRole.courier || user.role == UserRole.admin)
                      _buildMenuItem(
                        icon: Icons.two_wheeler_rounded,
                        title: 'Cockpit do Entregador',
                        subtitle: 'Rotas ativas e GPS',
                        accentColor: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/courier');
                        },
                      ),
                    if (user.role == UserRole.admin)
                      _buildMenuItem(
                        icon: Icons.shield_rounded,
                        title: 'Super Admin',
                        subtitle: 'Painel master BoraGás',
                        accentColor: const Color(0xFF8B5CF6),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/admin');
                        },
                      ),
                  ],
                ],
              ),
            ),

            // Rodapé do Menu com Logout / Versão
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
                color: Color(0xFF0B0F19),
              ),
              child: Column(
                children: [
                  if (isAuthenticated) ...[
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
                        _confirmLogout(context, ref);
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Desconectar Conta',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Botão rápido de baixar o APK no rodapé do drawer
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      ApkDownloadService.downloadApk(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_rounded, color: Color(0xFF10B981), size: 16),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Baixar APK Android (v1.0.0)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Text(
                    'BoraGás • Versão 1.0.0 Oficial',
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? accentColor,
    String? badgeText,
  }) {
    final color = accentColor ?? const Color(0xFF38BDF8);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
          ),
        ),
        trailing: badgeText != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF475569)),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }
}
