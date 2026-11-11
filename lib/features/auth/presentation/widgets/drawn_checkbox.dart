import 'package:flutter/material.dart';
import '../theme/app_cores.dart';

class DrawnCheckbox extends StatelessWidget {
  const DrawnCheckbox({
    super.key,
    required this.value,
    required this.onTap,
  });

  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppCores.roxo : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: value ? AppCores.roxo : const Color(0xFF94A3B8),
            width: 2,
          ),
        ),
        child: value
            ? const Icon(
                Icons.check_rounded,
                size: 18,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
