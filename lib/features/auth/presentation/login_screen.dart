import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/boragas_logo.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers - Login
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Controllers - Login por WhatsApp Oficial
  final _loginPhoneController = TextEditingController();
  bool _isPhoneLoginMode = false;

  // Controllers - Cadastro
  UserRole _selectedRole = UserRole.customer;
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  bool _obscureRegPassword = true;

  // Campos específicos de Lojista
  final _regStoreNameController = TextEditingController();
  final _regCnpjController = TextEditingController();
  final _regStoreAddressController = TextEditingController();

  // Campos específicos de Entregador
  final _regVehicleModelController = TextEditingController();
  final _regVehiclePlateController = TextEditingController();

  // Campos específicos de Cliente
  final _regDeliveryAddressController = TextEditingController();

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _loginPhoneController.dispose();

    _regNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _regStoreNameController.dispose();
    _regCnpjController.dispose();
    _regStoreAddressController.dispose();
    _regVehicleModelController.dispose();
    _regVehiclePlateController.dispose();
    _regDeliveryAddressController.dispose();
    super.dispose();
  }

  void _routeAfterAuth(UserRole role) {
    if (!mounted) return;
    switch (role) {
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
        context.go('/home');
        break;
    }
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final email = _loginEmailController.text.trim();
    final pwd = _loginPasswordController.text.trim();

    final success = await ref.read(authProvider.notifier).loginWithEmailPassword(email, pwd);

    if (!mounted) return;

    if (success) {
      final user = ref.read(authProvider).user;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bem-vindo(a), ${user?.name ?? 'ao BoraGás'}! ⚡'),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 2),
        ),
      );
      if (user != null) {
        _routeAfterAuth(user.role);
      } else {
        context.go('/home');
      }
    } else {
      final err = ref.read(authProvider).errorMessage ?? 'E-mail ou senha inválidos.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handlePhoneLogin() async {
    final phone = _loginPhoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe um número de celular válido com DDD.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await ref.read(authProvider.notifier).sendPhoneOtp(phone);
    if (mounted) {
      context.push('/otp?phone=${Uri.encodeComponent(phone)}');
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    final pwd = _regPasswordController.text.trim();
    final confirmPwd = _regConfirmPasswordController.text.trim();

    if (pwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas digitadas não coincidem.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).registerUser(
          name: _regNameController.text.trim(),
          email: _regEmailController.text.trim(),
          phone: _regPhoneController.text.trim(),
          password: pwd,
          role: _selectedRole,
          storeName: _selectedRole == UserRole.merchant ? _regStoreNameController.text.trim() : null,
          storeCnpj: _selectedRole == UserRole.merchant ? _regCnpjController.text.trim() : null,
          storeAddress: _selectedRole == UserRole.merchant ? _regStoreAddressController.text.trim() : null,
          vehicleModel: _selectedRole == UserRole.courier ? _regVehicleModelController.text.trim() : null,
          vehiclePlate: _selectedRole == UserRole.courier ? _regVehiclePlateController.text.trim() : null,
          deliveryAddress: _selectedRole == UserRole.customer ? _regDeliveryAddressController.text.trim() : null,
        );

    if (!mounted) return;

    if (success) {
      final user = ref.read(authProvider).user;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conta cadastrada com sucesso! Bem-vindo(a) ${user?.name ?? ''} 🚀'),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 2),
        ),
      );
      if (user != null) {
        _routeAfterAuth(user.role);
      } else {
        context.go('/home');
      }
    } else {
      final err = ref.read(authProvider).errorMessage ?? 'Falha ao registrar conta. Tente novamente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showForgotPasswordModal() {
    final identifierController = TextEditingController(text: _loginEmailController.text.trim());
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isStepTwo = false;
    bool isSending = false;
    String? localError;
    String? localSuccess;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (innerContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(innerContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recuperar Senha',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'Acesso via WhatsApp sem custo de SMS',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (localError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          localError!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (localSuccess != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(
                          localSuccess!,
                          style: const TextStyle(color: Color(0xFF15803D), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!isStepTwo) ...[
                      const Text(
                        'Informe seu e-mail ou número de WhatsApp cadastrado para receber o código seguro de redefinição:',
                        style: TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: identifierController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-mail ou WhatsApp cadastrado',
                          hintText: 'seu@email.com ou (11) 98765-4321',
                          prefixIcon: const Icon(Icons.account_circle_outlined, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSending
                            ? null
                            : () async {
                                final text = identifierController.text.trim();
                                if (text.isEmpty) {
                                  setModalState(() => localError = 'Informe seu e-mail ou WhatsApp.');
                                  return;
                                }
                                setModalState(() {
                                  isSending = true;
                                  localError = null;
                                });

                                final res = await ref.read(authProvider.notifier).sendPasswordResetOtp(text);

                                setModalState(() {
                                  isSending = false;
                                  if (res['success'] == true) {
                                    isStepTwo = true;
                                    localSuccess = 'Código de validação enviado via WhatsApp!';
                                  } else {
                                    localError = res['message'] ?? 'Erro ao enviar código.';
                                  }
                                });
                              },
                        icon: isSending
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.chat_rounded, size: 18),
                        label: Text(
                          isSending ? 'Enviando...' : 'Enviar Código no WhatsApp',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Digite o código recebido no seu WhatsApp e crie a sua nova senha:',
                        style: TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'Código de 6 dígitos',
                          hintText: 'Ex: 123456',
                          prefixIcon: const Icon(Icons.pin_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Nova Senha (mínimo 6 caracteres)',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Nova Senha',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSending
                            ? null
                            : () async {
                                final code = otpController.text.trim();
                                final pwd = newPasswordController.text.trim();
                                final confirm = confirmPasswordController.text.trim();

                                if (code.isEmpty) {
                                  setModalState(() => localError = 'Digite o código recebido.');
                                  return;
                                }
                                if (pwd.length < 6) {
                                  setModalState(() => localError = 'A nova senha deve ter no mínimo 6 caracteres.');
                                  return;
                                }
                                if (pwd != confirm) {
                                  setModalState(() => localError = 'As senhas digitadas não conferem.');
                                  return;
                                }

                                setModalState(() {
                                  isSending = true;
                                  localError = null;
                                });

                                final res = await ref.read(authProvider.notifier).confirmPasswordReset(
                                  code: code,
                                  newPassword: pwd,
                                );

                                setModalState(() => isSending = false);

                                if (res['success'] == true) {
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                  _loginPasswordController.text = pwd;
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ Senha redefinida com sucesso! Você já pode entrar.'),
                                        backgroundColor: Color(0xFF10B981),
                                        duration: Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                } else {
                                  setModalState(() => localError = res['message'] ?? 'Falha ao redefinir.');
                                }
                              },
                        child: Text(
                          isSending ? 'Salvando...' : 'Salvar Nova Senha e Concluir',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setModalState(() {
                          isStepTwo = false;
                          localError = null;
                          localSuccess = null;
                        }),
                        child: const Text('Voltar / reenviar código'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const BoraGasLogo(size: 60, showText: true),
              const SizedBox(height: 16),
              Text(
                'BoraGás Marketplace',
                style: AppTypography.displayMedium.copyWith(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Gás e água mineral em minutos com o melhor preço',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Abas de Acesso Real (Entrar vs Cadastrar)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Entrar na Conta'),
                    Tab(text: 'Criar Nova Conta'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Conteúdo Dinâmico (Entrar vs Cadastrar)
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  if (_tabController.index == 0) {
                    return _buildLoginTab(auth);
                  } else {
                    return _buildRegisterTab(auth);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ABA 1: ENTRAR NA CONTA
  Widget _buildLoginTab(AuthState auth) {
    if (_isPhoneLoginMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.chat_bubble_rounded, color: Color(0xFF16A34A), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Entrar rápido como Cliente com código enviado diretamente no seu WhatsApp.',
                    style: TextStyle(color: Color(0xFF15803D), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Celular / WhatsApp com DDD',
              hintText: '(11) 98765-4321',
              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Enviar Código no WhatsApp',
            isLoading: auth.isLoading,
            isFlameAccent: true,
            icon: Icons.chat_rounded,
            onPressed: _handlePhoneLogin,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _isPhoneLoginMode = false),
            child: const Text('Voltar para login com E-mail e Senha'),
          ),
        ],
      );
    }

    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe seu e-mail de acesso.';
              if (!v.contains('@')) return 'Informe um e-mail válido.';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'E-mail cadastrado',
              hintText: 'seuemail@exemplo.com',
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe sua senha.';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),

          // Esqueci minha senha
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _showForgotPasswordModal,
              icon: const Icon(Icons.lock_reset_rounded, size: 16, color: Color(0xFF64748B)),
              label: const Text(
                'Esqueci minha senha',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Acessar BoraGás',
            isLoading: auth.isLoading,
            isFlameAccent: true,
            icon: Icons.login_rounded,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.chat_rounded, color: Color(0xFF16A34A), size: 18),
            label: const Text(
              'Acessar via WhatsApp Oficial (Cliente)',
              style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700, fontSize: 13),
            ),
            onPressed: () => setState(() => _isPhoneLoginMode = true),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                _tabController.animateTo(1);
              },
              child: const Text(
                'Ainda não tem conta? Cadastre-se aqui',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ABA 2: CRIAR NOVA CONTA (CADASTRO REAL)
  Widget _buildRegisterTab(AuthState auth) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Seletor de Tipo de Perfil
          const Text(
            'Selecione o tipo de conta:',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _buildRoleChip(
                label: 'Cliente',
                icon: Icons.shopping_cart_outlined,
                role: UserRole.customer,
              ),
              const SizedBox(width: 6),
              _buildRoleChip(
                label: 'Distribuidora',
                icon: Icons.storefront_rounded,
                role: UserRole.merchant,
              ),
              const SizedBox(width: 6),
              _buildRoleChip(
                label: 'Entregador',
                icon: Icons.two_wheeler_rounded,
                role: UserRole.courier,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Campos Comuns
          TextFormField(
            controller: _regNameController,
            validator: (v) {
              if (v == null || v.trim().length < 3) return 'Informe seu nome completo (mínimo 3 letras).';
              return null;
            },
            decoration: InputDecoration(
              labelText: _selectedRole == UserRole.merchant ? 'Nome do Responsável / Lojista' : 'Nome Completo',
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty || !v.contains('@')) return 'Informe um e-mail válido.';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'E-mail para login',
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _regPhoneController,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().length < 10) return 'Informe o celular com DDD.';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Celular / WhatsApp (com DDD)',
              hintText: '(11) 98765-4321',
              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // Campos Específicos por Perfil
          if (_selectedRole == UserRole.merchant) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: Color(0xFFEA580C), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dados da Distribuidora (Aparecerá no app para os clientes do seu raio)',
                      style: TextStyle(color: Color(0xFF9A3412), fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _regStoreNameController,
              validator: (v) {
                if (_selectedRole == UserRole.merchant && (v == null || v.trim().isEmpty)) {
                  return 'Informe o nome da distribuidora.';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Nome da Distribuidora',
                hintText: 'Ex: Ultragaz Paulistana Express',
                prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFFEA580C)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regCnpjController,
              validator: (v) {
                if (_selectedRole == UserRole.merchant && (v == null || v.trim().length < 14)) {
                  return 'Informe o CNPJ da empresa.';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'CNPJ',
                hintText: '00.000.000/0001-00',
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFFEA580C)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regStoreAddressController,
              validator: (v) {
                if (_selectedRole == UserRole.merchant && (v == null || v.trim().isEmpty)) {
                  return 'Informe o endereço do depósito.';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Endereço Comercial / Depósito',
                hintText: 'Rua, Número, Bairro, Cidade - SP',
                prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFFEA580C)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (_selectedRole == UserRole.courier) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.two_wheeler_rounded, color: Color(0xFF059669), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dados da Moto / Veículo de Entrega para Identificação do Cliente',
                      style: TextStyle(color: Color(0xFF065F46), fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _regVehicleModelController,
                    validator: (v) {
                      if (_selectedRole == UserRole.courier && (v == null || v.trim().isEmpty)) {
                        return 'Informe o modelo da moto.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Modelo da Moto',
                      hintText: 'Honda Fan 160',
                      prefixIcon: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF059669)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _regVehiclePlateController,
                    validator: (v) {
                      if (_selectedRole == UserRole.courier && (v == null || v.trim().isEmpty)) {
                        return 'Informe a placa.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Placa',
                      hintText: 'BRA-2024',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (_selectedRole == UserRole.customer) ...[
            TextFormField(
              controller: _regDeliveryAddressController,
              decoration: InputDecoration(
                labelText: 'Endereço de Entrega Principal (Opcional)',
                hintText: 'Rua, Número, Apto, Bairro',
                prefixIcon: const Icon(Icons.home_outlined, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Senha e Confirmação
          TextFormField(
            controller: _regPasswordController,
            obscureText: _obscureRegPassword,
            validator: (v) {
              if (v == null || v.length < 6) return 'A senha deve ter no mínimo 6 caracteres.';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Criar Senha de Acesso',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _regConfirmPasswordController,
            obscureText: _obscureRegPassword,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirme sua senha.';
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Confirmar Senha',
              prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          AppButton(
            label: 'Finalizar Cadastro & Acessar',
            isLoading: auth.isLoading,
            isFlameAccent: true,
            icon: Icons.check_circle_outline_rounded,
            onPressed: _handleRegister,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                _tabController.animateTo(0);
              },
              child: const Text(
                'Já possui uma conta? Faça login aqui',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip({
    required String label,
    required IconData icon,
    required UserRole role,
  }) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
