import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_cores.dart';

class AnimatedField extends StatefulWidget {
  const AnimatedField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
    this.inputFormatters,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  State<AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<AnimatedField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppCores.campoFundo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? AppCores.roxo : AppCores.campoBorda,
          width: _isFocused ? 1.8 : 1.2,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppCores.roxo.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextFormField(
        focusNode: _focusNode,
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        obscureText: widget.obscure,
        onFieldSubmitted: widget.onSubmitted,
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        validator: widget.validator,
        style: const TextStyle(
          color: AppCores.texto,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: widget.label,
          labelStyle: TextStyle(
            color: _isFocused ? AppCores.roxo : const Color(0xFF837D9A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(
              widget.icon,
              size: 20,
              color: _isFocused ? AppCores.roxo : const Color(0xFF837D9A),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          suffixIcon: widget.suffix,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}
