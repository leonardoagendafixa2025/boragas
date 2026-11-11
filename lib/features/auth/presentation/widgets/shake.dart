import 'dart:math';
import 'package:flutter/material.dart';

class Shake extends StatefulWidget {
  const Shake({super.key, required this.child});

  final Widget child;

  @override
  State<Shake> createState() => ShakeState();
}

class ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Balanço oscilatório amortecido
        final progress = _controller.value;
        final offset = sin(progress * pi * 4) * 10 * (1 - progress);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
