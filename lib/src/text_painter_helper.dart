import 'package:flutter/material.dart';

class TextPainterHelper {
  TextPainter _painter;
  TextPainter get painter => _painter;

  ///method for [OverFlowTextSpan] and [BackgroundTextSpan]
  TextPainter layout(TextPainter painter, TextSpan textSpan,
      {bool compareChildren: true}) {
    if (_painter == null ||
        ((compareChildren
                ? _painter.text != textSpan
                : _painter.text.text != textSpan.text) ||
            _painter.textAlign != painter.textAlign ||
            _painter.textScaleFactor != painter.textScaleFactor ||
            _painter.locale != painter.locale)) {
      _painter = TextPainter(
          text: textSpan,
          textAlign: painter.textAlign,
          textScaleFactor: painter.textScaleFactor,
          textDirection: painter.textDirection,
          locale: painter.locale);
    }
    _painter.layout();

    return _painter;
  }

  ///method for [OverFlowTextSpan]
  ///offset int coordinate system
  Offset _offset;
  void saveOffset(Offset offset) {
    _offset = offset;
  }

  ///method for [OverFlowTextSpan]
  TextPosition getPositionForOffset(Offset offset) {
    return painter.getPositionForOffset(offset - _offset);
  }

  ///method for [OverFlowTextSpan]
  TextSpan getSpanForPosition(TextPosition position) {
    return painter.text.getSpanForPosition(position);
  }
}
