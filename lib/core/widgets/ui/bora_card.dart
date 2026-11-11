import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class BoraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool isElevated;
  final bool hasGlow;
  final Color? glowColor;

  const BoraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.borderColor,
    this.borderRadius = 20,
    this.onTap,
    this.isElevated = false,
    this.hasGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.merchantCard : Colors.white;
    final defaultBorder = isDark ? AppColors.merchantCardBorder : AppColors.border;

    final cardWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? defaultBorder,
          width: 1,
        ),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: (glowColor ?? AppColors.accentFlame).withValues(alpha: 0.25),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                // Layered Elevation
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                  blurRadius: isElevated ? 16 : 8,
                  offset: const Offset(0, 3),
                ),
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}
