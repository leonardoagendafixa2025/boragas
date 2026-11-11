import 'package:flutter/material.dart';

class FadeSlide extends StatelessWidget {
  const FadeSlide({
    super.key,
    required this.controller,
    required this.start,
    this.duration = 0.25,
    required this.child,
    this.offset = const Offset(0, 0.2),
  });

  final AnimationController controller;
  final double start;
  final double duration;
  final Widget child;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final end = (start + duration).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: offset, end: Offset.zero).animate(curve),
        child: child,
      ),
    );
  }
}
