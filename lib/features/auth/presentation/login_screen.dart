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
  final TextEditingController _phoneController = TextEditingController(text: '(11) 98122-3344');
  final TextEditingController _emailController = TextEditingController(text: 'lojista@boragas.app');
  final TextEditingController _passwordController = TextEditingController(text: '••••••••');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _sendCustomerOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    await ref.read(authProvider.notifier).sendPhoneOtp(phone);
    if (mounted) {
      context.push('/otp?phone=${Uri.encodeComponent(phone)}');
    }
  }

  void _loginStaff() async {
    final email = _emailController.text.trim().toLowerCase();
    final pwd = _passwordController.text.trim();

    if (email.contains('admin')) {
      await ref.read(authProvider.notifier).loginAdmin(email, pwd);
      if (mounted) context.go('/admin');
    } else if (email.contains('entregador') || email.contains('courier')) {
      await ref.read(authProvider.notifier).loginCourier(email, pwd);
      if (mounted) context.go('/courier');
    } else {
      await ref.read(authProvider.notifier).loginMerchant(email, pwd);
      if (mounted) context.go('/merchant');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const BoraGasLogo(size: 64, showText: true),
              const SizedBox(height: 24),
              Text(
                'Acesse sua conta',
                style: AppTypography.displayMedium.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 6),
              Text(
                'Gás e água mineral em minutos com o melhor preço',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 24),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(text: 'Cliente (Celular)'),
                    Tab(text: 'Equipe & Lojas'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tab contents
              SizedBox(
                height: 260,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Customer Phone
                    Column(
                      children: [
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Celular / WhatsApp com DDD',
                            prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                            hintText: '(11) 98765-4321',
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Continuar com WhatsApp / SMS',
                          isLoading: auth.isLoading,
                          isFlameAccent: true,
                          icon: Icons.chat_rounded,
                          onPressed: _sendCustomerOtp,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Enviaremos um código SMS ou WhatsApp com validação em 1 toque.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),

                    // Tab 2: Merchant, Courier & Admin
                    Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'E-mail corporativo / Login',
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                            hintText: 'lojista@... / admin@... / entregador@...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Senha de acesso',
                            prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Entrar no Painel Correspondente',
                          isLoading: auth.isLoading,
                          onPressed: _loginStaff,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),
              const SizedBox(height: 10),

              // Quick bypass demo profiles
              const Text(
                'TESTAR IMEDIATAMENTE (DEMO 4 PERFIS):',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        ref.read(authProvider.notifier).switchDemoRole(UserRole.customer);
                        context.go('/home');
                      },
                      child: const Text('Cliente', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        ref.read(authProvider.notifier).switchDemoRole(UserRole.merchant);
                        context.go('/merchant');
                      },
                      child: const Text('Lojista', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        ref.read(authProvider.notifier).switchDemoRole(UserRole.courier);
                        context.go('/courier');
                      },
                      child: const Text('Entregador', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        ref.read(authProvider.notifier).switchDemoRole(UserRole.admin);
                        context.go('/admin');
                      },
                      child: const Text('Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
