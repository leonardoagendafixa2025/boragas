import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class BoraGasLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isWhite;
  final String? heroTag;

  const BoraGasLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.isWhite = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: Image.asset(
          'assets/images/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => CustomPaint(
            size: Size(size, size),
            painter: _BoraGasVectorPainter(),
          ),
        ),
      ),
    );

    if (heroTag != null) {
      mark = Hero(tag: heroTag!, child: mark);
    }

    if (!showText) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        SizedBox(width: size * 0.25),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Bora',
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: size * 0.48,
                      fontWeight: FontWeight.w900,
                      color: isWhite ? Colors.white : AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Gás',
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: size * 0.48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accentFlame,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            TextSpanWrapper(
              text: 'ENTREGA RÁPIDA ⚡',
              fontSize: size * 0.18,
              color: isWhite
                  ? Colors.white.withValues(alpha: 0.8)
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ],
    );
  }
}

class TextSpanWrapper extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;

  const TextSpanWrapper({
    super.key,
    required this.text,
    required this.fontSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: color,
      ),
    );
  }
}

class _BoraGasVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0052CC), Color(0xFF2684FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.26)),
      bgPaint,
    );

    // Dynamic Flame
    final flamePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF7A00), Color(0xFFFF5630)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(rect);

    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.2);
    path.cubicTo(
      size.width * 0.65,
      size.height * 0.35,
      size.width * 0.75,
      size.height * 0.55,
      size.width * 0.65,
      size.height * 0.75,
    );
    path.cubicTo(
      size.width * 0.55,
      size.height * 0.85,
      size.width * 0.45,
      size.height * 0.85,
      size.width * 0.35,
      size.height * 0.75,
    );
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.55,
      size.width * 0.4,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.2,
    );
    path.close();

    canvas.drawPath(path, flamePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
