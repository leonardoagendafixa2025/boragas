import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class BoraPulsingHalo extends StatefulWidget {
  final Widget child;
  final bool isPulsing;
  final Color pulseColor;
  final double borderRadius;

  const BoraPulsingHalo({
    super.key,
    required this.child,
    this.isPulsing = true,
    this.pulseColor = AppColors.accentFlame,
    this.borderRadius = 20,
  });

  @override
  State<BoraPulsingHalo> createState() => _BoraPulsingHaloState();
}

class _BoraPulsingHaloState extends State<BoraPulsingHalo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _glowAnimation = Tween<double>(begin: 0.15, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BoraPulsingHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) return widget.child;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final alpha = _glowAnimation.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.pulseColor.withValues(alpha: alpha),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.pulseColor.withValues(alpha: alpha * 0.4),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
