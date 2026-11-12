import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/widgets/change_password_dialog.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/customer_providers.dart';
import '../address_selection_sheet.dart';
import 'gas_consumption_calculator.dart';

class HomeHeader extends ConsumerWidget {
  final VoidCallback? onMenuPressed;
  const HomeHeader({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAddress = ref.watch(currentAddressProvider);
    final remoteConfig = ref.watch(remoteConfigProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Address Selector and Fast Actions
          Row(
            children: [
              // Botão do Menu Lateral (Drawer)
              Builder(
                builder: (ctx) => Tooltip(
                  message: 'Menu e Portais',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (onMenuPressed != null) {
                          onMenuPressed!();
                        } else {
                          Scaffold.of(ctx).openDrawer();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 20,
                                height: 2.4,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 3.5),
                              Container(
                                width: 20,
                                height: 2.4,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 3.5),
                              Container(
                                width: 20,
                                height: 2.4,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Address Selector
              Expanded(
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) => const AddressSelectionSheet(),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    currentAddress.label,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                              Text(
                                '${currentAddress.street}, ${currentAddress.number}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Gas Calculator Button
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => GasConsumptionCalculatorSheet(
                      onOrderNow: () {
                        ref.read(homeViewModeProvider.notifier).set(HomeViewMode.items);
                      },
                    ),
                  );
                },
                tooltip: 'Calculadora de Gás',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accentFlame.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.accentFlame,
                  size: 20,
                ),
              ),

              const SizedBox(width: 8),

              // Botão de Login / Trocar Perfil
              IconButton(
                onPressed: () => _showProfileSheet(context, ref),
                tooltip: 'Perfil & Portais',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: Color(0xFF6C5CE7),
                  size: 22,
                ),
              ),
            ],
          ),

          // Announcement Banner from Remote Config (Controlled by Admin)
          if (remoteConfig.showAnnouncementBanner &&
              remoteConfig.announcementBannerText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    remoteConfig.seasonalAccentColor.withValues(alpha: 0.15),
                    AppColors.accentFlame.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: remoteConfig.seasonalAccentColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.campaign_rounded,
                    size: 18,
                    color: AppColors.accentFlame,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remoteConfig.announcementBannerText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);
    final user = auth.user;
    final isAuthenticated = auth.isAuthenticated && user != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cabeçalho do Perfil do Cliente
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6C5CE7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isAuthenticated && user.name.isNotEmpty
                            ? user.name.substring(0, 1).toUpperCase()
                            : 'B',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isAuthenticated ? user.name : 'Cliente BoraGás',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CLIENTE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.success,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAuthenticated
                              ? user.email
                              : 'Conecte-se para acompanhar pedidos e promoções',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isAuthenticated && user.phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.phone,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 4),

              // Opções Reais do Perfil do Cliente
              _buildProfileOption(
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.primary,
                title: 'Meus Pedidos',
                subtitle: 'Histórico e acompanhamento em tempo real',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/orders');
                },
              ),
              _buildProfileOption(
                icon: Icons.loyalty_rounded,
                iconColor: AppColors.accentFlame,
                title: 'Clube BoraGás',
                subtitle: 'Assinatura com 5% OFF garantido',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/subscription-club');
                },
              ),
              _buildProfileOption(
                icon: Icons.stars_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Cartão Fidelidade',
                subtitle: 'Acumule selos e ganhe R\$ 25 OFF',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/loyalty');
                },
              ),
              _buildProfileOption(
                icon: Icons.card_giftcard_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Indique & Ganhe R\$ 10',
                subtitle: 'Indique vizinhos e ganhe créditos',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/referral');
                },
              ),
              _buildProfileOption(
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFF059669),
                title: 'Endereço de Entrega',
                subtitle: 'Gerenciar locais e CEPs cadastrados',
                onTap: () {
                  Navigator.pop(ctx);
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
              _buildProfileOption(
                icon: Icons.headset_mic_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'Suporte & Ajuda',
                subtitle: 'Dúvidas e atendimento direto via WhatsApp',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/support');
                },
              ),
              if (isAuthenticated)
                _buildProfileOption(
                  icon: Icons.lock_reset_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Alterar Senha',
                  subtitle: 'Atualizar senha de acesso da sua conta',
                  onTap: () {
                    Navigator.pop(ctx);
                    ChangePasswordDialog.show(context);
                  },
                ),

              const SizedBox(height: 10),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // Botão de Logout ou Entrar
              if (isAuthenticated)
                InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    final router = GoRouter.of(context);
                    final nav = Navigator.of(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        title: const Text('Sair da Conta', style: TextStyle(fontWeight: FontWeight.w800)),
                        content: const Text('Deseja realmente desconectar sua conta deste dispositivo?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx, false),
                            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(dCtx, true),
                            child: const Text('Sair da Conta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      nav.pop();
                      await ref.read(authProvider.notifier).logout();
                      router.go('/login');
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Sair da Conta',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/login');
                  },
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Entrar ou Criar Conta', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      ),
    );
  }
}
