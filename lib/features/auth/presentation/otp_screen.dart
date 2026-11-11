import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) return;

    final success = await ref.read(authProvider.notifier).verifyOtp(widget.phone, code);
    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmação'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF16A34A), size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Código enviado no seu WhatsApp',
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'Digite o código de 6 dígitos enviado para seu WhatsApp no número ${widget.phone}:',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '123456',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onChanged: (val) {
                if (val.length == 6) _verify();
              },
            ),

            if (auth.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                auth.errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],

            const SizedBox(height: 24),

            AppButton(
              label: 'Verificar e Entrar',
              isLoading: auth.isLoading,
              isFlameAccent: true,
              onPressed: _verify,
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _codeController.text = '123456';
                _verify();
              },
              child: const Text('Preencher código de teste (123456)'),
            ),
          ],
        ),
      ),
    );
  }
}
