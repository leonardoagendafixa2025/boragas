import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/remote_config_service.dart';
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
                builder: (ctx) => IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (onMenuPressed != null) {
                      onMenuPressed!();
                    } else {
                      Scaffold.of(ctx).openDrawer();
                    }
                  },
                  tooltip: 'Menu e Portais',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.primary,
                    size: 22,
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6C5CE7)],
                      ),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Cliente BoraGás',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          user != null
                              ? '${user.email} (${user.role.name.toUpperCase()})'
                              : 'Conecte-se para gerenciar pedidos e lojas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'NAVEGAÇÃO DIRETA ENTRE PORTAIS (DEMO & TESTES)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFFEA580C), size: 22),
                ),
                title: const Text('Portal da Distribuidora (Lojista)', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Acessar painel com e-mail e senha (/merchant)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (user?.role == UserRole.merchant || user?.role == UserRole.admin) {
                    context.go('/merchant');
                  } else {
                    // Para acessar como Lojista, desloga a sessão atual para exibir a tela de login
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF7C3AED), size: 22),
                ),
                title: const Text('Super Admin Master Control', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Acessar painel com e-mail e senha (/admin)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (user?.role == UserRole.admin) {
                    context.go('/admin');
                  } else {
                    // Para acessar como Admin, desloga a sessão atual para exibir a tela de login
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF059669), size: 22),
                ),
                title: const Text('App do Entregador', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Acessar painel com e-mail e senha (/courier)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (user?.role == UserRole.courier || user?.role == UserRole.admin) {
                    context.go('/courier');
                  } else {
                    // Para acessar como Entregador, desloga a sessão atual para exibir a tela de login
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.login_rounded, color: Color(0xFF6C5CE7), size: 22),
                ),
                title: const Text('Tela de Login Cósmico & Cadastro', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Sair da sessão e abrir tela de autenticação (/login)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
