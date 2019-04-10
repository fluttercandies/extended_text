import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class DollarText extends SpecialText {
  static const String flag = "\$";
  DollarText(TextStyle textStyle, SpecialTextGestureTapCallback onTap)
      : super(flag, flag, textStyle, onTap: onTap);

  @override
  TextSpan finishText() {
    // TODO: implement finishText
    final String atText = getContent();
    return TextSpan(
        text: atText,
        style: textStyle?.copyWith(color: Colors.orange),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (onTap != null) onTap(toString());
          });
  }
}
