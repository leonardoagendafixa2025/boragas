import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';

enum BoraButtonVariant {
  primaryRoyal,
  primaryFlame,
  primarySuccess,
  secondary,
  outline,
  ghost,
  danger,
}

class BoraButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final BoraButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double? width;
  final double borderRadius;
  final bool enableHaptic;

  const BoraButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = BoraButtonVariant.primaryRoyal,
    this.icon,
    this.isLoading = false,
    this.height = 50,
    this.width,
    this.borderRadius = 16,
    this.enableHaptic = true,
  });

  const BoraButton.flame({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 52,
    this.width,
    this.borderRadius = 16,
    this.enableHaptic = true,
  }) : variant = BoraButtonVariant.primaryFlame;

  const BoraButton.success({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 52,
    this.width,
    this.borderRadius = 16,
    this.enableHaptic = true,
  }) : variant = BoraButtonVariant.primarySuccess;

  const BoraButton.outline({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
    this.width,
    this.borderRadius = 16,
    this.enableHaptic = true,
  }) : variant = BoraButtonVariant.outline;

  const BoraButton.danger({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
    this.width,
    this.borderRadius = 16,
    this.enableHaptic = true,
  }) : variant = BoraButtonVariant.danger;

  @override
  State<BoraButton> createState() => _BoraButtonState();
}

class _BoraButtonState extends State<BoraButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color bg;
    Color fg;
    Border? border;
    Gradient? gradient;

    switch (widget.variant) {
      case BoraButtonVariant.primaryRoyal:
        bg = AppColors.primary;
        fg = Colors.white;
        gradient = AppColors.primaryGradient;
        break;
      case BoraButtonVariant.primaryFlame:
        bg = AppColors.accentFlame;
        fg = Colors.white;
        gradient = AppColors.flameGradient;
        break;
      case BoraButtonVariant.primarySuccess:
        bg = AppColors.success;
        fg = Colors.white;
        gradient = AppColors.successGradient;
        break;
      case BoraButtonVariant.secondary:
        bg = isDark ? AppColors.merchantCardElevated : AppColors.surfaceVariant;
        fg = isDark ? Colors.white : AppColors.textPrimary;
        border = Border.all(color: isDark ? AppColors.merchantCardBorder : AppColors.border);
        break;
      case BoraButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDark ? Colors.white : AppColors.primary;
        border = Border.all(color: isDark ? const Color(0x33FFFFFF) : AppColors.primary, width: 1.4);
        break;
      case BoraButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
        break;
      case BoraButtonVariant.danger:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        fg = const Color(0xFFEF4444);
        border = Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 1);
        break;
    }

    if (isDisabled) {
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
      fg = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
      gradient = null;
      border = null;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: isDisabled
            ? null
            : () {
                if (widget.enableHaptic) {
                  HapticFeedback.lightImpact();
                }
                widget.onPressed!();
              },
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: gradient == null ? bg : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: border,
            boxShadow: (!isDisabled &&
                    (widget.variant == BoraButtonVariant.primaryFlame ||
                        widget.variant == BoraButtonVariant.primaryRoyal ||
                        widget.variant == BoraButtonVariant.primarySuccess))
                ? [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: fg,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: fg,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
