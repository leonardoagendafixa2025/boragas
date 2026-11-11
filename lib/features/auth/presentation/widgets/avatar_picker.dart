import 'package:flutter/material.dart';
import '../theme/app_cores.dart';

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final int selected;
  final ValueChanged<int> onSelect;

  static const List<IconData> _avatarIcons = [
    Icons.face_rounded,
    Icons.sentiment_very_satisfied_rounded,
    Icons.emoji_emotions_rounded,
    Icons.person_pin_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Escolha seu avatar:',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_avatarIcons.length, (index) {
            final isSelected = selected == index;
            return GestureDetector(
              onTap: () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppCores.roxo : const Color(0xFFF1F5F9),
                  border: Border.all(
                    color: isSelected ? AppCores.roxo : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppCores.roxo.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _avatarIcons[index],
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  size: 26,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
