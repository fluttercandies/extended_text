import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui
    show
        Gradient,
        Shader,
        TextBox,
        TextHeightBehavior,
        BoxWidthStyle,
        BoxHeightStyle;
import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'text_overflow_widget.dart';
part 'text_overflow_render_mixin.dart';

const String _kEllipsis = '\u2026';

/// A render object that displays a paragraph of text
class ExtendedRenderParagraph extends ExtendedTextSelectionRenderObject
    with TextOverflowMixin {
  /// Creates a paragraph render object.
  ///
  /// The [text], [textAlign], [textDirection], [overflow], [softWrap], and
  /// [textScaleFactor] arguments must not be null.
  ///
  /// The [maxLines] property may be null (and indeed defaults to null), but if
  /// it is not null, it must be greater than zero.
  ExtendedRenderParagraph(
    InlineSpan text, {
    TextAlign textAlign = TextAlign.start,
    required TextDirection textDirection,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    double textScaleFactor = 1.0,
    int? maxLines,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    Locale? locale,
    required LayerLink? startHandleLayerLink,
    required LayerLink? endHandleLayerLink,
    Color? selectionColor,
    TextSelection? selection,
    StrutStyle? strutStyle,
    List<RenderBox>? children,
    ui.TextHeightBehavior? textHeightBehavior,
    ui.BoxHeightStyle selectionHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle selectionWidthStyle = ui.BoxWidthStyle.tight,
    TextOverflowWidget? overflowWidget,
    this.textSelectionDelegate,
    bool? hasFocus,
  })  : assert(text.debugAssertIsValid()),
        assert(maxLines == null || maxLines > 0),
        _softWrap = softWrap,
        oldOverflow = overflow,
        _startHandleLayerLink = startHandleLayerLink,
        _endHandleLayerLink = endHandleLayerLink,
        _rawText = text,
        _textPainter = TextPainter(
          text: text,
          textAlign: textAlign,
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          ellipsis:
              (overflowWidget == null && overflow == TextOverflow.ellipsis)
                  ? _kEllipsis
                  : null,
          locale: locale,
          strutStyle: strutStyle,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
        ),
        _selectionColor = selectionColor,
        _selection = selection,
        _selectionHeightStyle = selectionHeightStyle,
        _selectionWidthStyle = selectionWidthStyle {
    this.hasFocus = hasFocus ?? false;
    _overflow = overflowWidget != null ? TextOverflow.clip : overflow;
    _overflowWidget = overflowWidget;
    addAll(children);
    extractPlaceholderSpans(text);
  }

  @override
  double get preferredLineHeight => _textPainter.preferredLineHeight;

  List<ui.TextBox>? _selectionRects;

  /// The [LayerLink] of start selection handle.
  ///
  /// [RenderEditable] is responsible for calculating the [Offset] of this
  /// [LayerLink], which will be used as [CompositedTransformTarget] of start handle.
  @override
  LayerLink? get startHandleLayerLink => _startHandleLayerLink;
  LayerLink? _startHandleLayerLink;
  @override
  set startHandleLayerLink(LayerLink? value) {
    if (_startHandleLayerLink == value) {
      return;
    }
    _startHandleLayerLink = value;
    markNeedsPaint();
  }

  /// The [LayerLink] of end selection handle.
  ///
  /// [RenderEditable] is responsible for calculating the [Offset] of this
  /// [LayerLink], which will be used as [CompositedTransformTarget] of end handle.
  @override
  LayerLink? get endHandleLayerLink => _endHandleLayerLink;
  LayerLink? _endHandleLayerLink;
  @override
  set endHandleLayerLink(LayerLink? value) {
    if (_endHandleLayerLink == value) {
      return;
    }
    _endHandleLayerLink = value;
    markNeedsPaint();
  }

  /// The region of text that is selected, if any.
  @override
  TextSelection? get selection => _selection;
  TextSelection? _selection;
  @override
  set selection(TextSelection? value) {
    if (_selection == value) {
      return;
    }
    _selection = value;
    _selectionRects = null;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The color to use when painting the selection.
  @override
  Color? get selectionColor => _selectionColor;
  Color? _selectionColor;
  @override
  set selectionColor(Color? value) {
    if (_selectionColor == value) {
      return;
    }
    _selectionColor = value;
    markNeedsPaint();
  }

  final TextPainter _textPainter;

  /// The text to display
  @override
  InlineSpan get text => _textPainter.text!;

  /// store raw text in case raw text may changed by _findNoOverflow.
  /// but we don't need layout any more.
  InlineSpan? _rawText;
  set text(InlineSpan value) {
    switch ((_rawText ?? _textPainter.text!).compareTo(value)) {
      case RenderComparison.identical:
      case RenderComparison.metadata:
        return;
      case RenderComparison.paint:
        _textPainter.text = value;
        _rawText = value;
        extractPlaceholderSpans(value);
        _cachedPlainText = null;
        markNeedsPaint();
        markNeedsSemanticsUpdate();
        break;
      case RenderComparison.layout:
        _textPainter.text = value;
        _rawText = value;
        _cachedPlainText = null;
        _overflowShader = null;
        extractPlaceholderSpans(value);
        markNeedsTextLayout();
        break;
    }
  }

  /// How the text should be aligned horizontally.
  TextAlign get textAlign => _textPainter.textAlign;
  set textAlign(TextAlign value) {
    if (_textPainter.textAlign == value) {
      return;
    }
    _textPainter.textAlign = value;
    markNeedsTextLayout();
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
  @override
  TextDirection get textDirection => _textPainter.textDirection!;
  set textDirection(TextDirection value) {
    if (_textPainter.textDirection == value) {
      return;
    }
    _textPainter.textDirection = value;
    markNeedsTextLayout();
  }

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was
  /// unlimited horizontal space.
  ///
  /// If [softWrap] is false, [overflow] and [textAlign] may have unexpected
  /// effects.
  @override
  bool get softWrap => _softWrap;
  bool _softWrap;
  set softWrap(bool value) {
    if (_softWrap == value) {
      return;
    }
    _softWrap = value;
    markNeedsTextLayout();
  }

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  @override
  double get textScaleFactor => _textPainter.textScaleFactor;
  @override
  set textScaleFactor(double value) {
    if (_textPainter.textScaleFactor == value) {
      return;
    }
    _textPainter.textScaleFactor = value;
    _overflowShader = null;
    markNeedsTextLayout();
  }

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow] and [softWrap].
  int? get maxLines => _textPainter.maxLines;

  /// The value may be null. If it is not null, then it must be greater than zero.
  set maxLines(int? value) {
    assert(value == null || value > 0);
    if (_textPainter.maxLines == value) {
      return;
    }
    _textPainter.maxLines = value;
    _overflowShader = null;
    markNeedsTextLayout();
  }

  /// Used by this paragraph's internal [TextPainter] to select a locale-specific
  /// font.
  ///
  /// In some cases the same Unicode character may be rendered differently depending
  /// on the locale. For example the '骨' character is rendered differently in
  /// the Chinese and Japanese locales. In these cases the [locale] may be used
  /// to select a locale-specific font.
  Locale? get locale => _textPainter.locale;

  /// The value may be null.
  set locale(Locale? value) {
    if (_textPainter.locale == value) {
      return;
    }
    _textPainter.locale = value;
    _overflowShader = null;
    markNeedsTextLayout();
  }

  /// {@macro flutter.painting.textPainter.strutStyle}
  StrutStyle? get strutStyle => _textPainter.strutStyle;

  /// The value may be null.
  set strutStyle(StrutStyle? value) {
    if (_textPainter.strutStyle == value) {
      return;
    }
    _textPainter.strutStyle = value;
    _overflowShader = null;
    markNeedsTextLayout();
  }

  /// {@macro flutter.widgets.basic.TextWidthBasis}
  TextWidthBasis get textWidthBasis => _textPainter.textWidthBasis;
  set textWidthBasis(TextWidthBasis value) {
    if (_textPainter.textWidthBasis == value) {
      return;
    }
    _textPainter.textWidthBasis = value;
    _overflowShader = null;
    markNeedsTextLayout();
  }

  /// {@macro flutter.dart:ui.textHeightBehavior}
  ui.TextHeightBehavior? get textHeightBehavior =>
      _textPainter.textHeightBehavior;
  set textHeightBehavior(ui.TextHeightBehavior? value) {
    if (_textPainter.textHeightBehavior == value) {
      return;
    }
    _textPainter.textHeightBehavior = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  /// Controls how tall the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxHeightStyle] for details on available styles.
  @override
  ui.BoxHeightStyle get selectionHeightStyle => _selectionHeightStyle;
  ui.BoxHeightStyle _selectionHeightStyle;
  set selectionHeightStyle(ui.BoxHeightStyle value) {
    if (_selectionHeightStyle == value) {
      return;
    }
    _selectionHeightStyle = value;
    markNeedsPaint();
  }

  /// Controls how wide the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxWidthStyle] for details on available styles.
  @override
  ui.BoxWidthStyle get selectionWidthStyle => _selectionWidthStyle;
  ui.BoxWidthStyle _selectionWidthStyle;
  set selectionWidthStyle(ui.BoxWidthStyle value) {
    if (_selectionWidthStyle == value) {
      return;
    }
    _selectionWidthStyle = value;
    markNeedsPaint();
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
    assert(constraints.debugAssertIsValid());
    layoutTextWithConstraints(constraints);
    // (garyq): Since our metric for ideographic baseline is currently
    // inaccurate and the non-alphabetic baselines are based off of the
    // alphabetic baseline, we use the alphabetic for now to produce correct
    // layouts. We should eventually change this back to pass the `baseline`
    // property when the ideographic baseline is properly implemented
    // (https://github.com/flutter/flutter/issues/22625).
    return _textPainter
        .computeDistanceToActualBaseline(TextBaseline.alphabetic);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  // @override
  // void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
  //   assert(debugHandleEvent(event, entry));
  //   if (event is! PointerDownEvent) {
  //     return;
  //   }
  //   layoutTextWithConstraints(constraints);
  //   final Offset offset = entry.localPosition;
  //   final TextPosition position = _textPainter.getPositionForOffset(offset);
  //   final InlineSpan? span = _textPainter.text!.getSpanForPosition(position);
  //   if (span != null && span is TextSpan) {
  //     span.recognizer?.addPointer(event);
  //   }
  // }

  /// Whether this paragraph currently has a [dart:ui.Shader] for its overflow
  /// effect.
  ///
  /// Used to test this object. Not for use in production.
  @visibleForTesting
  bool get debugHasOverflowShader => _overflowShader != null;

  @override
  void performLayout() {
    layoutAll();
    layoutOverflow();
  }

  void layoutAll() {
    layoutChildren(constraints);
    layoutText(
      minWidth: constraints.minWidth,
      maxWidth: constraints.maxWidth,
      forceLayout: true,
    );

    setParentData();

    // We grab _textPainter.size and _textPainter.didExceedMaxLines here because
    // assigning to `size` will trigger us to validate our intrinsic sizes,
    // which will change _textPainter's layout because the intrinsic size
    // calculations are destructive. Other _textPainter state will also be
    // affected. See also RenderEditable which has a similar issue.
    final Size textSize = _textPainter.size;
    size = constraints.constrain(textSize);
  }

  Offset _offset = Offset.zero;
  @override
  void paint(PaintingContext context, Offset offset) {
    _offset = offset;
    // Ideally we could compute the min/max intrinsic width/height with a
    // non-destructive operation. However, currently, computing these values
    // will destroy state inside the painter. If that happens, we need to
    // get back the correct state by calling _layout again.
    //
    // (abarth): Make computing the min/max intrinsic width/height
    // a non-destructive operation.
    //
    // If you remove this call, make sure that changing the textAlign still
    // works properly.
    layoutTextWithConstraints(constraints);

    assert(() {
      if (debugRepaintTextRainbowEnabled) {
        final Paint paint = Paint()..color = debugCurrentRepaintColor.toColor();
        context.canvas.drawRect(offset & size, paint);
      }
      return true;
    }());
    if (_needsClipping) {
      final Rect bounds = offset & size;
      if (_overflowShader != null) {
        // This layer limits what the shader below blends with to be just the
        // text (as opposed to the text and its background).
        context.canvas.saveLayer(bounds, Paint());
      } else {
        context.canvas.save();
      }
      context.canvas.clipRect(bounds);
    }

    _paintTextOverflow(context, offset);
    //clip rect of over flow
    if (_overflowRect != null) {
      context.canvas.saveLayer(offset & size, Paint());
    }
    _paintSelection(context, offset);
    _paintSpecialText(context, offset);
    _paint(context, offset);
    if (_overflowRect != null) {
      // crop rect before _overflowRect
      // it's used for [TextOverflowPosition.middle]
      if (_overflowRects != null && _overflowRects!.isNotEmpty) {
        for (final Rect rect in _overflowRects!) {
          context.canvas.drawRect(
              rect.shift(offset), Paint()..blendMode = BlendMode.clear);
        }
      }
      context.canvas.drawRect(
          _overflowRect!.shift(offset), Paint()..blendMode = BlendMode.clear);

      if (kDebugMode &&
          overflowWidget != null &&
          overflowWidget!.debugOverflowRectColor != null) {
        context.canvas.drawRect(_overflowRect!.shift(offset),
            Paint()..color = overflowWidget!.debugOverflowRectColor!);
      }

      context.canvas.restore();
    }
    paintHandleLayers(context, super.paint);

    if (_needsClipping) {
      if (_overflowShader != null) {
        context.canvas.translate(offset.dx, offset.dy);
        final Paint paint = Paint()
          ..blendMode = BlendMode.modulate
          ..shader = _overflowShader;
        context.canvas.drawRect(Offset.zero & size, paint);
      }
      context.canvas.restore();
    }
  }

  void _paint(PaintingContext context, Offset offset) {
    if (_needsClipping) {
      final Rect bounds = offset & size;
      if (_overflowShader != null) {
        // This layer limits what the shader below blends with to be just the text
        // (as opposed to the text and its background).
        context.canvas.saveLayer(bounds, Paint());
      } else {
        context.canvas.save();
      }
      context.canvas.clipRect(bounds);
    }
    _textPainter.paint(context.canvas, offset);

    paintWidgets(
      context,
      offset,
      overFlowRect: _overflowRect,
    );

    if (_needsClipping) {
      if (_overflowShader != null) {
        context.canvas.translate(offset.dx, offset.dy);
        final Paint paint = Paint()
          ..blendMode = BlendMode.modulate
          ..shader = _overflowShader;
        context.canvas.drawRect(Offset.zero & size, paint);
      }
      context.canvas.restore();
    }
  }

  /// Returns the offset at which to paint the caret.
  ///
  /// Valid only after [layout].
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    assert(!debugNeedsLayout);
    layoutTextWithConstraints(constraints);
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
    layoutTextWithConstraints(constraints);
    return _textPainter.getBoxesForSelection(
      selection,
      boxWidthStyle: selectionWidthStyle,
      boxHeightStyle: selectionHeightStyle,
    );
  }

  /// Returns the position within the text for the given pixel offset.
  ///
  /// Valid only after [layout].
  TextPosition getPositionForOffset(Offset offset) {
    assert(!debugNeedsLayout);
    layoutTextWithConstraints(constraints);
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
  @override
  TextRange getWordBoundary(TextPosition position) {
    assert(!debugNeedsLayout);
    layoutTextWithConstraints(constraints);
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

  /// Collected during [describeSemanticsConfiguration], used by
  /// [assembleSemanticsNode] and [_combineSemanticsInfo].
  List<InlineSpanSemanticsInformation>? _semanticsInfo;

  /// Combines _semanticsInfo entries where permissible, determined by
  /// [InlineSpanSemanticsInformation.requiresOwnNode].
  List<InlineSpanSemanticsInformation> _combineSemanticsInfo() {
    assert(_semanticsInfo != null);
    final List<InlineSpanSemanticsInformation> combined =
        <InlineSpanSemanticsInformation>[];
    String workingText = '';
    // TODO(ianh): this algorithm is internally inconsistent. workingText
    // never becomes null, but we check for it being so below.
    String? workingLabel;
    for (final InlineSpanSemanticsInformation info in _semanticsInfo!) {
      if (info.requiresOwnNode) {
        combined.add(InlineSpanSemanticsInformation(
          workingText,
          semanticsLabel: workingLabel ?? workingText,
        ));
        workingText = '';
        workingLabel = null;
        combined.add(info);
      } else {
        workingText += info.text;
        workingLabel ??= '';
        if (info.semanticsLabel != null) {
          workingLabel += info.semanticsLabel!;
        } else {
          workingLabel += info.text;
        }
      }
    }
    combined.add(InlineSpanSemanticsInformation(
      workingText,
      semanticsLabel: workingLabel,
    ));

    return combined;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    _semanticsInfo = text.getSemanticsInformation();

    // add SemanticsInformation for overflowWidget
    // add into _semanticsInfo even if _hasVisualOverflow is false.
    // make sure that assert(childIndex == children.length)
    // is passed in assembleSemanticsNode method.
    //
    if (overflowWidget != null) {
      _semanticsInfo!
          .addAll(WidgetSpan(child: overflowWidget!).getSemanticsInformation());
    }

    if (_semanticsInfo!.any(
        (InlineSpanSemanticsInformation info) => info.recognizer != null)) {
      config.explicitChildNodes = true;
      config.isSemanticBoundary = true;
    } else {
      final StringBuffer buffer = StringBuffer();
      for (final InlineSpanSemanticsInformation info in _semanticsInfo!) {
        buffer.write(info.semanticsLabel ?? info.text);
      }
      config.label = buffer.toString();
      config.textDirection = textDirection;
    }
  }

  // Caches [SemanticsNode]s created during [assembleSemanticsNode] so they
  // can be re-used when [assembleSemanticsNode] is called again. This ensures
  // stable ids for the [SemanticsNode]s of [TextSpan]s across
  // [assembleSemanticsNode] invocations.
  Queue<SemanticsNode>? _cachedChildNodes;

  @override
  void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config,
      Iterable<SemanticsNode> children) {
    assert(_semanticsInfo != null && _semanticsInfo!.isNotEmpty);
    final List<SemanticsNode> newChildren = <SemanticsNode>[];
    TextDirection currentDirection = textDirection;
    Rect currentRect;
    double ordinal = 0.0;
    int start = 0;
    int placeholderIndex = 0;
    int childIndex = 0;
    RenderBox? child = firstChild;
    final Queue<SemanticsNode> newChildCache = Queue<SemanticsNode>();
    for (final InlineSpanSemanticsInformation info in _combineSemanticsInfo()) {
      final TextSelection selection = TextSelection(
        baseOffset: start,
        extentOffset: start + info.text.length,
      );
      start += info.text.length;

      if (info.isPlaceholder) {
        // A placeholder span may have 0 to multple semantics nodes, we need
        // to annotate all of the semantics nodes belong to this span.
        while (children.length > childIndex &&
            children
                .elementAt(childIndex)
                .isTagged(PlaceholderSpanIndexSemanticsTag(placeholderIndex))) {
          final SemanticsNode childNode = children.elementAt(childIndex);
          final TextParentData parentData =
              child!.parentData! as TextParentData;

          childNode.rect = Rect.fromLTWH(
            childNode.rect.left,
            childNode.rect.top,
            childNode.rect.width * (parentData.scale ?? 1.0),
            childNode.rect.height * (parentData.scale ?? 1.0),
          );
          newChildren.add(childNode);
          childIndex += 1;
        }
        child = childAfter(child!);
        placeholderIndex += 1;
      } else {
        final TextDirection initialDirection = currentDirection;
        final List<ui.TextBox> rects = getBoxesForSelection(selection);
        if (rects.isEmpty) {
          continue;
        }
        Rect rect = rects.first.toRect();
        currentDirection = rects.first.direction;
        for (final ui.TextBox textBox in rects.skip(1)) {
          rect = rect.expandToInclude(textBox.toRect());
          currentDirection = textBox.direction;
        }
        // Any of the text boxes may have had infinite dimensions.
        // We shouldn't pass infinite dimensions up to the bridges.
        rect = Rect.fromLTWH(
          math.max(0.0, rect.left),
          math.max(0.0, rect.top),
          math.min(rect.width, constraints.maxWidth),
          math.min(rect.height, constraints.maxHeight),
        );
        // round the current rectangle to make this API testable and add some
        // padding so that the accessibility rects do not overlap with the text.
        currentRect = Rect.fromLTRB(
          rect.left.floorToDouble() - 4.0,
          rect.top.floorToDouble() - 4.0,
          rect.right.ceilToDouble() + 4.0,
          rect.bottom.ceilToDouble() + 4.0,
        );
        final SemanticsConfiguration configuration = SemanticsConfiguration()
          ..sortKey = OrdinalSortKey(ordinal++)
          ..textDirection = initialDirection
          ..label = info.semanticsLabel ?? info.text;
        final GestureRecognizer? recognizer = info.recognizer;
        if (recognizer != null) {
          if (recognizer is TapGestureRecognizer) {
            if (recognizer.onTap != null) {
              configuration.onTap = recognizer.onTap;
              configuration.isLink = true;
            }
          } else if (recognizer is DoubleTapGestureRecognizer) {
            if (recognizer.onDoubleTap != null) {
              configuration.onTap = recognizer.onDoubleTap;
              configuration.isLink = true;
            }
          } else if (recognizer is LongPressGestureRecognizer) {
            if (recognizer.onLongPress != null) {
              configuration.onLongPress = recognizer.onLongPress;
            }
          } else {
            assert(false, '${recognizer.runtimeType} is not supported.');
          }
        }
        final SemanticsNode newChild = (_cachedChildNodes?.isNotEmpty == true)
            ? _cachedChildNodes!.removeFirst()
            : SemanticsNode();
        newChild
          ..updateWith(config: configuration)
          ..rect = currentRect;
        newChildCache.addLast(newChild);
        newChildren.add(newChild);
      }
    }
    // Makes sure we annotated all of the semantics children.
    assert(childIndex == children.length);
    assert(child == null);

    _cachedChildNodes = newChildCache;
    node.updateWith(config: config, childrenInInversePaintOrder: newChildren);
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _cachedChildNodes = null;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      text.toDiagnosticsNode(
        name: 'text',
        style: DiagnosticsTreeStyle.transition,
      )
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
    properties.add(EnumProperty<TextOverflow>('overflow', overflow));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
    properties
        .add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, ifNull: 'unlimited'));
  }

  void _paintSpecialText(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    canvas.save();

    ///move to extended text
    canvas.translate(offset.dx, offset.dy);

    ///we have move the canvas, so rect top left should be (0,0)
    final Rect rect = const Offset(0.0, 0.0) & size;
    _paintSpecialTextChildren(<InlineSpan>[text], canvas, rect);
    canvas.restore();
  }

  void _paintSpecialTextChildren(
      List<InlineSpan> textSpans, Canvas canvas, Rect rect,
      {int textOffset = 0}) {
    for (final InlineSpan ts in textSpans) {
      final Offset topLeftOffset = getOffsetForCaret(
        TextPosition(offset: textOffset),
        rect,
      );
      //skip invalid or overflow
      if (textOffset != 0 && topLeftOffset == Offset.zero) {
        return;
      }

      if (ts is BackgroundTextSpan) {
        final TextPainter painter = ts.layout(_textPainter)!;
        final Rect textRect = topLeftOffset & painter.size;
        Offset? endOffset;
        if (textRect.right > rect.right) {
          final int endTextOffset = textOffset + ts.toPlainText().length;
          endOffset = _findEndOffset(rect, endTextOffset);
        }

        ts.paint(canvas, topLeftOffset, rect,
            endOffset: endOffset, wholeTextPainter: _textPainter);
      }
      // else if (ts is PaintingImageSpan) {
      //   ///imageSpanTransparentPlaceholder \u200B has no width, and we define image width by
      //   ///use letterSpacing,so the actual top-left offset of image should be subtract letterSpacing(width)/2.0
      //   Offset imageSpanOffset = topLeftOffset - Offset(ts.width / 2.0, 0.0);

      //   if (!ts.paint(canvas, imageSpanOffset)) {
      //     //image not ready
      //     ts.resolveImage(
      //         listener: (ImageInfo imageInfo, bool synchronousCall) {
      //       if (synchronousCall)
      //         ts.paint(canvas, imageSpanOffset);
      //       else {
      //         if (owner == null || !owner.debugDoingPaint) {
      //           markNeedsPaint();
      //         }
      //       }
      //     });
      //   }
      // }
      else if (ts is TextSpan && ts.children != null) {
        _paintSpecialTextChildren(ts.children!, canvas, rect,
            textOffset: textOffset);
      }

      textOffset += ts.toPlainText().length;
    }
  }

  Offset _findEndOffset(Rect rect, int endTextOffset) {
    final Offset endOffset = getOffsetForCaret(
      TextPosition(offset: endTextOffset, affinity: TextAffinity.upstream),
      rect,
    );
    //overflow
    if (endTextOffset != 0 && endOffset == Offset.zero) {
      return _findEndOffset(rect, endTextOffset - 1);
    }
    return endOffset;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (overflowWidget != null && _overflowRect != null) {
      final bool isHit = hitTestChild(result, lastChild!, position: position);
      if (isHit) {
        return true;
      }
      // stop hittest if overflowRect contains position
      if (_overflowRect!.contains(position)) {
        return false;
      }
    }
    return super.hitTestChildren(result, position: position);
  }

  void _paintSelection(PaintingContext context, Offset effectiveOffset) {
    if (_selection == null) {
      return;
    }
    bool showSelection = false;

    // zmt
    TextSelection actualSelection = hasSpecialInlineSpanBase
        ? convertTextInputSelectionToTextPainterSelection(text, _selection!)
        : _selection!;

    // never drag over the over flow text span
    actualSelection = neverDragOnOverflow(actualSelection);

    if (!actualSelection.isCollapsed && _selectionColor != null) {
      showSelection = true;
      _updateSelectionExtentsVisibility(effectiveOffset, actualSelection);
    }

    if (showSelection) {
      _selectionRects ??= _textPainter.getBoxesForSelection(
        actualSelection,
        boxWidthStyle: selectionWidthStyle,
        boxHeightStyle: selectionHeightStyle,
      );

      assert(_selectionRects != null);
      paintSelection(context.canvas, effectiveOffset);
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
  @override
  List<TextSelectionPoint>? getEndpointsForSelection(TextSelection selection) {
//    if (temp.isCollapsed && toolbar) {
//      // (mpcomplete): This doesn't work well at an RTL/LTR boundary.
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

    if (!selection.isCollapsed) {
      layoutTextWithConstraints(constraints);
      TextSelection textPainterSelection = selection;
      if (hasSpecialInlineSpanBase) {
        textPainterSelection =
            convertTextInputSelectionToTextPainterSelection(text, selection);
      }

      // never drag over the over flow text span
      textPainterSelection = neverDragOnOverflow(textPainterSelection);

      final List<ui.TextBox> boxes = _textPainter.getBoxesForSelection(
        textPainterSelection,
        boxWidthStyle: selectionWidthStyle,
        boxHeightStyle: selectionHeightStyle,
      );

      if (boxes.isEmpty) {
        return null;
      }

      final Offset start = Offset(boxes.first.start, boxes.first.bottom);
      final Offset end = Offset(boxes.last.end, boxes.last.bottom);
      if (start == end) {
        return null;
      }

      return <TextSelectionPoint>[
        TextSelectionPoint(start, boxes.first.direction),
        TextSelectionPoint(end, boxes.last.direction),
      ];
    }

    return null;
  }

  //Rect _caretPrototype = Rect.zero;

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
  @override
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
  @override
  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

  @override
  TextPosition getPositionForPoint(Offset? globalPosition) {
    layoutTextWithConstraints(constraints);

    final Offset offset = globalToLocal(globalPosition!);

    TextPosition result = _textPainter.getPositionForOffset(offset);

    // never drag over the over flow text span
    final TextSelection selection = neverDragOnOverflow(TextSelection.collapsed(
      offset: result.offset,
      affinity: result.affinity,
    ));

    if (selection.baseOffset != result.offset) {
      result =
          TextPosition(offset: selection.baseOffset, affinity: result.affinity);
    } else if (selection.extentOffset != result.offset) {
      result = TextPosition(
          offset: selection.extentOffset, affinity: result.affinity);
    }

    return result;
  }

  void _updateSelectionExtentsVisibility(
      Offset effectiveOffset, TextSelection selection) {
    ///final Rect visibleRegion = Offset.zero & size;

    ///zmt
    ///caret may be less than 0, because it's bigger than text
    ///

    final Rect visibleRegion = Offset.zero & size;
    //getCaretOffset already has effectiveOffset
    final Offset startOffset = getCaretOffset(
      TextPosition(
        offset: selection.start,
        affinity: selection.affinity,
      ),
      effectiveOffset: effectiveOffset,
    );

    // (justinmc): https://github.com/flutter/flutter/issues/31495
    // Check if the selection is visible with an approximation because a
    // difference between rounded and unrounded values causes the caret to be
    // reported as having a slightly (< 0.5) negative y offset. This rounding
    // happens in paragraph.cc's layout and TextPainer's
    // _applyFloatingPointHack. Ideally, the rounding mismatch will be fixed and
    // this can be changed to be a strict check instead of an approximation.
    const double visibleRegionSlop = 0.5;
    _selectionStartInViewport.value =
        visibleRegion.inflate(visibleRegionSlop).contains(startOffset);
    //getCaretOffset already has effectiveOffset
    final Offset endOffset = getCaretOffset(
      TextPosition(offset: selection.end, affinity: selection.affinity),
      effectiveOffset: effectiveOffset,
    );

    _selectionEndInViewport.value =
        visibleRegion.inflate(visibleRegionSlop).contains(endOffset);
  }

  bool containsPosition(Offset position) {
    final Rect visibleRegion = Offset.zero & size;
    return visibleRegion.contains(globalToLocal(position));
  }

  @override
  bool get isAttached => attached;

  @override
  TextPainter get textPainter => _textPainter;

  @override
  double get caretMargin => 0.0;

  @override
  bool get forceLine => false;

  @override
  bool get isMultiline => maxLines != 1;

  @override
  bool get obscureText => false;

  @override
  Offset get paintOffset => Offset.zero;

  @override
  String get plainText {
    _cachedPlainText ??= textSpanToActualText(_textPainter.text!);
    return _cachedPlainText!;
  }

  @override
  List<TextBox>? get selectionRects => _selectionRects;

  @override
  Offset get effectiveOffset => _offset;

  @override
  Rect get caretPrototype =>
      Rect.fromLTWH(0, 0, 1, textPainter.preferredLineHeight);

  @override
  TextSelectionDelegate? textSelectionDelegate;

  @override
  bool get ignorePointer => false;

  @override
  bool get readOnly => true;

  @override
  final TextOverflow oldOverflow;
}
