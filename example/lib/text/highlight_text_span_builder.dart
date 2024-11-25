import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';

class HighlightText extends RegExpSpecialText {
  @override
  RegExp get regExp => RegExp(
        "<Highlight color=['\"](.*?)['\"]>(.*?)</Highlight>",
      );

  static String getHighlightString(String content) {
    return '<Highlight color="#FF2196F3">' + content + '</Highlight>';
  }

  @override
  InlineSpan finishText(int start, Match match,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap}) {
    final String hexColor = match[1]!;

    return SpecialTextSpan(
      text: match[2]!,
      actualText: match[0],
      start: start,
      style: textStyle?.copyWith(
          color: Color(int.parse(hexColor.substring(1), radix: 16))),
      keepVisible: true,
    );
  }
}

class HighlightTextSpanBuilder extends RegExpSpecialTextSpanBuilder {
  @override
  List<RegExpSpecialText> get regExps => <RegExpSpecialText>[
        HighlightText(),
      ];
}
