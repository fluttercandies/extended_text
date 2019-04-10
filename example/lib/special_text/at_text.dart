import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AtText extends SpecialText {
  static const String flag = "@";
  AtText(TextStyle textStyle, SpecialTextGestureTapCallback onTap)
      : super(flag, " ", textStyle, onTap: onTap);

  @override
  TextSpan finishText() {
    // TODO: implement finishText

    final String atText = toString();
    return TextSpan(
        text: atText,
        style: textStyle?.copyWith(color: Colors.blue, fontSize: 16.0),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (onTap != null) onTap(atText);
          });
  }
}
