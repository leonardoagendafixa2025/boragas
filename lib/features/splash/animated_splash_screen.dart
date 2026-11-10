import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/remote_config_service.dart';

class AnimatedSplashScreen extends ConsumerStatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  ConsumerState<AnimatedSplashScreen> createState() =>
      _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends ConsumerState<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _flameScale;
  late Animation<double> _cylinderOpacity;
  late Animation<double> _cylinderScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _progressAnimation;

  String _loadingStepText = 'Inicializando ecossistema BoraGás...';

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 1. Flame ignition (0.0 to 0.35)
    _flameScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    // 2. Cylinder formation (0.25 to 0.60)
    _cylinderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeIn),
      ),
    );
    _cylinderScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutBack),
      ),
    );

    // 3. Logo text & slogan (0.55 to 0.85)
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.85, curve: Curves.fastOutSlowIn),
      ),
    );

    // 4. Progress bar sync (0.2 to 0.95)
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    _mainController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _loadingStepText = 'Sincronizando Remote Config & Taxas...');
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      // Simulate remote config load
      ref.read(remoteConfigProvider);
      setState(() => _loadingStepText = 'Localizando distribuidoras próximas...');
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() => _loadingStepText = 'Pronto! Bem-vindo ao BoraGás ⚡');
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient with Energy Heat Waves
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF071B42),
                      Color.lerp(
                        const Color(0xFF0B132B),
                        const Color(0xFF1C2541),
                        _pulseController.value * 0.4,
                      )!,
                      const Color(0xFF030712),
                    ],
                  ),
                ),
              );
            },
          ),

          // Rising particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _EnergyParticlesPainter(
                  progress: _particleController.value,
                ),
              );
            },
          ),

          // Central Cinematic Stage
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Stage 1 & 2: Stylized Flame + Cylinder Formation
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Radiant Glow behind mark
                          Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.15),
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentFlame
                                        .withValues(alpha: 0.35),
                                    blurRadius: 70,
                                    spreadRadius: 15,
                                  ),
                                  BoxShadow(
                                    color: AppColors.gasCyan
                                        .withValues(alpha: 0.25),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Custom Animated Vector Flame
                          Transform.scale(
                            scale: _flameScale.value,
                            child: CustomPaint(
                              size: const Size(140, 140),
                              painter: _FlameIgnitionPainter(
                                glowPhase: _pulseController.value,
                              ),
                            ),
                          ),

                          // Cylinder Badge with Hero
                          Opacity(
                            opacity: _cylinderOpacity.value,
                            child: Transform.scale(
                              scale: _cylinderScale.value,
                              child: Hero(
                                tag: 'boragas_main_logo',
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(36),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 30,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(36),
                                    child: Image.asset(
                                      'assets/images/app_icon.png',
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Stage 3: Logo text & slogan with FadeSlide
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Column(
                            children: [
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Bora',
                                      style: AppTypography.displayLarge.copyWith(
                                        color: Colors.white,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Gás',
                                      style: AppTypography.displayLarge.copyWith(
                                        color: AppColors.accentFlame,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Text(
                                  AppStrings.appSlogan,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Stage 4: Minimalist bottom progress & status text
          PositionBar(
            stepText: _loadingStepText,
            progressAnim: _progressAnimation,
          ),
        ],
      ),
    );
  }
}

class PositionBar extends StatelessWidget {
  final String stepText;
  final Animation<double> progressAnim;

  const PositionBar({
    super.key,
    required this.stepText,
    required this.progressAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 32,
      right: 32,
      bottom: 50,
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              stepText,
              key: ValueKey<String>(stepText),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: AnimatedBuilder(
              animation: progressAnim,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressAnim.value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.gasCyan, AppColors.accentFlame],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentFlame.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FlameIgnitionPainter extends CustomPainter {
  final double glowPhase;

  _FlameIgnitionPainter({required this.glowPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accentFlame,
          AppColors.accentFlame.withValues(alpha: 0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));

    canvas.drawCircle(center, (size.width / 2) * (0.8 + glowPhase * 0.2), paint);
  }

  @override
  bool shouldRepaint(covariant _FlameIgnitionPainter oldDelegate) =>
      oldDelegate.glowPhase != glowPhase;
}

class _EnergyParticlesPainter extends CustomPainter {
  final double progress;

  _EnergyParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.25);
    final rnd = math.Random(42);

    for (int i = 0; i < 20; i++) {
      final initialX = rnd.nextDouble() * size.width;
      final speed = 0.5 + rnd.nextDouble();
      final currentY = (size.height - ((progress * speed * size.height + (i * 45)) % size.height));
      final radius = 1.0 + rnd.nextDouble() * 2.2;
      canvas.drawCircle(Offset(initialX, currentY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyParticlesPainter oldDelegate) => true;
}
