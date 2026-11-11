import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import 'theme/app_cores.dart';
import 'widgets/auth_shell.dart';
import 'widgets/confetti.dart';
import 'widgets/fade_slide.dart';
import 'widgets/morph_button.dart';

class BemVindoScreen extends ConsumerStatefulWidget {
  const BemVindoScreen({
    super.key,
    required this.nome,
    this.primeiroAcesso = false,
  });

  final String nome;
  final bool primeiroAcesso;

  @override
  ConsumerState<BemVindoScreen> createState() => _BemVindoScreenState();
}

class _BemVindoScreenState extends ConsumerState<BemVindoScreen>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  // A chama "respira" suavemente
  late final _chama = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  final _confettiKey = GlobalKey<ConfettiState>();
  Timer? _confettiTimer;

  @override
  void initState() {
    super.initState();
    _confettiTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _confettiKey.currentState?.burst();
    });
  }

  @override
  void dispose() {
    _confettiTimer?.cancel();
    _intro.dispose();
    _chama.dispose();
    super.dispose();
  }

  String get _nome {
    final n = widget.nome.trim();
    if (n.isEmpty) return '';
    return n[0].toUpperCase() + n.substring(1);
  }

  void _irParaDestino() {
    final user = ref.read(authProvider).user;
    final role = user?.role ?? UserRole.customer;

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

  Future<void> _trocarConta() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final saudacao =
        widget.primeiroAcesso ? 'Bem-vindo(a)' : 'Bem-vindo de volta';
    final user = ref.read(authProvider).user;
    final isMerchantOrAdmin =
        user?.role == UserRole.merchant || user?.role == UserRole.admin;
    final isCourier = user?.role == UserRole.courier;

    String ctaLabel = 'Pedir gás agora';
    String description = 'Tudo pronto para o seu próximo pedido de gás.';

    if (isMerchantOrAdmin) {
      ctaLabel = 'Ir para o Painel da Distribuidora';
      description = 'Tudo pronto para gerenciar suas entregas e vendas.';
    } else if (isCourier) {
      ctaLabel = 'Ir para Minhas Entregas';
      description = 'Tudo pronto para receber pedidos de entrega.';
    }

    return AuthShell(
      intro: _intro,
      confettiKey: _confettiKey,
      icone: Icons.local_fire_department_rounded,
      titulo: _nome.isEmpty ? '$saudacao!' : '$saudacao,\n$_nome!',
      subtitulo: 'Que bom ter você por aqui',
      rodape: RodapeLink(
        texto: 'Não é você?',
        link: 'Trocar de conta',
        onTap: _trocarConta,
      ),
      card: AuthCard(
        child: Column(
          children: [
            FadeSlide(
              controller: _intro,
              start: 0.3,
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.08).animate(
                  CurvedAnimation(parent: _chama, curve: Curves.easeInOut),
                ),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppCores.chamaLaranja.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: AppCores.chamaLaranja.withValues(alpha: 0.35),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 54,
                    color: AppCores.chamaLaranja,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FadeSlide(
              controller: _intro,
              start: 0.4,
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppCores.texto,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 22),
            FadeSlide(
              controller: _intro,
              start: 0.5,
              child: MorphButton(
                label: ctaLabel,
                state: ButtonState.idle,
                onTap: _irParaDestino,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
