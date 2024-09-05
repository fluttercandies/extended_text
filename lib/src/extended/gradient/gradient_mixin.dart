part of 'package:extended_text/src/extended/rendering/paragraph.dart';

/// A mixin to apply gradient effects to text rendering.
mixin GradientMixin on _RenderParagraph {
  GradientConfig? _gradientConfig;

  /// Configuration for applying gradients to text.
  ///
  /// [gradient] is the gradient that will be applied to the text.
  /// [ignoreWidgetSpan] determines whether `WidgetSpan` elements should be
  /// included in the gradient application. By default, widget spans are ignored.
  /// [mode] specifies how the gradient should be applied to the text. The default
  /// is [GradientRenderMode.fullText], meaning the gradient will apply to the entire text.
  /// [ignoreRegex] is a regular expression used to exclude certain parts of the text
  /// from the gradient effect. For example, it can be used to exclude specific characters
  /// or words (like emojis or special symbols) from the gradient application.
  GradientConfig? get gradientConfig => _gradientConfig;
  set gradientConfig(GradientConfig? value) {
    if (_gradientConfig != value) {
      _gradientConfig = value;
      markNeedsPaint();
    }
  }

  /// Method to draw the gradient on the text based on the selected `GradientType`.
  /// and ignore the text base on [ignoreGradientRegex]
  void drawGradient(PaintingContext context, Offset offset) {
    // save for _ignoreGradient
    context.canvas.save();
    _ignoreGradient(context, offset);

    if (_gradientConfig?.beforeDrawGradient != null) {
      _gradientConfig!.beforeDrawGradient!(context, _textPainter, offset);
    }

    _drawGradient(context, offset);
    // restore for _ignoreGradient
    context.canvas.restore();
    // restore for _drawGradient
    context.canvas.restore();
  }

  /// Method to draw the gradient on the text based on the selected `GradientType`.
  void _drawGradient(PaintingContext context, Offset offset) {
    if (_gradientConfig != null) {
      switch (_gradientConfig!.renderMode) {
        // Apply the gradient to the entire text area.
        case GradientRenderMode.fullText:
          _drawGradientWithRect(offset & size, context);
          break;

        // Apply the gradient to each individual line of text.
        case GradientRenderMode.line:
          _textPainter.computeLineMetrics().forEach((ui.LineMetrics line) {
            final Rect rect = Rect.fromLTWH(
              0,
              line.baseline - line.ascent,
              size.width,
              line.ascent + line.descent,
            ).shift(offset);
            _drawGradientWithRect(rect, context);
          });
          break;

        // Apply the gradient to the selected text ranges.
        case GradientRenderMode.selection:
          _textPainter
              .getBoxesForSelection(TextSelection(
            baseOffset: 0,
            extentOffset: _textPainter.plainText.length,
          ))
              .forEach((ui.TextBox box) {
            final Rect rect = box.toRect().shift(offset);

            _drawGradientWithRect(rect, context);
          });
          break;
        case GradientRenderMode.character:
          final CharacterRange characterRange =
              CharacterRange(_textPainter.plainText);
          int graphemeStart = 0;
          while (characterRange.moveNext()) {
            final int graphemeEnd =
                graphemeStart + characterRange.current.length;
            final List<TextBox> boxes = _textPainter.getBoxesForSelection(
              TextSelection(
                  baseOffset: graphemeStart, extentOffset: graphemeEnd),
            );
            for (final ui.TextBox box in boxes) {
              final ui.Rect rect = box.toRect().shift(offset);
              _drawGradientWithRect(rect, context);
            }
            graphemeStart = graphemeEnd;
          }

          break;
        case GradientRenderMode.word:
          final String text = _textPainter.plainText;
          for (int i = 0; i < text.length; i++) {
            final ui.TextRange wordBoundary =
                _textPainter.getWordBoundary(TextPosition(offset: i));
            final int start = wordBoundary.start;
            final int end = wordBoundary.end;
            if (start < end && end <= text.length) {
              final List<ui.TextBox> boxes = _textPainter.getBoxesForSelection(
                TextSelection(baseOffset: start, extentOffset: end),
              );

              for (final ui.TextBox box in boxes) {
                final ui.Rect rect = box.toRect().shift(offset);
                _drawGradientWithRect(rect, context);
              }
            }
            i = math.max(i, math.max(start, end - 1));
          }
          break;
      }
    }
  }

  bool _ignoreGradient(PaintingContext context, ui.Offset offset) {
    final List<TextBox> boxes = <ui.TextBox>[];
    if (_gradientConfig != null && _gradientConfig!.ignoreRegex != null) {
      _gradientConfig!.ignoreRegex!.allMatches(_textPainter.plainText).forEach(
        (RegExpMatch match) {
          final int start = match.start;
          final int end = match.end;
          final TextSelection textSelection =
              TextSelection(baseOffset: start, extentOffset: end);
          boxes.addAll(_textPainter.getBoxesForSelection(textSelection));
        },
      );
    }

    if (_textPainter.text != null) {
      void _findIgnoreGradientSpan(InlineSpan span, int startIndex) {
        if (span is IgnoreGradientSpan) {
          final int length = span.toPlainText().length;
          final TextSelection textSelection = TextSelection(
              baseOffset: startIndex, extentOffset: startIndex + length);
          boxes.addAll(_textPainter.getBoxesForSelection(textSelection));
          // IgnoreGradientSpan and it's children should not be applied to the gradient.
          return;
        }

        if (span is TextSpan && span.children != null) {
          int childStartIndex = startIndex;
          for (final InlineSpan child in span.children!) {
            _findIgnoreGradientSpan(child, childStartIndex);
            childStartIndex += child.toPlainText().length;
          }
        }
      }

      _findIgnoreGradientSpan(_textPainter.text!, 0);
    }

    _ignoreGradientWithBoxes(boxes, context, offset);

    return boxes.isNotEmpty;
  }

  void _ignoreGradientWithBoxes(
      List<ui.TextBox> boxes, PaintingContext context, ui.Offset offset) {
    if (boxes.isNotEmpty) {
      for (final ui.TextBox box in boxes) {
        final Rect rect = box.toRect();
        if (!rect.isEmpty) {
          context.canvas.clipRect(
            rect.shift(offset),
            clipOp: ui.ClipOp.difference,
          );
        }
      }
    }
  }

  /// Helper method to actually draw the gradient on the specified rectangle.
  void _drawGradientWithRect(ui.Rect rect, PaintingContext context) {
    if (rect.isEmpty || _gradientConfig == null) {
      return;
    }
    final ui.Shader shader = _gradientConfig!.gradient.createShader(rect);
    final ui.Paint paint = Paint()
      ..shader = shader
      ..blendMode = _gradientConfig!.blendMode;

    // Draw the gradient within the rectangle.
    context.canvas.drawRect(rect, paint);
  }
}
