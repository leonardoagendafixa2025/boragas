import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class BoraBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final Widget? bottomAction;
  final IconData? icon;
  final Color? iconColor;

  const BoraBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.bottomAction,
    this.icon,
    this.iconColor,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget content,
    Widget? bottomAction,
    IconData? icon,
    Color? iconColor,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BoraBottomSheet(
        title: title,
        subtitle: subtitle,
        content: content,
        bottomAction: bottomAction,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.merchantCardBorder : AppColors.border,
          width: 1,
        ),
      ),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? const Color(0x1AFFFFFF) : AppColors.border,
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: content,
              ),
            ),

            // Bottom Sticky Action
            if (bottomAction != null) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0x1AFFFFFF) : AppColors.border,
                    ),
                  ),
                ),
                child: bottomAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
