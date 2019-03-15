import 'package:extended_text/src/text_painter_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class OverFlowTextSpan extends TextSpan {
  ///helper for textPainter
  final TextPainterHelper _textPainterHelper;
  TextPainterHelper get textPainterHelper => _textPainterHelper;

  ///background to cover up the original text under [OverFlowTextSpan]
  final Color background;

  OverFlowTextSpan(
      {TextStyle style,
      String text,
      List<TextSpan> children,
      GestureRecognizer recognizer,
      this.background})
      : _textPainterHelper = TextPainterHelper(),
        //assert(background != null),
        super(
            style: style,
            text: text,
            children: children,
            recognizer: recognizer);

  TextPainter layout(TextPainter painter) {
    return _textPainterHelper.layout(painter, this, compareChildren: true);
  }
}
