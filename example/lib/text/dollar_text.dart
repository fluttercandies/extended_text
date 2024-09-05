// ignore_for_file: unused_element

import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class DollarText extends SpecialText {
  DollarText(TextStyle? textStyle, SpecialTextGestureTapCallback? onTap,
      {this.start})
      : super(flag, flag, textStyle, onTap: onTap);
  static const String flag = '\$';
  final int? start;
  @override
  InlineSpan finishText() {
    final String text = getContent();

    return _SpecialTextSpan(
        text: text,
        actualText: toString(),
        start: start!,
        deleteAll: false,
        style: (textStyle ?? const TextStyle())
            .copyWith(color: Colors.orange, fontSize: 16),
        mouseCursor: SystemMouseCursors.text,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (onTap != null) {
              onTap!(toString());
            }
          });
  }
}

class _SpecialTextSpan extends SpecialTextSpan with IgnoreGradientSpan {
  _SpecialTextSpan({
    super.style,
    required super.text,
    super.actualText,
    super.start = 0,
    super.deleteAll = true,
    super.recognizer,
    super.children,
    super.semanticsLabel,
    super.mouseCursor,
    super.onEnter,
    super.onExit,
  });

  @override
  String getSelectedContent(String showText) {
    return '${DollarText.flag}$showText${DollarText.flag}';
  }
}

List<String> dollarList = <String>[
  '\$Dota2\$',
  '\$Dota2 Ti9\$',
  '\$CN dota best dota\$',
  '\$Flutter\$',
  '\$CN dev best dev\$',
  '\$UWP\$',
  '\$Nevermore\$',
  '\$FlutterCandies\$',
  '\$ExtendedImage\$',
  '\$ExtendedText\$',
];
