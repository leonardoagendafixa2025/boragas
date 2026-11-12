import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/apk_download_service.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // 1. Card de Destaque: Baixar o APK Oficial Android
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge superior
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.android_rounded,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'APK OFICIAL ANDROID',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'v1.0.0 • 66 MB',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Título e Descrição
                  const Text(
                    'Instale o App BoraGás no seu Celular',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Receba notificações em tempo real até com o celular bloqueado quando o motoboy sair para entrega e peça botijão ou água com apenas 1 clique.',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Badges de Confiança
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildPill(Icons.verified_user_rounded, '100% Seguro'),
                      _buildPill(Icons.bolt_rounded, 'Entrega Rápida'),
                      _buildPill(Icons.notifications_active_rounded, 'Push Nativo'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Botão de Download do APK
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => ApkDownloadService.downloadApk(context),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text(
                        'Baixar APK Oficial para Android',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Links Rápidos & Institucional
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Divider(color: Color(0xFF1E293B), height: 1),
                const SizedBox(height: 16),

                // Logo e Descrição da Marca
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppColors.flameGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'BoraGás',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'O marketplace mais rápido de botijão de gás e água mineral da sua região.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Ações Rápidas de Navegação
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _buildFooterLink(
                      context,
                      'Suporte & Ajuda',
                      () => context.push('/support'),
                    ),
                    _buildFooterLink(
                      context,
                      'Indique & Ganhe',
                      () => context.push('/referral'),
                    ),
                    _buildFooterLink(
                      context,
                      'Clube BoraGás',
                      () => context.push('/subscription-club'),
                    ),
                    _buildFooterLink(
                      context,
                      'Meus Pedidos',
                      () => context.push('/orders'),
                    ),
                    _buildFooterLink(
                      context,
                      'Baixar APK',
                      () => ApkDownloadService.downloadApk(context),
                      isHighlight: true,
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(color: Color(0xFF1E293B), height: 1),
                const SizedBox(height: 14),

                // Copyright & Direitos Reservados
                const Text(
                  '© 2026 BoraGás Marketplace • Todos os direitos reservados.\nCNPJ 52.891.432/0001-90',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Espaço inferior de rolagem para não cobrir o bottomNavigationBar
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  static Widget _buildPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildFooterLink(
    BuildContext context,
    String label,
    VoidCallback onTap, {
    bool isHighlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: isHighlight ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
            fontSize: 11.5,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            decoration: isHighlight ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }
}
