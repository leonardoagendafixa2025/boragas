import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../providers/marketing_providers.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  void _copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 Código de indicação "$code" copiado!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareViaWhatsApp(String code) async {
    HapticFeedback.lightImpact();
    final message =
        '🔥 Vizinho(a), comprei gás de cozinha pelo BoraGás e chegou super rápido! '
        'Baixe o app e use meu código $code para ganhar R\$ 10,00 de desconto no seu primeiro pedido: '
        'https://boragas.app/indique/$code';

    // Copia preventivamente para a área de transferência
    await Clipboard.setData(ClipboardData(text: message));

    final encodedMessage = Uri.encodeComponent(message);
    final nativeUri = Uri.parse('whatsapp://send?text=$encodedMessage');
    final webUri = Uri.parse('https://api.whatsapp.com/send?text=$encodedMessage');
    final waMeUri = Uri.parse('https://wa.me/?text=$encodedMessage');

    bool opened = false;

    // 1. Tenta abrir via esquema nativo do app WhatsApp (Android / iOS)
    try {
      if (await canLaunchUrl(nativeUri)) {
        opened = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // 2. Se não abriu, tenta via api.whatsapp.com (abre app ou web)
    if (!opened) {
      try {
        if (await canLaunchUrl(webUri)) {
          opened = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    // 3. Fallback via wa.me
    if (!opened) {
      try {
        opened = await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    // 4. Último fallback padrão
    if (!opened) {
      try {
        opened = await launchUrl(waMeUri);
      } catch (_) {}
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                opened
                    ? 'Abrindo WhatsApp com mensagem pronta...'
                    : 'Texto copiado! Abra o WhatsApp e cole na conversa.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF25D366),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(referralWalletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Indique & Ganhe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card with Wallet Balance
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D28D9).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'PROGRAMA GANHA-GANHA',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${wallet.friendsInvited} Amigos Indicados',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Seu Saldo em Créditos BoraGás',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'R\$ ${wallet.creditBalance.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Abate no Checkout',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Indique vizinhos e amigos. Eles ganham R\$ 10 no primeiro botijão e você recebe R\$ 10 em créditos quando eles receberem o pedido.',
                    style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Referral Code Box
            const Text(
              'Seu Código Exclusivo de Indicação',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        wallet.userReferralCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _copyReferralCode(wallet.userReferralCode),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Big WhatsApp Share Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _shareViaWhatsApp(wallet.userReferralCode),
                icon: const Icon(Icons.share_rounded, size: 20),
                label: const Text(
                  'Compartilhar no WhatsApp',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // How it works card
            const Text(
              'Como Funciona a Indicação?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _buildStepRow(
              '1',
              'Compartilhe seu link ou código',
              'Envie no WhatsApp para vizinhos do prédio, amigos da rua ou familiares.',
            ),
            const SizedBox(height: 10),
            _buildStepRow(
              '2',
              'Seu vizinho ganha R\$ 10 OFF',
              'Ele aplica o código no carrinho do 1º botijão ou galão de água mineral.',
            ),
            const SizedBox(height: 10),
            _buildStepRow(
              '3',
              'Você recebe R\$ 10 de crédito',
              'Assim que a entrega dele for concluída pelo motoboy, seu saldo é creditado!',
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String stepNumber, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
