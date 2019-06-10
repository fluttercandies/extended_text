import 'package:extended_text/src/over_flow_text_span.dart';
import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui show Gradient, Shader, TextBox;
import 'dart:math';

import 'extended_text_typedef.dart';

/// get idea from https://github.com/bytedance/RealRichText about Inline-Image-In-Text
/// update by zmtzawqlp@live.com

/// How overflowing text should be handled.
enum ExtendedTextOverflow {
  /// Clip the overflowing text to fix its container.
  clip,

  /// Fade the overflowing text to transparent.
  fade,

  /// Use an ellipsis to indicate that the text has overflowed.
  ellipsis,
}

const String _kEllipsis = '\u2026';

/// A render object that displays a paragraph of text
class ExtendedRenderParagraph extends RenderBox {
  /// Creates a paragraph render object.
  ///
  /// The [text], [textAlign], [textDirection], [overflow], [softWrap], and
  /// [textScaleFactor] arguments must not be null.
  ///
  /// The [maxLines] property may be null (and indeed defaults to null), but if
  /// it is not null, it must be greater than zero.
  ExtendedRenderParagraph(
    TextSpan text, {
    TextAlign textAlign = TextAlign.start,
    @required TextDirection textDirection,
    bool softWrap = true,
    ExtendedTextOverflow overflow = ExtendedTextOverflow.clip,
    double textScaleFactor = 1.0,
    int maxLines,
    Locale locale,
    OverFlowTextSpan overFlowTextSpan,
    this.onSelectionChanged,
    Color selectionColor,
    TextSelection selection,
  })  : assert(text != null),
        assert(text.debugAssertIsValid()),
        assert(textAlign != null),
        assert(textDirection != null),
        assert(softWrap != null),
        assert(overflow != null),
        assert(textScaleFactor != null),
        assert(maxLines == null || maxLines > 0),
        _handleSpecialText = hasSpecialText(text),
        _softWrap = softWrap,
        _overflow =
            overFlowTextSpan != null ? ExtendedTextOverflow.clip : overflow,
        _oldOverflow = overflow,
        _textPainter = TextPainter(
          text: text,
          textAlign: textAlign,
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          ellipsis: overFlowTextSpan != null
              ? null
              : (overflow == ExtendedTextOverflow.ellipsis ? _kEllipsis : null),
          locale: locale,
        ),
        _overFlowTextSpan = overFlowTextSpan,
        _selectionColor = selectionColor,
        _selection = selection;

  ///TextSelection

  /// Called when the selection changes.
  TextSelectionChangedHandler onSelectionChanged;

  double get preferredLineHeight => _textPainter.preferredLineHeight;

  bool _handleSpecialText = false;
  bool get handleSpecialText => _handleSpecialText;

  List<ui.TextBox> _selectionRects;

  /// The region of text that is selected, if any.
  TextSelection get selection => _selection;
  TextSelection _selection;
  set selection(TextSelection value) {
    if (_selection == value) return;
    _selection = value;
    _selectionRects = null;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The color to use when painting the selection.
  Color get selectionColor => _selectionColor;
  Color _selectionColor;
  set selectionColor(Color value) {
    if (_selectionColor == value) return;
    _selectionColor = value;
    markNeedsPaint();
  }

  /// the custom text over flow TextSpan
  OverFlowTextSpan _overFlowTextSpan;
  final ExtendedTextOverflow _oldOverflow;
  OverFlowTextSpan get overFlowTextSpan => _overFlowTextSpan;
  set overFlowTextSpan(TextSpan value) {
    if (value != _overFlowTextSpan) {
      if (value != null) {
        overflow = ExtendedTextOverflow.clip;
      } else {
        overflow = _oldOverflow;
      }
      _overFlowTextSpan = value;
      markNeedsPaint();
    }
  }

  final TextPainter _textPainter;

  /// The text to display
  TextSpan get text => _textPainter.text;
  set text(TextSpan value) {
    assert(value != null);
    _handleSpecialText = hasSpecialText(value);
    switch (_textPainter.text.compareTo(value)) {
      case RenderComparison.identical:
      case RenderComparison.metadata:
        return;
      case RenderComparison.paint:
        _textPainter.text = value;
        markNeedsPaint();
        markNeedsSemanticsUpdate();
        break;
      case RenderComparison.layout:
        _textPainter.text = value;
        _overflowShader = null;
        markNeedsLayout();
        break;
    }
  }

  /// How the text should be aligned horizontally.
  TextAlign get textAlign => _textPainter.textAlign;
  set textAlign(TextAlign value) {
    assert(value != null);
    if (_textPainter.textAlign == value) return;
    _textPainter.textAlign = value;
    markNeedsPaint();
  }

  /// The directionality of the text.
  ///
  /// This decides how the [TextAlign.start], [TextAlign.end], and
  /// [TextAlign.justify] values of [textAlign] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// This must not be null.
  TextDirection get textDirection => _textPainter.textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textPainter.textDirection == value) return;
    _textPainter.textDirection = value;
    markNeedsLayout();
  }

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was
  /// unlimited horizontal space.
  ///
  /// If [softWrap] is false, [overflow] and [textAlign] may have unexpected
  /// effects.
  bool get softWrap => _softWrap;
  bool _softWrap;
  set softWrap(bool value) {
    assert(value != null);
    if (_softWrap == value) return;
    _softWrap = value;
    markNeedsLayout();
  }

  /// How visual overflow should be handled.
  ExtendedTextOverflow get overflow => _overflow;
  ExtendedTextOverflow _overflow;
  set overflow(ExtendedTextOverflow value) {
    assert(value != null);
    if (_overflow == value) return;
    _overflow = value;
    _textPainter.ellipsis =
        value == ExtendedTextOverflow.ellipsis ? _kEllipsis : null;
    markNeedsLayout();
  }

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  double get textScaleFactor => _textPainter.textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (_textPainter.textScaleFactor == value) return;
    _textPainter.textScaleFactor = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow] and [softWrap].
  int get maxLines => _textPainter.maxLines;

  /// The value may be null. If it is not null, then it must be greater than zero.
  set maxLines(int value) {
    assert(value == null || value > 0);
    if (_textPainter.maxLines == value) return;
    _textPainter.maxLines = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  /// Used by this paragraph's internal [TextPainter] to select a locale-specific
  /// font.
  ///
  /// In some cases the same Unicode character may be rendered differently depending
  /// on the locale. For example the '骨' character is rendered differently in
  /// the Chinese and Japanese locales. In these cases the [locale] may be used
  /// to select a locale-specific font.
  Locale get locale => _textPainter.locale;

  /// The value may be null.
  set locale(Locale value) {
    if (_textPainter.locale == value) return;
    _textPainter.locale = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  void _layoutText({double minWidth = 0.0, double maxWidth = double.infinity}) {
    final bool widthMatters =
        softWrap || overflow == ExtendedTextOverflow.ellipsis;
    _textPainter.layout(
        minWidth: minWidth,
        maxWidth: widthMatters ? maxWidth : double.infinity);
  }

  void _layoutTextWithConstraints(BoxConstraints constraints) {
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _layoutText();
    return _textPainter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _layoutText();
    return _textPainter.maxIntrinsicWidth;
  }

  double _computeIntrinsicHeight(double width) {
    _layoutText(minWidth: width, maxWidth: width);
    return _textPainter.height;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
    assert(constraints != null);
    assert(constraints.debugAssertIsValid());
    _layoutTextWithConstraints(constraints);
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is! PointerDownEvent) return;
    _layoutTextWithConstraints(constraints);
    final Offset offset = entry.localPosition;
    if (_hasVisualOverflow && overFlowTextSpan != null) {
      final TextPosition position =
          overFlowTextSpan.textPainterHelper.getPositionForOffset(offset);
      final TextSpan span =
          overFlowTextSpan.textPainterHelper.getSpanForPosition(position);

      if (span?.recognizer != null) {
        span.recognizer.addPointer(event);
        return;
      }
    }

    final TextPosition position = _textPainter.getPositionForOffset(offset);
    final TextSpan span = _textPainter.text.getSpanForPosition(position);
    span?.recognizer?.addPointer(event);
  }

  bool _hasVisualOverflow = false;
  ui.Shader _overflowShader;

  /// Whether this paragraph currently has a [dart:ui.Shader] for its overflow
  /// effect.
  ///
  /// Used to test this object. Not for use in production.
  @visibleForTesting
  bool get debugHasOverflowShader => _overflowShader != null;

  @override
  void performLayout() {
    _layoutTextWithConstraints(constraints);
    // We grab _textPainter.size here because assigning to `size` will trigger
    // us to validate our intrinsic sizes, which will change _textPainter's
    // layout because the intrinsic size calculations are destructive.
    // Other _textPainter state like didExceedMaxLines will also be affected.
    // See also RenderEditable which has a similar issue.
    final Size textSize = _textPainter.size;
    final bool didOverflowHeight = _textPainter.didExceedMaxLines;
    size = constraints.constrain(textSize);

    final bool didOverflowWidth = size.width < textSize.width;
    // TODO(abarth): We're only measuring the sizes of the line boxes here. If
    // the glyphs draw outside the line boxes, we might think that there isn't
    // visual overflow when there actually is visual overflow. This can become
    // a problem if we start having horizontal overflow and introduce a clip
    // that affects the actual (but undetected) vertical overflow.
    _hasVisualOverflow = didOverflowWidth || didOverflowHeight;
    if (_hasVisualOverflow) {
      switch (_overflow) {
        case ExtendedTextOverflow.clip:
        case ExtendedTextOverflow.ellipsis:
          _overflowShader = null;
          break;
        case ExtendedTextOverflow.fade:
          assert(textDirection != null);
          final TextPainter fadeSizePainter = TextPainter(
            text: TextSpan(style: _textPainter.text.style, text: '\u2026'),
            textDirection: textDirection,
            textScaleFactor: textScaleFactor,
            locale: locale,
          )..layout();
          if (didOverflowWidth) {
            double fadeEnd, fadeStart;
            switch (textDirection) {
              case TextDirection.rtl:
                fadeEnd = 0.0;
                fadeStart = fadeSizePainter.width;
                break;
              case TextDirection.ltr:
                fadeEnd = size.width;
                fadeStart = fadeEnd - fadeSizePainter.width;
                break;
            }
            _overflowShader = ui.Gradient.linear(
              Offset(fadeStart, 0.0),
              Offset(fadeEnd, 0.0),
              <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
            );
          } else {
            final double fadeEnd = size.height;
            final double fadeStart = fadeEnd - fadeSizePainter.height / 2.0;
            _overflowShader = ui.Gradient.linear(
              Offset(0.0, fadeStart),
              Offset(0.0, fadeEnd),
              <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
            );
          }
          break;
      }
    } else {
      _overflowShader = null;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintSelection(context, offset);
    _paintSpecialText(context, offset);
    _paint(context, offset);
    _paintTextOverflow(context, offset);
  }

  void _paint(PaintingContext context, Offset offset) {
    // Ideally we could compute the min/max intrinsic width/height with a
    // non-destructive operation. However, currently, computing these values
    // will destroy state inside the painter. If that happens, we need to
    // get back the correct state by calling _layout again.
    //
    // TODO(abarth): Make computing the min/max intrinsic width/height
    // a non-destructive operation.
    //
    // If you remove this call, make sure that changing the textAlign still
    // works properly.
    _layoutTextWithConstraints(constraints);
    final Canvas canvas = context.canvas;

    assert(() {
      if (debugRepaintTextRainbowEnabled) {
        final Paint paint = Paint()..color = debugCurrentRepaintColor.toColor();
        canvas.drawRect(offset & size, paint);
      }
      return true;
    }());

    if (_hasVisualOverflow) {
      final Rect bounds = offset & size;
      if (_overflowShader != null) {
        // This layer limits what the shader below blends with to be just the text
        // (as opposed to the text and its background).
        canvas.saveLayer(bounds, Paint());
      } else {
        canvas.save();
      }
      canvas.clipRect(bounds);
    }
    _textPainter.paint(canvas, offset);

    if (_hasVisualOverflow) {
      if (_overflowShader != null) {
        canvas.translate(offset.dx, offset.dy);
        final Paint paint = Paint()
          ..blendMode = BlendMode.modulate
          ..shader = _overflowShader;
        canvas.drawRect(Offset.zero & size, paint);
      }
      canvas.restore();
    }
  }

  /// Returns the offset at which to paint the caret.
  ///
  /// Valid only after [layout].
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getOffsetForCaret(position, caretPrototype);
  }

  /// Returns a list of rects that bound the given selection.
  ///
  /// A given selection might have more than one rect if this text painter
  /// contains bidirectional text because logically contiguous text might not be
  /// visually contiguous.
  ///
  /// Valid only after [layout].
  List<ui.TextBox> getBoxesForSelection(TextSelection selection) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getBoxesForSelection(selection);
  }

  /// Returns the position within the text for the given pixel offset.
  ///
  /// Valid only after [layout].
  TextPosition getPositionForOffset(Offset offset) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getPositionForOffset(offset);
  }

  /// Returns the text range of the word at the given offset. Characters not
  /// part of a word, such as spaces, symbols, and punctuation, have word breaks
  /// on both sides. In such cases, this method will return a text range that
  /// contains the given text position.
  ///
  /// Word boundaries are defined more precisely in Unicode Standard Annex #29
  /// <http://www.unicode.org/reports/tr29/#Word_Boundaries>.
  ///
  /// Valid only after [layout].
  TextRange getWordBoundary(TextPosition position) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getWordBoundary(position);
  }

  /// Returns the size of the text as laid out.
  ///
  /// This can differ from [size] if the text overflowed or if the [constraints]
  /// provided by the parent [RenderObject] forced the layout to be bigger than
  /// necessary for the given [text].
  ///
  /// This returns the [TextPainter.size] of the underlying [TextPainter].
  ///
  /// Valid only after [layout].
  Size get textSize {
    assert(!debugNeedsLayout);
    return _textPainter.size;
  }

  final List<int> _recognizerOffsets = <int>[];
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    _recognizerOffsets.clear();
    _recognizers.clear();
    int offset = 0;
    text.visitTextSpan((TextSpan span) {
      if (span.recognizer != null &&
          (span.recognizer is TapGestureRecognizer ||
              span.recognizer is LongPressGestureRecognizer)) {
        _recognizerOffsets.add(offset);
        _recognizerOffsets.add(offset + span.text.length);
        _recognizers.add(span.recognizer);
      }
      offset += span.text.length;
      return true;
    });
    if (_recognizerOffsets.isNotEmpty) {
      config.explicitChildNodes = true;
      config.isSemanticBoundary = true;
    } else {
      config.label = text.toPlainText();
      config.textDirection = textDirection;
    }
  }

  @override
  void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config,
      Iterable<SemanticsNode> children) {
    assert(_recognizerOffsets.isNotEmpty);
    assert(_recognizerOffsets.length.isEven);
    assert(_recognizers.isNotEmpty);
    assert(children.isEmpty);
    final List<SemanticsNode> newChildren = <SemanticsNode>[];
    final String rawLabel = text.toPlainText();
    int current = 0;
    double order = -1.0;
    TextDirection currentDirection = textDirection;
    Rect currentRect;

    SemanticsConfiguration buildSemanticsConfig(int start, int end) {
      final TextDirection initialDirection = currentDirection;
      final TextSelection selection =
          TextSelection(baseOffset: start, extentOffset: end);
      final List<ui.TextBox> rects = getBoxesForSelection(selection);
      Rect rect;
      for (ui.TextBox textBox in rects) {
        rect ??= textBox.toRect();
        rect = rect.expandToInclude(textBox.toRect());
        currentDirection = textBox.direction;
      }
      // round the current rectangle to make this API testable and add some
      // padding so that the accessibility rects do not overlap with the text.
      // TODO(jonahwilliams): implement this for all text accessibility rects.
      currentRect = Rect.fromLTRB(
        rect.left.floorToDouble() - 4.0,
        rect.top.floorToDouble() - 4.0,
        rect.right.ceilToDouble() + 4.0,
        rect.bottom.ceilToDouble() + 4.0,
      );
      order += 1;
      return SemanticsConfiguration()
        ..sortKey = OrdinalSortKey(order)
        ..textDirection = initialDirection
        ..label = rawLabel.substring(start, end);
    }

    for (int i = 0, j = 0; i < _recognizerOffsets.length; i += 2, j++) {
      final int start = _recognizerOffsets[i];
      final int end = _recognizerOffsets[i + 1];
      if (current != start) {
        final SemanticsNode node = SemanticsNode();
        final SemanticsConfiguration configuration =
            buildSemanticsConfig(current, start);
        node.updateWith(config: configuration);
        node.rect = currentRect;
        newChildren.add(node);
      }
      final SemanticsNode node = SemanticsNode();
      final SemanticsConfiguration configuration =
          buildSemanticsConfig(start, end);
      final GestureRecognizer recognizer = _recognizers[j];
      if (recognizer is TapGestureRecognizer) {
        configuration.onTap = recognizer.onTap;
      } else if (recognizer is LongPressGestureRecognizer) {
        configuration.onLongPress = recognizer.onLongPress;
      } else {
        assert(false);
      }
      node.updateWith(config: configuration);
      node.rect = currentRect;
      newChildren.add(node);
      current = end;
    }
    if (current < rawLabel.length) {
      final SemanticsNode node = SemanticsNode();
      final SemanticsConfiguration configuration =
          buildSemanticsConfig(current, rawLabel.length);
      node.updateWith(config: configuration);
      node.rect = currentRect;
      newChildren.add(node);
    }
    node.updateWith(config: config, childrenInInversePaintOrder: newChildren);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      text.toDiagnosticsNode(
          name: 'text', style: DiagnosticsTreeStyle.transition)
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
    properties.add(FlagProperty('softWrap',
        value: softWrap,
        ifTrue: 'wrapping at box width',
        ifFalse: 'no wrapping except at line break characters',
        showName: true));
    properties.add(EnumProperty<ExtendedTextOverflow>('overflow', overflow));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
    properties
        .add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, ifNull: 'unlimited'));
  }

  @override
  void detach() {
    // TODO: implement detach
    super.detach();
    _disposeImageSpan(<TextSpan>[text]);
  }

  void _disposeImageSpan(List<TextSpan> textSpan) {
    textSpan.forEach((ts) {
      if (ts is ImageSpan) {
        ts.dispose();
      } else if (ts.children != null) {
        _disposeImageSpan(ts.children);
      }
    });
  }

  void _paintSpecialText(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    canvas.save();

    ///move to extended text
    canvas.translate(offset.dx, offset.dy);

    ///we have move the canvas, so rect top left should be (0,0)
    final Rect rect = Offset(0.0, 0.0) & size;
    _paintSpecialTextChildren(<TextSpan>[text], canvas, rect);
    canvas.restore();
  }

  void _paintSpecialTextChildren(
      List<TextSpan> textSpans, Canvas canvas, Rect rect,
      {int textOffset: 0}) {
    for (TextSpan ts in textSpans) {
      Offset topLeftOffset = getOffsetForCaret(
        TextPosition(offset: textOffset),
        rect,
      );
      //skip invalid or overflow
      if (topLeftOffset == null ||
          (textOffset != 0 && topLeftOffset == Offset.zero)) {
        return;
      }

      if (ts is ImageSpan) {
        ///imageSpanTransparentPlaceholder \u200B has no width, and we define image width by
        ///use letterSpacing,so the actual top-left offset of image should be subtract letterSpacing(width)/2.0
        Offset imageSpanOffset = topLeftOffset - Offset(ts.width / 2.0, 0.0);

        if (!ts.paint(canvas, imageSpanOffset)) {
          //image not ready
          ts.resolveImage(
              listener: (ImageInfo imageInfo, bool synchronousCall) {
            if (synchronousCall)
              ts.paint(canvas, imageSpanOffset);
            else {
              if (owner == null || !owner.debugDoingPaint) {
                markNeedsPaint();
              }
            }
          });
        }
      } else if (ts is BackgroundTextSpan) {
        var painter = ts.layout(_textPainter);
        Rect textRect = topLeftOffset & painter.size;
        Offset endOffset;
        if (textRect.right > rect.right) {
          int endTextOffset = textOffset + ts.toPlainText().length;
          endOffset = _findEndOffset(rect, endTextOffset);
        }

        ts.paint(canvas, topLeftOffset, rect,
            endOffset: endOffset, wholeTextPainter: _textPainter);
      } else if (ts.children != null) {
        _paintSpecialTextChildren(ts.children, canvas, rect,
            textOffset: textOffset);
      }
      textOffset += ts.toPlainText().length;
    }
  }

  Offset _findEndOffset(Rect rect, int endTextOffset) {
    Offset endOffset = getOffsetForCaret(
      TextPosition(offset: endTextOffset, affinity: TextAffinity.upstream),
      rect,
    );
    //overflow
    if (endOffset == null || (endTextOffset != 0 && endOffset == Offset.zero)) {
      return _findEndOffset(rect, endTextOffset - 1);
    }
    return endOffset;
  }

  void _paintTextOverflow(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow && overFlowTextSpan != null) {
      final Canvas canvas = context.canvas;

      ///we will move the canvas, so rect top left should be (0,0)
      final Rect rect = Offset(0.0, 0.0) & size;
      var textPainter = overFlowTextSpan.layout(_textPainter);

      //overFlowTextSpan can't be more one line.
      assert(
        textPainter.width <= rect.width,
      );

      canvas.save();

      ///move to extended text
      canvas.translate(offset.dx, offset.dy);

      final Offset overFlowTextSpanOffset = Offset(
          rect.width - textPainter.width, rect.height - textPainter.height);

      ///find TextPosition near bottomRight
      TextPosition lastOnePosition = getPositionForOffset(rect.bottomRight);

      final TextSpan lastTextSpan =
          _textPainter.text.getSpanForPosition(lastOnePosition);

      ///find overflow TextPosition that not clip the original text
      Offset finalOverflowOffset = _findFinalOverflowOffset(
          rect: rect,
          x: rect.width - textPainter.width,
          endTextOffset: lastOnePosition.offset,
          y: rect.bottom);

      Offset bottomRight = rect.bottomRight;
      if (lastTextSpan is ImageSpan) {
        bottomRight =
            Offset(bottomRight.dx + lastTextSpan.width / 2.0, bottomRight.dy);
      }
      final Rect overFlowTextSpanRect =
          Rect.fromPoints(finalOverflowOffset, bottomRight);

      canvas.drawRect(
          overFlowTextSpanRect, Paint()..color = overFlowTextSpan.background);

      ///why BlendMode.clear not clear the text
//      canvas.saveLayer(overFlowTextSpanRect, Paint());
//      canvas.drawRect(
//          overFlowTextSpanRect,
//          Paint()
//            ..blendMode = BlendMode.clear);
//      canvas.restore();

      textPainter.paint(
          canvas, Offset(finalOverflowOffset.dx, overFlowTextSpanOffset.dy));

      overFlowTextSpan.textPainterHelper.saveOffset(Offset(
          offset.dx + finalOverflowOffset.dx,
          offset.dy + overFlowTextSpanOffset.dy));

      canvas.restore();
    }
  }

  /// y find min y, so that over flow text will be covered
  Offset _findFinalOverflowOffset(
      {Rect rect, double x, int endTextOffset, double y}) {
    Offset endOffset = getOffsetForCaret(
      TextPosition(offset: endTextOffset),
      rect,
    );
    final TextPosition position = getPositionForOffset(endOffset);

    ///handle image span
    final TextSpan textSpan = _textPainter.text.getSpanForPosition(position);
    if (textSpan is ImageSpan) {
      endOffset = Offset(endOffset.dx - textSpan.width / 2.0, endOffset.dy);

      if (textSpan.margin != null) {
        endOffset =
            endOffset + Offset(textSpan.margin.left, textSpan.margin.top);
      }
    }
    //overflow
    if (endOffset == null || (endTextOffset != 0 && endOffset == Offset.zero)) {
      return _findFinalOverflowOffset(
          rect: rect, x: x, endTextOffset: endTextOffset - 1, y: y);
    }

    if (endOffset.dx > x) {
      return _findFinalOverflowOffset(
          rect: rect,
          x: x,
          endTextOffset: endTextOffset - 1,
          y: min(y, endOffset.dy));
    }
    return Offset(endOffset.dx, min(y, endOffset.dy));
  }

  ///selection

  Offset _lastTapDownPosition;

  ///
  ///Offset _lastTapDownPosition;

  /// If [ignorePointer] is false (the default) then this method is called by
  /// the internal gesture recognizer's [TapGestureRecognizer.onTapDown]
  /// callback.
  ///
  /// When [ignorePointer] is true, an ancestor widget must respond to tap
  /// down events by calling this method.
  void handleTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition;
  }

  /// Selects the set words of a paragraph in a given range of global positions.
  ///
  /// The first and last endpoints of the selection will always be at the
  /// beginning and end of a word respectively.
  ///
  /// {@macro flutter.rendering.editable.select}
  void selectWordsInRange(
      {@required Offset from,
      Offset to,
      @required SelectionChangedCause cause}) {
    assert(cause != null);
    assert(from != null);
    _layoutTextWithConstraints(constraints);
    if (onSelectionChanged != null) {
      final TextPosition firstPosition =
          _textPainter.getPositionForOffset(globalToLocal(from));

      final TextSelection firstWord = _selectWordAtOffset(firstPosition);
      final TextSelection lastWord = to == null
          ? firstWord
          : _selectWordAtOffset(
              _textPainter.getPositionForOffset(globalToLocal(to)));

      onSelectionChanged(
        TextSelection(
          baseOffset: firstWord.base.offset,
          extentOffset: lastWord.extent.offset,
          affinity: firstWord.affinity,
        ),
        this,
        cause,
      );
    }
  }

  TextSelection _selectWordAtOffset(TextPosition position) {
    ///zmt
    final TextRange word = _textPainter.getWordBoundary(position);
    TextSelection selection;
    // When long-pressing past the end of the text, we want a collapsed cursor.
    if (position.offset >= word.end) {
      selection = TextSelection.fromPosition(position);
    } else {
      selection = TextSelection(baseOffset: word.start, extentOffset: word.end);
    }
    return handleSpecialText
        ? convertTextPainterSelectionToTextInputSelection(text, selection)
        : selection;
//    if (position.offset >= word.end)
//      return TextSelection.fromPosition(position);
//    return TextSelection(baseOffset: word.start, extentOffset: word.end);
  }

  /// Move the selection to the beginning or end of a word.
  ///
  /// {@macro flutter.rendering.editable.select}
  void selectWordEdge({@required SelectionChangedCause cause}) {
    assert(cause != null);
    _layoutTextWithConstraints(constraints);
    assert(_lastTapDownPosition != null);
    if (onSelectionChanged != null) {
      final TextPosition position = _textPainter
          .getPositionForOffset(globalToLocal(_lastTapDownPosition));

      final TextRange word = _textPainter.getWordBoundary(position);
      TextSelection selection;

      ///zmt
      if (position.offset - word.start <= 1) {
        selection = handleSpecialText
            ? convertTextPainterSelectionToTextInputSelection(
                text,
                TextSelection.collapsed(
                    offset: word.start, affinity: TextAffinity.downstream))
            : TextSelection.collapsed(
                offset: word.start, affinity: TextAffinity.downstream);
      } else {
        selection = handleSpecialText
            ? convertTextPainterSelectionToTextInputSelection(
                text,
                TextSelection.collapsed(
                    offset: word.end, affinity: TextAffinity.upstream))
            : TextSelection.collapsed(
                offset: word.end, affinity: TextAffinity.upstream);
      }
      onSelectionChanged(
        selection,
        this,
        cause,
      );
    }
  }

  /// Move selection to the location of the last tap down.
  ///
  /// {@template flutter.rendering.editable.select}
  /// This method is mainly used to translate user inputs in global positions
  /// into a [TextSelection]. When used in conjunction with a [EditableText],
  /// the selection change is fed back into [TextEditingController.selection].
  ///
  /// If you have a [TextEditingController], it's generally easier to
  /// programmatically manipulate its `value` or `selection` directly.
  /// {@endtemplate}
  void selectPosition({@required SelectionChangedCause cause}) {
    selectPositionAt(from: _lastTapDownPosition, cause: cause);
  }

  /// Select text between the global positions [from] and [to].
  void selectPositionAt(
      {@required Offset from,
      Offset to,
      @required SelectionChangedCause cause}) {
    assert(cause != null);
    assert(from != null);
    _layoutTextWithConstraints(constraints);
    if (onSelectionChanged != null) {
      TextPosition fromPosition =
          _textPainter.getPositionForOffset(globalToLocal(from));
      TextPosition toPosition = to == null
          ? null
          : _textPainter.getPositionForOffset(globalToLocal(to));

      //zmt
      if (handleSpecialText) {
        fromPosition =
            convertTextPainterPostionToTextInputPostion(text, fromPosition);
        toPosition =
            convertTextPainterPostionToTextInputPostion(text, toPosition);
      }

      int baseOffset = fromPosition.offset;
      int extentOffset = fromPosition.offset;

      if (toPosition != null) {
        baseOffset = min(fromPosition.offset, toPosition.offset);
        extentOffset = max(fromPosition.offset, toPosition.offset);
      }

      final TextSelection newSelection = TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
        affinity: fromPosition.affinity,
      );
      // Call [onSelectionChanged] only when the selection actually changed.
      if (newSelection != _selection) {
        onSelectionChanged(newSelection, this, cause);
      }
    }
  }

  /// Select a word around the location of the last tap down.
  ///
  /// {@macro flutter.rendering.editable.select}
  void selectWord({@required SelectionChangedCause cause}) {
    selectWordsInRange(from: _lastTapDownPosition, cause: cause);
  }

  void _paintSelection(PaintingContext context, Offset effectiveOffset) {
    if (_selection == null) return;
    bool showSelection = false;

    ///zmt
    var actualSelection = handleSpecialText
        ? convertTextInputSelectionToTextPainterSelection(text, _selection)
        : _selection;

    if (!actualSelection.isCollapsed && _selectionColor != null) {
      showSelection = true;
      _updateSelectionExtentsVisibility(effectiveOffset, actualSelection);
    }

    if (showSelection) {
      _selectionRects ??= _textPainter.getBoxesForSelection(actualSelection);

      int textOffset = 0;
      Map<Offset, ImageSpan> imageSpans = Map<Offset, ImageSpan>();

      ///zmt
      ///find all image span in selection
      if (handleSpecialText) {
        if (text != null && text.children != null) {
          for (TextSpan ts in text.children) {
            if (textOffset >= actualSelection.start &&
                textOffset <= actualSelection.end) {
              if (ts is ImageSpan) {
                var offset = _textPainter.getOffsetForCaret(
                  TextPosition(offset: textOffset),
                  effectiveOffset & size,
                );
                imageSpans[offset] = ts;
              }
            }
            textOffset += ts.toPlainText().length;
            if (textOffset > actualSelection.end) {
              break;
            }
          }
        }
      }

      _paintInnerSelection(context.canvas, effectiveOffset, imageSpans);
    }
  }

  void _paintInnerSelection(Canvas canvas, Offset effectiveOffset,
      Map<Offset, ImageSpan> imageSpans) {
    assert(_selectionRects != null);
    final Paint paint = Paint()..color = _selectionColor;

    ///zmt
    for (int i = 0; i < _selectionRects.length; i++) {
      var box = _selectionRects[i];
      var rect = box.toRect();
      if (handleSpecialText) {
        ImageSpan textSpan = imageSpans[Offset(box.left, box.top)];

//      var textPosition =
//          _textPainter.getPositionForOffset(Offset(box.left, box.top));
//      var textSpan = text.getSpanForPosition(textPosition);

        ///fix image span position
        if (textSpan != null) {
          ///move left only
//        if (textSpan.width < rect.width) {
//          rect = Rect.fromLTRB(rect.left - textSpan.width / 2.0, rect.top,
//              rect.right, rect.bottom);
//        }
//        //move all rect
//        else
          {
            rect = rect.shift(Offset(
                -getImageSpanCorrectPosition(textSpan, textDirection), 0.0));
          }
        }
      }
      canvas.drawRect(rect.shift(effectiveOffset), paint);
    }
  }

  /// Returns the local coordinates of the endpoints of the given selection.
  ///
  /// If the selection is collapsed (and therefore occupies a single point), the
  /// returned list is of length one. Otherwise, the selection is not collapsed
  /// and the returned list is of length two. In this case, however, the two
  /// points might actually be co-located (e.g., because of a bidirectional
  /// selection that contains some text but whose ends meet in the middle).
  ///
  /// See also:
  ///
  ///  * [getLocalRectForCaret], which is the equivalent but for
  ///    a [TextPosition] rather than a [TextSelection].
  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection) {
    assert(constraints != null);
    _layoutTextWithConstraints(constraints);

    //final Offset paintOffset = _paintOffset;
    ///zmt
    final Offset effectiveOffset = Offset.zero;

    var temp = convertTextInputSelectionToTextPainterSelection(text, selection);

//    if (temp.isCollapsed) {
//      // TODO(mpcomplete): This doesn't work well at an RTL/LTR boundary.
////      final Offset caretOffset =
////          _textPainter.getOffsetForCaret(temp.extent, _caretPrototype);
//
//      final Offset caretOffset = _getCaretOffset(
//          effectiveOffset,
//          TextPosition(offset: temp.extentOffset, affinity: selection.affinity),
//          TextPosition(
//              offset: selection.extentOffset, affinity: selection.affinity));
//
//      final Offset start = Offset(0.0, preferredLineHeight) + caretOffset;
//
//      return <TextSelectionPoint>[TextSelectionPoint(start, null)];
//    } else
    if (!temp.isCollapsed) {
      final Offset start = Offset(0.0, preferredLineHeight) +
          _getCaretOffset(
              effectiveOffset,
              TextPosition(
                  offset: temp.baseOffset, affinity: selection.affinity),
              TextPosition(
                  offset: selection.baseOffset, affinity: selection.affinity));
      final Offset end = Offset(0.0, preferredLineHeight) +
          _getCaretOffset(
              effectiveOffset,
              TextPosition(
                  offset: temp.extentOffset, affinity: selection.affinity),
              TextPosition(
                  offset: selection.extentOffset,
                  affinity: selection.affinity));

      return <TextSelectionPoint>[
        TextSelectionPoint(start, TextDirection.ltr),
        TextSelectionPoint(end, TextDirection.ltr),
      ];

//      final List<ui.TextBox> boxes = _textPainter.getBoxesForSelection(temp);
//      final Offset start =
//          Offset(boxes.first.start, boxes.first.bottom) + paintOffset;
//      final Offset end =
//          Offset(boxes.last.end, boxes.last.bottom) + paintOffset;
//
//      return <TextSelectionPoint>[
//        TextSelectionPoint(start, boxes.first.direction),
//        TextSelectionPoint(end, boxes.last.direction),
//      ];
    }
  }

  Offset _getCaretOffset(Offset effectiveOffset, TextPosition textPosition,
      TextPosition textInputPosition) {
    ///zmt
    double imageTextSpanWidth = 0.0;
    Offset imageSpanEndCaretOffset;
    if (handleSpecialText) {
      var textSpan = text.getSpanForPosition(textPosition);
      if (textSpan != null) {
        if (textSpan is ImageSpan) {
          if (textInputPosition.offset >= textSpan.start &&
              textInputPosition.offset < textSpan.end) {
            imageTextSpanWidth -=
                getImageSpanCorrectPosition(textSpan, textDirection);
          } else if (textInputPosition.offset == textSpan.end) {
            var preTextPosition = TextPosition(
                offset: textPosition.offset - 1,
                affinity: textPosition.affinity);
            var preTextSpan = text.getSpanForPosition(preTextPosition);
            if (preTextSpan != null && preTextSpan is ImageSpan) {
              ///_textPainter.getOffsetForCaret is not right.
              imageSpanEndCaretOffset = _textPainter.getOffsetForCaret(
                    preTextPosition,
                    effectiveOffset & size,
                  ) +
                  Offset(getImageSpanCorrectPosition(textSpan, textDirection),
                      0.0);
            } else {
              imageTextSpanWidth -=
                  getImageSpanCorrectPosition(textSpan, textDirection);
            }
          }
        }
      } else {
        //handle image text span is last one, textPainter will get wrong offset
        //last one
        textSpan = text.children?.last;
        if (textSpan != null &&
            textSpan is ImageSpan &&
            textInputPosition.offset >= textSpan.start) {
          imageSpanEndCaretOffset = _textPainter.getOffsetForCaret(
                TextPosition(
                    offset: textPosition.offset - 1,
                    affinity: textPosition.affinity),
                effectiveOffset & size,
              ) +
              Offset(getImageSpanCorrectPosition(textSpan, textDirection), 0.0);
        }
      }
    }

    final Offset caretOffset = (imageSpanEndCaretOffset ??
            _textPainter.getOffsetForCaret(textPosition, _caretPrototype) +
                Offset(imageTextSpanWidth, 0.0)) +
        effectiveOffset;
    return caretOffset;
  }

  Rect _caretPrototype = Rect.zero;

  /// Track whether position of the start of the selected text is within the viewport.
  ///
  /// For example, if the text contains "Hello World", and the user selects
  /// "Hello", then scrolls so only "World" is visible, this will become false.
  /// If the user scrolls back so that the "H" is visible again, this will
  /// become true.
  ///
  /// This bool indicates whether the text is scrolled so that the handle is
  /// inside the text field viewport, as opposed to whether it is actually
  /// visible on the screen.
  ValueListenable<bool> get selectionStartInViewport =>
      _selectionStartInViewport;
  final ValueNotifier<bool> _selectionStartInViewport =
      ValueNotifier<bool>(true);

  /// Track whether position of the end of the selected text is within the viewport.
  ///
  /// For example, if the text contains "Hello World", and the user selects
  /// "World", then scrolls so only "Hello" is visible, this will become
  /// 'false'. If the user scrolls back so that the "d" is visible again, this
  /// will become 'true'.
  ///
  /// This bool indicates whether the text is scrolled so that the handle is
  /// inside the text field viewport, as opposed to whether it is actually
  /// visible on the screen.
  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

  TextPosition getPositionForPoint(Offset globalPosition) {
    _layoutTextWithConstraints(constraints);
    return _textPainter.getPositionForOffset(globalToLocal(globalPosition));
  }

  void _updateSelectionExtentsVisibility(
      Offset effectiveOffset, TextSelection selection) {
    ///final Rect visibleRegion = Offset.zero & size;

    ///zmt
    ///caret may be less than 0, because it's bigger than text
    ///

    final Rect visibleRegion = Offset.zero & size;

    final Offset startOffset = _textPainter.getOffsetForCaret(
      TextPosition(offset: selection.start, affinity: selection.affinity),
      Rect.zero,
    );

    _selectionStartInViewport.value =
        visibleRegion.contains(startOffset + effectiveOffset);

    final Offset endOffset = _textPainter.getOffsetForCaret(
      TextPosition(offset: selection.end, affinity: selection.affinity),
      Rect.zero,
    );

    _selectionEndInViewport.value =
        visibleRegion.contains(endOffset + effectiveOffset);
  }

  bool containsPosition(Offset position) {
    final Rect visibleRegion = Offset.zero & size;
    return visibleRegion.contains(globalToLocal(position));
  }
}
