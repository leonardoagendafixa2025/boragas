import 'package:flutter/material.dart';
import '../theme/app_cores.dart';

class RuleCheck extends StatelessWidget {
  const RuleCheck({
    super.key,
    required this.text,
    required this.ok,
  });

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok ? AppCores.verde : const Color(0xFFE2E8F0),
            ),
            child: Icon(
              ok ? Icons.check_rounded : Icons.close_rounded,
              size: 11,
              color: ok ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ok ? AppCores.verde : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
