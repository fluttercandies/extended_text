import 'package:extended_text/src/text_painter_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class BackgroundTextSpan extends TextSpan {
  /// The paint drawn as a background for the text.
  ///
  /// The value should ideally be cached and reused each time if multiple text
  /// styles are created with the same paint settings. Otherwise, each time it
  /// will appear like the style changed, which will result in unnecessary
  /// updates all the way through the framework.
  ///
  /// workaround for 24335 issue
  /// https://github.com/flutter/flutter/issues/24335
  /// https://github.com/flutter/flutter/issues/24337
  /// we will draw background by ourself
  final Paint background;

  ///clip BorderRadius
  final BorderRadius clipBorderRadius;

  ///paint background by yourself
  final PaintBackground paintBackground;

  ///helper for textPainter
  final TextPainterHelper _textPainterHelper;

  BackgroundTextSpan(
      {TextStyle style,
      String text,
      //List<TextSpan> children,
      GestureRecognizer recognizer,
      this.background,
      this.clipBorderRadius,
      this.paintBackground})
      : assert(background != null),
        _textPainterHelper = TextPainterHelper(),
        super(style: style, text: text, children: null, recognizer: recognizer);

  TextPainter layout(TextPainter painter) {
    return _textPainterHelper.layout(painter, this, compareChildren: false);
  }

  ///rect: all text size
  void paint(Canvas canvas, Offset offset, Rect rect,
      {Offset endOffset, TextPainter wholeTextPainter}) {
    assert(_textPainterHelper.painter != null);

    if (paintBackground != null) {
      bool handle = paintBackground(
              this, canvas, offset, _textPainterHelper.painter, rect,
              endOffset: endOffset, wholeTextPainter: wholeTextPainter) ??
          false;
      if (handle) return;
    }

    Rect textRect = offset & _textPainterHelper.painter.size;

    ///top-right
    if (endOffset != null) {
      Rect firstLineRect = offset &
          Size(rect.right - offset.dx, _textPainterHelper.painter.height);

      if (clipBorderRadius != null) {
        canvas.save();
        canvas.clipPath(Path()
          ..addRRect(BorderRadius.only(
                  topLeft: clipBorderRadius.topLeft,
                  bottomLeft: clipBorderRadius.bottomLeft)
              .resolve(_textPainterHelper.painter.textDirection)
              .toRRect(firstLineRect)));
      }

      ///start
      canvas.drawRect(firstLineRect, background);

      if (clipBorderRadius != null) {
        canvas.restore();
      }

      ///endOffset.y has deviation,so we calculate with text height
      ///print(((endOffset.dy - offset.dy) / _painter.height));
      var fullLinesAndLastLine =
          ((endOffset.dy - offset.dy) / _textPainterHelper.painter.height)
              .round();

      double y = offset.dy;
      for (int i = 0; i < fullLinesAndLastLine; i++) {
        y += _textPainterHelper.painter.height;
        //last line
        if (i == fullLinesAndLastLine - 1) {
          Rect lastLineRect = Offset(0.0, y) &
              Size(endOffset.dx, _textPainterHelper.painter.height);
          if (clipBorderRadius != null) {
            canvas.save();
            canvas.clipPath(Path()
              ..addRRect(BorderRadius.only(
                      topRight: clipBorderRadius.topRight,
                      bottomRight: clipBorderRadius.bottomRight)
                  .resolve(_textPainterHelper.painter.textDirection)
                  .toRRect(lastLineRect)));
          }
          canvas.drawRect(lastLineRect, background);
          if (clipBorderRadius != null) {
            canvas.restore();
          }
        } else {
          ///draw full line
          canvas.drawRect(
              Offset(0.0, y) &
                  Size(rect.width, _textPainterHelper.painter.height),
              background);
        }
      }
    } else {
      if (clipBorderRadius != null) {
        canvas.save();
        canvas.clipPath(Path()
          ..addRRect(clipBorderRadius
              .resolve(_textPainterHelper.painter.textDirection)
              .toRRect(textRect)));
      }

      canvas.drawRect(textRect, background);

      if (clipBorderRadius != null) {
        canvas.restore();
      }
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final BackgroundTextSpan typedOther = other;
    return typedOther.text == text &&
        typedOther.style == style &&
        typedOther.recognizer == recognizer &&
        typedOther.background == background &&
        typedOther.clipBorderRadius == clipBorderRadius &&
        typedOther.paintBackground == paintBackground;
  }

  @override
  int get hashCode => hashValues(
        style,
        text,
        recognizer,
        background,
        clipBorderRadius,
        paintBackground,
      );

  @override
  RenderComparison compareTo(TextSpan other) {
    if (other is BackgroundTextSpan) {
      if (other.background != background ||
          other.clipBorderRadius != clipBorderRadius ||
          other.paintBackground != paintBackground) {
        return RenderComparison.paint;
      }
    }

    // TODO: implement compareTo
    return super.compareTo(other);
  }
}

///if you don't want use default, please return true.
///endOffset is the text top-right Offfset
///allTextPainter is the text painter of extended text.
///painter is current background text painter
typedef PaintBackground = bool Function(BackgroundTextSpan backgroundTextSpan,
    Canvas canvas, Offset offset, TextPainter painter, Rect rect,
    {Offset endOffset, TextPainter wholeTextPainter});
