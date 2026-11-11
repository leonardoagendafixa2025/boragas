import 'package:flutter/services.dart';

class TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final buffer = StringBuffer();
    if (digits.isNotEmpty) {
      buffer.write('(');
      buffer.write(digits.substring(0, digits.length.clamp(0, 2)));
      if (digits.length > 2) {
        buffer.write(') ');
        if (digits.length <= 10) {
          // (XX) XXXX-XXXX
          buffer.write(digits.substring(2, digits.length.clamp(2, 6)));
          if (digits.length > 6) {
            buffer.write('-');
            buffer.write(digits.substring(6, digits.length.clamp(6, 10)));
          }
        } else {
          // (XX) XXXXX-XXXX
          buffer.write(digits.substring(2, digits.length.clamp(2, 7)));
          if (digits.length > 7) {
            buffer.write('-');
            buffer.write(digits.substring(7, digits.length.clamp(7, 11)));
          }
        }
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
