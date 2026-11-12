import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Etapa do fluxo: 1 = Pedir WhatsApp/Email, 2 = Digitar Código & Nova Senha, 3 = Sucesso
  int _etapa = 1;

  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _shake = GlobalKey<ShakeState>();
  var _estado = ButtonState.idle;
  var _segundos = 0;
  Timer? _timer;
  String? _erro;
  String? _maskedPhone;
  bool _mostrarNovaSenha = false;
  bool _mostrarConfirmSenha = false;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(() => setState(() {}));
    _codeController.addListener(() => setState(() {}));
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    _identifierController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _identifierValido {
    final text = _identifierController.text.trim();
    if (text.isEmpty) return false;
    if (emailValido(text)) return true;
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  bool get _etapa2Valida {
    return _codeController.text.trim().length >= 4 &&
        _newPasswordController.text.trim().length >= 6 &&
        _confirmPasswordController.text.trim() == _newPasswordController.text.trim();
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

  /// ETAPA 1: Dispara o código de validação para o WhatsApp
  Future<void> _solicitarCodigoWhatsApp() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _estado = ButtonState.loading;
      _erro = null;
    });

    try {
      final input = _identifierController.text.trim();
      final result = await ref.read(authProvider.notifier).sendPasswordResetOtp(input);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _estado = ButtonState.success;
          _maskedPhone = result['maskedPhone'] as String? ?? 'WhatsApp cadastrado';
        });

        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;

        setState(() {
          _etapa = 2;
          _estado = ButtonState.idle;
        });
        _contar();
      } else {
        setState(() {
          _estado = ButtonState.idle;
          _erro = result['message']?.toString() ?? 'Não foi possível enviar o código.';
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

  /// ETAPA 2: Valida o código OTP e altera a senha
  Future<void> _confirmarNovaSenha() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _estado = ButtonState.loading;
      _erro = null;
    });

    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      setState(() {
        _estado = ButtonState.idle;
        _erro = 'A confirmação de senha não confere com a nova senha.';
      });
      _shake.currentState?.shake();
      return;
    }

    try {
      final res = await ref.read(authProvider.notifier).confirmPasswordReset(
            code: code,
            newPassword: newPassword,
          );

      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _estado = ButtonState.success;
        });
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;

        setState(() {
          _etapa = 3;
          _estado = ButtonState.idle;
        });
      } else {
        setState(() {
          _estado = ButtonState.idle;
          _erro = res['message']?.toString() ?? 'Código inválido ou expirado.';
        });
        _shake.currentState?.shake();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _estado = ButtonState.idle;
        _erro = 'Falha ao redefinir senha: $e';
      });
      _shake.currentState?.shake();
    }
  }

  /// Reenviar código para o WhatsApp
  Future<void> _reenviarCodigo() async {
    final input = _identifierController.text.trim();
    await ref.read(authProvider.notifier).sendPasswordResetOtp(input);
    _contar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código reenviado para o seu WhatsApp!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  /// Abre o WhatsApp para suporte caso necessário
  Future<void> _abrirWhatsAppSuporte() async {
    final phone = '5531973149306';
    final msg = Uri.encodeComponent(
      'Olá BoraGás! Preciso de ajuda para redefinir minha senha de acesso.',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _buildErro() {
    if (_erro == null) return const SizedBox.shrink();
    return Padding(
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
    );
  }

  // ===========================================================================
  // ETAPA 1: Formulário de Solicitação WhatsApp
  // ===========================================================================
  Widget _buildEtapa1() => Column(
        key: const ValueKey('etapa1'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Seu código de redefinição será enviado diretamente no seu WhatsApp.',
                    style: TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FadeSlide(
            controller: _intro,
            start: 0.3,
            child: AnimatedField(
              label: 'E-mail ou WhatsApp',
              icon: Icons.contact_mail_outlined,
              controller: _identifierController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_identifierValido && _estado == ButtonState.idle) {
                  _solicitarCodigoWhatsApp();
                }
              },
            ),
          ),
          _buildErro(),
          const SizedBox(height: 20),
          FadeSlide(
            controller: _intro,
            start: 0.4,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _identifierValido || _estado != ButtonState.idle ? 1 : 0.45,
                child: IgnorePointer(
                  ignoring: !_identifierValido,
                  child: MorphButton(
                    label: 'Enviar código no WhatsApp',
                    state: _estado,
                    onTap: _solicitarCodigoWhatsApp,
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  // ===========================================================================
  // ETAPA 2: Inserir Código OTP & Nova Senha
  // ===========================================================================
  Widget _buildEtapa2() => Column(
        key: const ValueKey('etapa2'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.mark_chat_read_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Código enviado no WhatsApp!',
                        style: TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Destino: ${_maskedPhone ?? ""}. Digite o código de 6 dígitos abaixo.',
                        style: const TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Campo Código de 6 Dígitos
          AnimatedField(
            label: 'Código de 6 dígitos do WhatsApp',
            icon: Icons.pin_outlined,
            controller: _codeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          // Campo Nova Senha
          AnimatedField(
            label: 'Nova Senha (mínimo 6 caracteres)',
            icon: Icons.lock_outline_rounded,
            controller: _newPasswordController,
            obscure: !_mostrarNovaSenha,
            textInputAction: TextInputAction.next,
            suffix: IconButton(
              icon: Icon(
                _mostrarNovaSenha
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: () => setState(() => _mostrarNovaSenha = !_mostrarNovaSenha),
            ),
          ),
          const SizedBox(height: 12),

          // Campo Confirmar Senha
          AnimatedField(
            label: 'Confirmar Nova Senha',
            icon: Icons.lock_reset_rounded,
            controller: _confirmPasswordController,
            obscure: !_mostrarConfirmSenha,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (_etapa2Valida && _estado == ButtonState.idle) {
                _confirmarNovaSenha();
              }
            },
            suffix: IconButton(
              icon: Icon(
                _mostrarConfirmSenha
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _mostrarConfirmSenha = !_mostrarConfirmSenha),
            ),
          ),

          _buildErro(),
          const SizedBox(height: 20),

          // Botão Confirmar Redefinição
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _etapa2Valida || _estado != ButtonState.idle ? 1 : 0.45,
              child: IgnorePointer(
                ignoring: !_etapa2Valida,
                child: MorphButton(
                  label: 'Redefinir Minha Senha',
                  state: _estado,
                  onTap: _confirmarNovaSenha,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Ações de reenvio
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _segundos <= 0 ? _reenviarCodigo : null,
                child: Text(
                  _segundos <= 0 ? 'Reenviar código' : 'Reenviar em ${_segundos}s',
                  style: TextStyle(
                    color: _segundos <= 0 ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
              TextButton(
                onPressed: () => setState(() {
                  _etapa = 1;
                  _erro = null;
                }),
                child: const Text(
                  'Trocar número',
                  style: TextStyle(
                    color: AppCores.roxo,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: _abrirWhatsAppSuporte,
              icon: const Icon(Icons.support_agent_rounded, size: 16, color: Color(0xFF10B981)),
              label: const Text(
                'Precisa de ajuda? Falar no WhatsApp',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );

  // ===========================================================================
  // ETAPA 3: Confirmação de Sucesso
  // ===========================================================================
  Widget _buildEtapa3() => Column(
        key: const ValueKey('etapa3'),
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
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Senha Alterada com Sucesso! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppCores.texto,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sua nova senha já está valendo. Acesse sua conta agora mesmo com as novas credenciais.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppCores.cinza, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppCores.roxo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login_rounded, size: 20),
              label: const Text(
                'Fazer Login Agora',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    IconData iconeHeader;
    String tituloHeader;
    String subtituloHeader;

    if (_etapa == 1) {
      iconeHeader = Icons.lock_reset_rounded;
      tituloHeader = 'Esqueceu a senha?';
      subtituloHeader = 'Receba seu código de validação no WhatsApp para redefinir';
    } else if (_etapa == 2) {
      iconeHeader = Icons.sms_outlined;
      tituloHeader = 'Validar Código WhatsApp';
      subtituloHeader = 'Digite o código recebido e crie sua nova senha';
    } else {
      iconeHeader = Icons.check_circle_outline_rounded;
      tituloHeader = 'Tudo Pronto!';
      subtituloHeader = 'Sua senha foi redefinida com segurança';
    }

    return AuthShell(
      intro: _intro,
      mostrarVoltar: true,
      onVoltar: () {
        if (_etapa == 2) {
          setState(() => _etapa = 1);
        } else {
          context.go('/login');
        }
      },
      icone: iconeHeader,
      titulo: tituloHeader,
      subtitulo: subtituloHeader,
      card: Shake(
        key: _shake,
        child: AuthCard(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _etapa == 1
                  ? _buildEtapa1()
                  : (_etapa == 2 ? _buildEtapa2() : _buildEtapa3()),
            ),
          ),
        ),
      ),
    );
  }
}
