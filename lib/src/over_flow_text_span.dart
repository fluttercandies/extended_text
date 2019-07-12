import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class OverFlowTextSpan extends TextSpan {
  ///helper for textPainter
  final TextPainterHelper _textPainterHelper;
  TextPainterHelper get textPainterHelper => _textPainterHelper;

  OverFlowTextSpan(
      {TextStyle style,
      String text,
      List<InlineSpan> children,
      GestureRecognizer recognizer})
      : _textPainterHelper = TextPainterHelper(),
        super(
            style: style,
            text: text,
            children: children,
            recognizer: recognizer);

  TextPainter layout(TextPainter painter) {
    return _textPainterHelper.layout(painter, this, compareChildren: true);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final OverFlowTextSpan typedOther = other;
    return typedOther.text == text &&
        typedOther.style == style &&
        typedOther.recognizer == recognizer &&
        listEquals<TextSpan>(typedOther.children, children);
  }

  @override
  int get hashCode => hashValues(style, text, recognizer, hashList(children));
}
