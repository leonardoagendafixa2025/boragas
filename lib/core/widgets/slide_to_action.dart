import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class SlideToActionWidget extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onCompleted;
  final Color? backgroundColor;
  final Color? thumbColor;
  final Color? activeTrackColor;
  final double height;
  final bool isLoading;

  const SlideToActionWidget({
    super.key,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
    required this.onCompleted,
    this.backgroundColor,
    this.thumbColor,
    this.activeTrackColor,
    this.height = 56,
    this.isLoading = false,
  });

  @override
  State<SlideToActionWidget> createState() => _SlideToActionWidgetState();
}

class _SlideToActionWidgetState extends State<SlideToActionWidget>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _springAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
    )..addListener(() {
        setState(() {
          _dragPosition = _springAnimation.value.clamp(0.0, double.infinity);
        });
      });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isCompleted || widget.isLoading) return;

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });

    // Provide light tick on drag progress
    if ((_dragPosition / maxDrag) > 0.45 && (_dragPosition / maxDrag) < 0.52) {
      HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_isCompleted || widget.isLoading) return;

    if (maxDrag > 0 && _dragPosition >= maxDrag * 0.75) {
      // Completed threshold reached!
      setState(() {
        _dragPosition = maxDrag;
        _isCompleted = true;
      });
      HapticFeedback.heavyImpact();
      widget.onCompleted();
    } else {
      // Spring back with physical bounce
      _springAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
      );
      _springController.reset();
      _springController.forward();
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? const Color(0xFF0F172A);
    final thumbColor = widget.thumbColor ?? AppColors.primary;
    final activeColor = widget.activeTrackColor ?? AppColors.accentFlame;
    final thumbSize = widget.height - 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = (constraints.maxWidth - thumbSize - 8).clamp(0.0, double.infinity);
        final progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: widget.height,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Dynamic Fill Track
              Container(
                width: (_dragPosition + (thumbSize / 2) + 4).clamp(0.0, constraints.maxWidth),
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [activeColor.withValues(alpha: 0.85), activeColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
              ),

              // Shimmering / Pulsing Center Text
              Center(
                child: Opacity(
                  opacity: (1.0 - (progress * 1.6)).clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 48, right: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Draggable Thumb
              Positioned(
                left: 4 + _dragPosition,
                child: GestureDetector(
                  key: const Key('slide-action-thumb'),
                  onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxDrag),
                  onHorizontalDragEnd: (d) => _onDragEnd(d, maxDrag),
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: _isCompleted ? AppColors.success : thumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isCompleted ? AppColors.success : thumbColor).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              _isCompleted ? Icons.check_rounded : widget.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
