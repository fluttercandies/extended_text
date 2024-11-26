import 'dart:collection';
import 'dart:math' as math;

import 'dart:ui' as ui;
import 'dart:ui';

import 'package:extended_text/src/extended/gradient/gradient_config.dart';
import 'package:extended_text/src/extended/widgets/text_overflow_widget.dart';
import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

part 'package:extended_text/src/official/rendering/paragraph.dart';
part 'package:extended_text/src/extended/text_overflow_mixin.dart';
part 'package:extended_text/src/extended/selection_mixin.dart';
part 'package:extended_text/src/extended/gradient/gradient_mixin.dart';

/// Parent data used by [RenderParagraph] and [RenderEditable] to annotate
/// inline contents (such as [WidgetSpan]s) with.
class _TextParentData extends TextParentData {
  @override
  Offset? get offset => _offset;
  Offset? _offset;
}

/// [RenderParagraph]
///
class ExtendedRenderParagraph extends _RenderParagraph
    with TextOverflowMixin, SelectionMixin, GradientMixin {
  ExtendedRenderParagraph(
    super.text, {
    super.textAlign = TextAlign.start,
    required super.textDirection,
    super.softWrap = true,
    super.overflow = TextOverflow.clip,
    super.textScaler = TextScaler.noScaling,
    super.maxLines,
    super.locale,
    super.strutStyle,
    super.textWidthBasis = TextWidthBasis.parent,
    super.textHeightBehavior,
    super.children,
    super.selectionColor,
    super.registrar,
    TextOverflowWidget? overflowWidget,
    bool canSelectPlaceholderSpan = true,
    GradientConfig? gradientConfig,
  }) {
    _oldOverflow = overflow;
    _overflowWidget = overflowWidget;
    _canSelectPlaceholderSpan = canSelectPlaceholderSpan;
    _gradientConfig = gradientConfig;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TextParentData) {
      child.parentData = _TextParentData();
    }
  }

  static PlaceholderDimensions _layoutChild(
      RenderBox child,
      BoxConstraints childConstraints,
      ChildLayouter layoutChild,
      ChildBaselineGetter getBaseline) {
    final TextParentData parentData = child.parentData! as TextParentData;
    final PlaceholderSpan? span = parentData.span;
    assert(span != null);
    return span == null
        ? PlaceholderDimensions.empty
        : PlaceholderDimensions(
            size: layoutChild(child, childConstraints),
            alignment: span.alignment,
            baseline: span.baseline,
            baselineOffset: switch (span.alignment) {
              ui.PlaceholderAlignment.aboveBaseline ||
              ui.PlaceholderAlignment.belowBaseline ||
              ui.PlaceholderAlignment.bottom ||
              ui.PlaceholderAlignment.middle ||
              ui.PlaceholderAlignment.top =>
                null,
              ui.PlaceholderAlignment.baseline =>
                getBaseline(child, childConstraints, span.baseline!),
            },
          );
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    _placeholderDimensions = layoutInlineChildren(constraints.maxWidth,
        ChildLayoutHelper.layoutChild, ChildLayoutHelper.getBaseline);
    _layoutTextWithConstraints(constraints);
    positionInlineChildren(_textPainter.inlinePlaceholderBoxes!);

    final Size textSize = _textPainter.size;
    size = constraints.constrain(textSize);

    final bool didOverflowHeight =
        size.height < textSize.height || _textPainter.didExceedMaxLines;
    final bool didOverflowWidth = size.width < textSize.width;
    // TODO(abarth): We're only measuring the sizes of the line boxes here. If
    // the glyphs draw outside the line boxes, we might think that there isn't
    // visual overflow when there actually is visual overflow. This can become
    // a problem if we start having horizontal overflow and introduce a clip
    // that affects the actual (but undetected) vertical overflow.
    final bool hasVisualOverflow = didOverflowWidth || didOverflowHeight;
    if (hasVisualOverflow) {
      switch (_overflow) {
        case TextOverflow.visible:
          _needsClipping = false;
          _overflowShader = null;
          break;
        case TextOverflow.clip:
        case TextOverflow.ellipsis:
          _needsClipping = true;
          _overflowShader = null;
          break;
        case TextOverflow.fade:
          _needsClipping = true;
          final TextPainter fadeSizePainter = TextPainter(
            text: TextSpan(style: _textPainter.text!.style, text: '\u2026'),
            textDirection: textDirection,
            textScaler: textScaler,
            locale: locale,
          )..layout();
          if (didOverflowWidth) {
            final (double fadeStart, double fadeEnd) = switch (textDirection) {
              TextDirection.rtl => (fadeSizePainter.width, 0.0),
              TextDirection.ltr => (
                  size.width - fadeSizePainter.width,
                  size.width
                ),
            };
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
          fadeSizePainter.dispose();
      }
    } else {
      _needsClipping = false;
      _overflowShader = null;
    }

    // zmtzawqlp
    _hasVisualOverflow = hasVisualOverflow;
    layoutOverflow();
    // _hasVisualOverflow = hasVisualOverflow;
    if (overflowWidget != null && _hasVisualOverflow) {
      _removeSelectionRegistrarSubscription();
      _disposeSelectableFragments();
      _updateSelectionRegistrarSubscription();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // _effectiveOffset = offset;
    // Ideally we could compute the min/max intrinsic width/height with a
    // non-destructive operation. However, currently, computing these values
    // will destroy state inside the painter. If that happens, we need to get
    // back the correct state by calling _layout again.
    //
    // TODO(abarth): Make computing the min/max intrinsic width/height a
    //  non-destructive operation.
    //
    // If you remove this call, make sure that changing the textAlign still
    // works properly.
    _layoutTextWithConstraints(constraints);

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

    if (_lastSelectableFragments != null) {
      for (final _SelectableFragment fragment in _lastSelectableFragments!) {
        fragment.paint(context, offset);
      }
    }

    // zmtzawqlp
    // clip rect of over flow
    if (_overflowRects != null) {
      context.canvas.saveLayer(offset & size, Paint());
      // clip should be before textpainter
      if (overflowWidget?.clearType == TextOverflowClearType.clipRect) {
        // crop rect before _overflowRect
        // it's used for [TextOverflowPosition.middle]

        if (_overflowClipTextRects != null &&
            _overflowClipTextRects!.isNotEmpty) {
          for (final Rect rect in _overflowClipTextRects!) {
            context.canvas.clipRect(
              rect.shift(offset),
              clipOp: ui.ClipOp.difference,
            );
          }
        }
      }
    }

    // zmtzawqlp
    if (_gradientConfig != null) {
      context.canvas.saveLayer(offset & size, Paint());
    }

    _paintSpecialText(context, offset);
    _textPainter.paint(context.canvas, offset);
    // zmtzawqlp
    if (_gradientConfig != null && _gradientConfig!.ignoreWidgetSpan) {
      drawGradient(context, offset);
    }
    paintInlineChildren(context, offset);
    // zmtzawqlp
    if (_gradientConfig != null && !_gradientConfig!.ignoreWidgetSpan) {
      drawGradient(context, offset);
    }
    // zmtzawqlp
    if (_overflowRects != null) {
      // BlendMode.clear should be after textpainter
      if (overflowWidget?.clearType == TextOverflowClearType.blendModeClear) {
        // crop rect before _overflowRect
        // it's used for [TextOverflowPosition.middle]
        if (_overflowClipTextRects != null &&
            _overflowClipTextRects!.isNotEmpty) {
          for (final Rect rect in _overflowClipTextRects!) {
            context.canvas.drawRect(
                rect.shift(offset), Paint()..blendMode = BlendMode.clear);
          }
        }
      }

      if (kDebugMode &&
          overflowWidget != null &&
          overflowWidget!.debugOverflowRectColor != null) {
        for (final ui.Rect rect in _overflowRects!) {
          context.canvas.drawRect(rect.shift(offset),
              Paint()..color = overflowWidget!.debugOverflowRectColor!);
        }
      }

      context.canvas.restore();
    }
    // zmtzawqlp
    _paintTextOverflow(context, offset);

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

    super.paint(context, offset);
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
      } else if (ts is TextSpan && ts.children != null) {
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
}
