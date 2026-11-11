import 'dart:math';
import 'package:flutter/material.dart';

class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => ConfettiState();
}

class ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void burst() {
    _particles.clear();
    final colors = [
      const Color(0xFF6C5CE7),
      const Color(0xFFFD79A8),
      const Color(0xFF00B894),
      const Color(0xFFFDCB6E),
      const Color(0xFF0984E3),
      const Color(0xFFFF7675),
    ];

    for (int i = 0; i < 45; i++) {
      _particles.add(
        _Particle(
          x: 0.15 + _random.nextDouble() * 0.7,
          y: 0.1 + _random.nextDouble() * 0.2,
          vx: (_random.nextDouble() - 0.5) * 0.8,
          vy: -0.3 - _random.nextDouble() * 0.6,
          color: colors[_random.nextInt(colors.length)],
          size: 6.0 + _random.nextDouble() * 8.0,
          rotation: _random.nextDouble() * 2 * pi,
          vRot: (_random.nextDouble() - 0.5) * 8,
        ),
      );
    }

    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isAnimating) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(
          particles: _particles,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  final double vx;
  final double vy;
  final Color color;
  final double size;
  double rotation;
  final double vRot;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.vRot,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final curX = (p.x + p.vx * progress) * size.width;
      final curY = (p.y + p.vy * progress + 0.8 * progress * progress) * size.height;
      final rot = p.rotation + p.vRot * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(curX, curY);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
