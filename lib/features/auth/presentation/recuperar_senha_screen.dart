import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import 'theme/app_cores.dart';
import 'widgets/animated_field.dart';
import 'widgets/auth_shell.dart';
import 'widgets/fade_slide.dart';
import 'widgets/morph_button.dart';
import 'widgets/shake.dart';

class RecuperarSenhaScreen extends ConsumerStatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  ConsumerState<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends ConsumerState<RecuperarSenhaScreen>
    with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  final _email = TextEditingController();
  final _shake = GlobalKey<ShakeState>();
  var _estado = ButtonState.idle;
  var _enviado = false;
  var _segundos = 0;
  Timer? _timer;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _emailOk => emailValido(_email.text);

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _estado = ButtonState.loading;
      _erro = null;
    });

    try {
      final emailClean = _email.text.trim();
      // Chama o provedor real BoraGás (Supabase e/ou WhatsApp Hub)
      final result = await ref
          .read(authProvider.notifier)
          .sendPasswordResetOtp(emailClean);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() => _estado = ButtonState.success);
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        setState(() => _enviado = true);
        _contar();
      } else {
        setState(() {
          _estado = ButtonState.idle;
          _erro = result['message']?.toString() ?? 'Erro ao enviar redefinição.';
        });
        _shake.currentState?.shake();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _estado = ButtonState.idle;
        _erro = 'Erro: $e';
      });
      _shake.currentState?.shake();
    }
  }

  void _contar() {
    _timer?.cancel();
    setState(() => _segundos = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _segundos--);
      if (_segundos <= 0) t.cancel();
    });
  }

  Future<void> _reenviar() async {
    final emailClean = _email.text.trim();
    await ref.read(authProvider.notifier).sendPasswordResetOtp(emailClean);
    _contar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link reenviado! Confira sua caixa de entrada e spam.'),
        backgroundColor: AppCores.roxo,
      ),
    );
  }

  Widget _formulario() => Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlide(
            controller: _intro,
            start: 0.3,
            child: AnimatedField(
              label: 'E-mail',
              icon: Icons.mail_outline_rounded,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) {
                if (_emailOk && _estado == ButtonState.idle) _enviar();
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _erro == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: AppCores.vermelho,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _erro!,
                              style: const TextStyle(
                                color: AppCores.vermelho,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          FadeSlide(
            controller: _intro,
            start: 0.4,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _emailOk || _estado != ButtonState.idle ? 1 : 0.45,
                child: IgnorePointer(
                  ignoring: !_emailOk,
                  child: MorphButton(
                    label: 'Enviar link',
                    state: _estado,
                    onTap: _enviar,
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _confirmacao() => Column(
        key: const ValueKey('ok'),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, v, child) =>
                Transform.scale(scale: v, child: child),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppCores.roxo.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 44,
                color: AppCores.roxo,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Enviamos um link para\n${_email.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppCores.texto,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Não chegou? Confira a caixa de spam.',
            style: TextStyle(color: AppCores.cinza, fontSize: 13),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: _segundos <= 0 ? _reenviar : null,
            child: Text(
              _segundos <= 0 ? 'Reenviar link' : 'Reenviar em ${_segundos}s',
              style: TextStyle(
                color: _segundos <= 0 ? AppCores.roxo : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              'Voltar para o login',
              style: TextStyle(
                color: AppCores.roxo,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      intro: _intro,
      mostrarVoltar: true,
      onVoltar: () => context.go('/login'),
      icone: _enviado ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
      titulo: _enviado ? 'Verifique seu e-mail' : 'Esqueceu a senha?',
      subtitulo: _enviado
          ? 'O link vale por 30 minutos'
          : 'Sem problemas! Enviaremos um link para redefinir',
      card: Shake(
        key: _shake,
        child: AuthCard(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _enviado ? _confirmacao() : _formulario(),
            ),
          ),
        ),
      ),
    );
  }
}
