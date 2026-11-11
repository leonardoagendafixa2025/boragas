import 'package:flutter/material.dart';
import '../theme/app_cores.dart';

enum ButtonState { idle, loading, success }

class MorphButton extends StatelessWidget {
  const MorphButton({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
    this.width = double.infinity,
    this.height = 54.0,
  });

  final String label;
  final ButtonState state;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isLoading = state == ButtonState.loading;
    final isSuccess = state == ButtonState.success;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: (isLoading || isSuccess) ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: isSuccess ? AppCores.verde : AppCores.roxo,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(
            color: (isSuccess ? AppCores.verde : AppCores.roxo).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2),
          onTap: (isLoading || isSuccess) ? null : onTap,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : isSuccess
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                      : Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
