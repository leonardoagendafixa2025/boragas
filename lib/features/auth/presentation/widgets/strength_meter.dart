import 'package:flutter/material.dart';
import '../theme/app_cores.dart';

class StrengthMeter extends StatelessWidget {
  const StrengthMeter({super.key, required this.score});

  final int score;

  Color get _color {
    if (score <= 1) return AppCores.vermelho;
    if (score == 2) return AppCores.laranja;
    return AppCores.verde;
  }

  String get _text {
    if (score <= 1) return 'Senha fraca';
    if (score == 2) return 'Senha média';
    return 'Senha forte e segura';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (index) {
            final active = index < score;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: active ? _color : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          _text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
      ],
    );
  }
}
