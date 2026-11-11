import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import 'theme/app_cores.dart';
import 'widgets/animated_field.dart';
import 'widgets/auth_shell.dart';
import 'widgets/fade_slide.dart';
import 'widgets/morph_button.dart';
import 'widgets/shake.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _shake = GlobalKey<ShakeState>();
  var _oculta = true;
  var _estado = ButtonState.idle;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
    _senha.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _intro.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  bool get _podeEntrar => emailValido(_email.text) && _senha.text.length >= 6;

  void _routeAfterLogin(UserRole role, String name) {
    if (!mounted) return;
    switch (role) {
      case UserRole.merchant:
        context.go('/merchant');
        break;
      case UserRole.admin:
        context.go('/admin');
        break;
      case UserRole.courier:
        context.go('/courier');
        break;
      case UserRole.customer:
        context.go('/bem-vindo', extra: {
          'nome': name,
          'primeiroAcesso': false,
        });
        break;
    }
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _estado = ButtonState.loading;
      _erro = null;
    });

    final email = _email.text.trim();
    final pwd = _senha.text.trim();

    final success = await ref
        .read(authProvider.notifier)
        .loginWithEmailPassword(email, pwd);

    if (!mounted) return;

    if (success) {
      setState(() => _estado = ButtonState.success);
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;

      final user = ref.read(authProvider).user;
      final role = user?.role ?? UserRole.customer;
      final nome = user?.name ?? email.split('@').first;

      _routeAfterLogin(role, nome);
    } else {
      final authError = ref.read(authProvider).errorMessage;
      setState(() {
        _estado = ButtonState.idle;
        _erro = authError ?? 'E-mail ou senha incorretos. Tente de novo.';
      });
      _shake.currentState?.shake();
    }
  }

  void _preencherDemo(String email, String senha) {
    HapticFeedback.selectionClick();
    setState(() {
      _email.text = email;
      _senha.text = senha;
      _erro = null;
    });
    _entrar();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      intro: _intro,
      titulo: 'Entrar',
      subtitulo: 'Peça seu gás de cozinha em poucos toques',
      rodape: RodapeLink(
        texto: 'Ainda não tem conta?',
        link: 'Cadastre-se',
        onTap: () => context.go('/cadastro'),
      ),
      card: Shake(
        key: _shake,
        child: AuthCard(
          child: Column(
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
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                ),
              ),
              const SizedBox(height: 12),
              FadeSlide(
                controller: _intro,
                start: 0.38,
                child: AnimatedField(
                  label: 'Senha',
                  icon: Icons.lock_outline_rounded,
                  controller: _senha,
                  obscure: _oculta,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) {
                    if (_podeEntrar && _estado == ButtonState.idle) _entrar();
                  },
                  suffix: IconButton(
                    tooltip: _oculta ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: () => setState(() => _oculta = !_oculta),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          RotationTransition(turns: anim, child: child),
                      child: Icon(
                        _oculta ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: const Color(0xFF64748B),
                        key: ValueKey(_oculta),
                      ),
                    ),
                  ),
                ),
              ),
              FadeSlide(
                controller: _intro,
                start: 0.44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/recuperar'),
                    child: const Text(
                      'Esqueci minha senha',
                      style: TextStyle(
                        color: AppCores.roxo,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _erro == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
              const SizedBox(height: 4),
              FadeSlide(
                controller: _intro,
                start: 0.5,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _podeEntrar || _estado != ButtonState.idle ? 1 : 0.45,
                    child: IgnorePointer(
                      ignoring: !_podeEntrar,
                      child: MorphButton(
                        label: 'Entrar',
                        state: _estado,
                        onTap: _entrar,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Chips de Acesso Rápido para Demonstração e QA
              FadeSlide(
                controller: _intro,
                start: 0.56,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: AppCores.laranja),
                          SizedBox(width: 4),
                          Text(
                            'Acesso Rápido (Demonstração / Testes):',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildQuickChip(
                            label: 'Lojista',
                            icon: Icons.storefront_rounded,
                            color: const Color(0xFFEA580C),
                            onTap: () => _preencherDemo('lojista@boragas.app', '123456'),
                          ),
                          _buildQuickChip(
                            label: 'Admin',
                            icon: Icons.shield_rounded,
                            color: const Color(0xFF7C3AED),
                            onTap: () => _preencherDemo('admin@boragas.app', '123456'),
                          ),
                          _buildQuickChip(
                            label: 'Entregador',
                            icon: Icons.two_wheeler_rounded,
                            color: const Color(0xFF059669),
                            onTap: () => _preencherDemo('entregador@boragas.app', '123456'),
                          ),
                          _buildQuickChip(
                            label: 'Cliente',
                            icon: Icons.shopping_cart_outlined,
                            color: const Color(0xFF2563EB),
                            onTap: () => _preencherDemo('cliente@boragas.app', '123456'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
