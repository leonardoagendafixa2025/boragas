import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ConfettiParticle {
  final double x;
  final double y;
  final double speedX;
  final double speedY;
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final double size;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
  });
}

class ConfettiCelebrationOverlay extends StatefulWidget {
  final VoidCallback? onFinished;

  const ConfettiCelebrationOverlay({super.key, this.onFinished});

  @override
  State<ConfettiCelebrationOverlay> createState() => _ConfettiCelebrationOverlayState();
}

class _ConfettiCelebrationOverlayState extends State<ConfettiCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  final List<Color> _palette = const [
    AppColors.primary,
    AppColors.accentFlame,
    AppColors.gasCyan,
    Color(0xFFFFD700), // Gold
    Color(0xFF10B981), // Emerald
    Color(0xFFEC4899), // Pink
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onFinished?.call();
        }
      });

    // Generate 50 particles from center-top
    for (int i = 0; i < 50; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 3.0 + _random.nextDouble() * 7.0;
      _particles.add(
        ConfettiParticle(
          x: 0.5,
          y: 0.35,
          speedX: cos(angle) * speed,
          speedY: sin(angle) * speed - 4.0, // Initial upward burst
          rotation: _random.nextDouble() * pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 8,
          color: _palette[_random.nextInt(_palette.length)],
          size: 6.0 + _random.nextDouble() * 6.0,
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              progress: _controller.value,
              particles: _particles,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    const gravity = 8.0;

    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final currentX = (p.x * size.width) + (p.speedX * progress * 40);
      final currentY = (p.y * size.height) +
          (p.speedY * progress * 40) +
          (0.5 * gravity * progress * progress * 40);
      final currentRotation = p.rotation + (p.rotationSpeed * progress);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
