import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import 'theme/app_cores.dart';
import 'widgets/animated_field.dart';
import 'widgets/auth_shell.dart';
import 'widgets/avatar_picker.dart';
import 'widgets/confetti.dart';
import 'widgets/drawn_checkbox.dart';
import 'widgets/fade_slide.dart';
import 'widgets/morph_button.dart';
import 'widgets/password_rules.dart';
import 'widgets/rule_check.dart';
import 'widgets/shake.dart';
import 'widgets/strength_meter.dart';
import 'widgets/telefone_formatter.dart';

class CadastroScreen extends ConsumerStatefulWidget {
  const CadastroScreen({super.key});

  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen>
    with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _storeName = TextEditingController();
  final _storeCnpj = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _vehiclePlate = TextEditingController();

  final _confettiKey = GlobalKey<ConfettiState>();
  final _shake = GlobalKey<ShakeState>();

  var _avatar = 0;
  var _oculta = true;
  var _aceitou = false;
  var _estado = ButtonState.idle;
  var _selectedRole = UserRole.customer;
  String? _erro;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nome,
      _telefone,
      _email,
      _senha,
      _storeName,
      _storeCnpj,
      _vehicleModel,
      _vehiclePlate,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    for (final c in [
      _nome,
      _telefone,
      _email,
      _senha,
      _storeName,
      _storeCnpj,
      _vehicleModel,
      _vehiclePlate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _podeCadastrar {
    final basicOk = _nome.text.trim().length >= 3 &&
        _telefone.text.replaceAll(RegExp(r'\D'), '').length >= 10 &&
        emailValido(_email.text) &&
        PasswordRules(_senha.text).passed >= 2 &&
        _aceitou;

    if (!basicOk) return false;

    if (_selectedRole == UserRole.merchant) {
      if (_storeName.text.trim().length < 2) return false;
    }

    return true;
  }

  Future<void> _cadastrar() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _estado = ButtonState.loading;
      _erro = null;
    });

    try {
      final success = await ref.read(authProvider.notifier).registerUser(
            name: _nome.text.trim(),
            phone: _telefone.text.trim(),
            email: _email.text.trim(),
            password: _senha.text.trim(),
            role: _selectedRole,
            storeName: _selectedRole == UserRole.merchant
                ? _storeName.text.trim()
                : null,
            storeCnpj: _selectedRole == UserRole.merchant
                ? _storeCnpj.text.trim()
                : null,
            vehicleModel: _selectedRole == UserRole.courier
                ? _vehicleModel.text.trim()
                : null,
            vehiclePlate: _selectedRole == UserRole.courier
                ? _vehiclePlate.text.trim()
                : null,
          );

      if (!mounted) return;

      if (success) {
        setState(() => _estado = ButtonState.success);
        _confettiKey.currentState?.burst();
        await Future.delayed(const Duration(milliseconds: 1400));
        if (!mounted) return;

        final firstName = _nome.text.trim().split(' ').first;
        switch (_selectedRole) {
          case UserRole.merchant:
            context.go('/merchant');
            break;
          case UserRole.courier:
            context.go('/courier');
            break;
          case UserRole.admin:
            context.go('/admin');
            break;
          case UserRole.customer:
            context.go(
              '/bem-vindo',
              extra: {
                'nome': firstName,
                'primeiroAcesso': true,
              },
            );
            break;
        }
      } else {
        final authError = ref.read(authProvider).errorMessage;
        setState(() {
          _estado = ButtonState.idle;
          _erro = authError ?? 'Não foi possível concluir o cadastro.';
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

  Widget _buildRoleChip({
    required UserRole role,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedRole = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppCores.roxo.withValues(alpha: 0.12)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppCores.roxo : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppCores.roxo : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppCores.roxo : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final concluido = _estado == ButtonState.success;
    final regras = PasswordRules(_senha.text);

    return AuthShell(
      intro: _intro,
      confettiKey: _confettiKey,
      mostrarVoltar: true,
      onVoltar: () => context.go('/login'),
      icone: Icons.person_add_alt_1_rounded,
      titulo: concluido ? 'Conta criada!' : 'Criar conta',
      subtitulo: concluido
          ? 'Tudo pronto para pedir seu gás'
          : 'Leva menos de um minuto',
      rodape: RodapeLink(
        texto: 'Já tem conta?',
        link: 'Entrar',
        onTap: () => context.go('/login'),
      ),
      card: Shake(
        key: _shake,
        child: AuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlide(
                controller: _intro,
                start: 0.25,
                child: AvatarPicker(
                  selected: _avatar,
                  onSelect: (i) => setState(() => _avatar = i),
                ),
              ),
              const SizedBox(height: 16),

              // Seletor de Tipo de Conta
              FadeSlide(
                controller: _intro,
                start: 0.28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Perfil',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildRoleChip(
                          role: UserRole.customer,
                          label: 'Cliente',
                          icon: Icons.person_outline_rounded,
                        ),
                        _buildRoleChip(
                          role: UserRole.merchant,
                          label: 'Distribuidora',
                          icon: Icons.storefront_rounded,
                        ),
                        _buildRoleChip(
                          role: UserRole.courier,
                          label: 'Entregador',
                          icon: Icons.two_wheeler_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              FadeSlide(
                controller: _intro,
                start: 0.32,
                child: AnimatedField(
                  label: 'Nome completo',
                  icon: Icons.person_outline_rounded,
                  controller: _nome,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
              ),
              const SizedBox(height: 12),

              FadeSlide(
                controller: _intro,
                start: 0.36,
                child: AnimatedField(
                  label: 'WhatsApp / Telefone',
                  icon: Icons.phone_outlined,
                  controller: _telefone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [TelefoneFormatter()],
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
              ),
              const SizedBox(height: 12),

              FadeSlide(
                controller: _intro,
                start: 0.40,
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

              // Campos Específicos se Distribuidora
              if (_selectedRole == UserRole.merchant) ...[
                FadeSlide(
                  controller: _intro,
                  start: 0.42,
                  child: AnimatedField(
                    label: 'Nome da Distribuidora',
                    icon: Icons.storefront_rounded,
                    controller: _storeName,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlide(
                  controller: _intro,
                  start: 0.44,
                  child: AnimatedField(
                    label: 'CNPJ (opcional)',
                    icon: Icons.badge_outlined,
                    controller: _storeCnpj,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Campos Específicos se Entregador
              if (_selectedRole == UserRole.courier) ...[
                FadeSlide(
                  controller: _intro,
                  start: 0.42,
                  child: AnimatedField(
                    label: 'Modelo da Moto / Veículo',
                    icon: Icons.two_wheeler_rounded,
                    controller: _vehicleModel,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlide(
                  controller: _intro,
                  start: 0.44,
                  child: AnimatedField(
                    label: 'Placa do Veículo',
                    icon: Icons.pin_outlined,
                    controller: _vehiclePlate,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              FadeSlide(
                controller: _intro,
                start: 0.46,
                child: AnimatedField(
                  label: 'Senha',
                  icon: Icons.lock_outline_rounded,
                  controller: _senha,
                  obscure: _oculta,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  suffix: IconButton(
                    tooltip: _oculta ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: () => setState(() => _oculta = !_oculta),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          RotationTransition(turns: anim, child: child),
                      child: Icon(
                        _oculta
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: const Color(0xFF64748B),
                        key: ValueKey(_oculta),
                      ),
                    ),
                  ),
                ),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: _senha.text.isEmpty
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          children: [
                            StrengthMeter(score: regras.passed),
                            const SizedBox(height: 8),
                            RuleCheck(
                              text: '8 ou mais caracteres',
                              ok: regras.longEnough,
                            ),
                            RuleCheck(text: 'Um número', ok: regras.hasNumber),
                            RuleCheck(
                              text: 'Uma letra maiúscula',
                              ok: regras.hasUpper,
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 14),

              FadeSlide(
                controller: _intro,
                start: 0.52,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DrawnCheckbox(
                      value: _aceitou,
                      onTap: () => setState(() => _aceitou = !_aceitou),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Aceito os Termos de Uso e a Política de Privacidade',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppCores.texto,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Feedback de Erro
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
              const SizedBox(height: 18),

              FadeSlide(
                controller: _intro,
                start: 0.58,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity:
                        _podeCadastrar || _estado != ButtonState.idle ? 1 : 0.45,
                    child: IgnorePointer(
                      ignoring: !_podeCadastrar,
                      child: MorphButton(
                        label: 'Criar conta',
                        state: _estado,
                        onTap: _cadastrar,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
