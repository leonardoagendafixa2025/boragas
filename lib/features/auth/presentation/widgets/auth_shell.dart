import 'package:flutter/material.dart';
import '../theme/app_cores.dart';
import 'confetti.dart';
import 'fade_slide.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.intro,
    required this.titulo,
    required this.subtitulo,
    required this.card,
    this.rodape,
    this.icone,
    this.iconeWidget,
    this.mostrarVoltar = false,
    this.onVoltar,
    this.confettiKey,
  });

  final AnimationController intro;
  final String titulo;
  final String subtitulo;
  final Widget card;
  final Widget? rodape;
  final IconData? icone;
  final Widget? iconeWidget;
  final bool mostrarVoltar;
  final VoidCallback? onVoltar;
  final GlobalKey<ConfettiState>? confettiKey;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppCores.fundo,
      body: Stack(
        children: [
          // 1. Fundo Gradiente Cósmico com Orbes Suaves
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.6, -0.5),
                  radius: 1.2,
                  colors: [
                    Color(0xFF2A1254),
                    AppCores.fundo,
                    AppCores.fundoEscuro,
                  ],
                ),
              ),
            ),
          ),

          // Orbe Brilhante Magenta / Rosa no Topo
          Positioned(
            top: -60,
            left: size.width * 0.1,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppCores.orbeRosa.withValues(alpha: 0.45),
                      AppCores.orbeMagenta.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Orbe Azul / Ciano na Base Direita
          Positioned(
            bottom: -80,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppCores.orbeAzul.withValues(alpha: 0.35),
                      AppCores.orbeCiano.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Botão Voltar (se ativado)
          if (mostrarVoltar)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
                onPressed: onVoltar ?? () => Navigator.maybePop(context),
              ),
            ),

          // 3. Conteúdo Rolável Principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),

                      // Badge Ícone Central
                      FadeSlide(
                        controller: intro,
                        start: 0.05,
                        child: Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFF43F5E),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF43F5E).withValues(alpha: 0.4),
                                  blurRadius: 22,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: iconeWidget ??
                                  Icon(
                                    icone ?? Icons.propane_tank_rounded,
                                    size: 34,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Título
                      FadeSlide(
                        controller: intro,
                        start: 0.15,
                        child: Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Subtítulo
                      FadeSlide(
                        controller: intro,
                        start: 0.22,
                        child: Text(
                          subtitulo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppCores.textoSecundario,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Cartão Branco com Formulário
                      FadeSlide(
                        controller: intro,
                        start: 0.28,
                        child: card,
                      ),

                      // Rodapé (link para cadastro/login)
                      if (rodape != null) ...[
                        const SizedBox(height: 20),
                        FadeSlide(
                          controller: intro,
                          start: 0.55,
                          child: rodape!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Efeito de Confetes
          if (confettiKey != null)
            Confetti(key: confettiKey),
        ],
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: child,
    );
  }
}

class RodapeLink extends StatelessWidget {
  const RodapeLink({
    super.key,
    required this.texto,
    required this.link,
    required this.onTap,
  });

  final String texto;
  final String link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.white70),
            children: [
              TextSpan(text: '$texto '),
              TextSpan(
                text: link,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
