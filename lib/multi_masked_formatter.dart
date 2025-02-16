import 'package:flutter/services.dart';

class MultiMaskedTextInputFormatter extends TextInputFormatter {
  List<String> _masks = [];
  String _separator = '';
  String _prevMask = '';
  bool _isPhoneNumber = false;
  static const minPhoneNumberLength = 12;

  MultiMaskedTextInputFormatter({
    required List<String> masks,
    required String separator,
    bool isPhoneNumber = false,
  }) {
    _isPhoneNumber = isPhoneNumber;
    _separator = separator.isNotEmpty ? separator : '';
    if (masks.isNotEmpty) {
      _masks = masks;
      _masks.sort((l, r) => l.length.compareTo(r.length));
      _prevMask = masks[0];
    }
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text;
    final oldText = oldValue.text;

    if (_isPhoneNumber && newText.length < oldText.length && newText.length < minPhoneNumberLength) {
      return newValue;
    }

    if (newText.isEmpty || _masks.isEmpty || _separator.isEmpty) {
      return newValue;
    }

    final pasted = (newText.length - oldText.length).abs() > 1;
    final mask = _masks.firstWhere((value) {
      final maskValue = pasted ? value.replaceAll(_separator, '') : value;
      return newText.length <= maskValue.length;
    }, orElse: () => '');

    if (mask.isEmpty) {
      return oldValue;
    }

    final needReset = _prevMask != mask;
    _prevMask = mask;

    if (needReset || _isPhoneNumber && newText.length == minPhoneNumberLength) {
      final text = newText.replaceAll(_separator, '');
      String resetValue = '';
      int sep = 0;

      for (int i = 0; i < text.length; i++) {
        if (mask[i + sep] == _separator) {
          resetValue += _separator;
          ++sep;
        }
        resetValue += text[i];
      }

      return TextEditingValue(
          text: resetValue,
          selection: TextSelection.collapsed(
            offset: resetValue.length,
          ));
    }

    if (newText.length < mask.length && mask[newText.length - 1] == _separator) {
      final text = '$oldText$_separator${newText.substring(newText.length - 1)}';
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
          offset: text.length,
        ),
      );
    }

    return newValue;
  }
}
