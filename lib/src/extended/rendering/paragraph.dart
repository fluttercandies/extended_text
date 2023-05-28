import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

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

/// [RenderParagraph]
///
class ExtendedRenderParagraph extends _RenderParagraph
    with TextOverflowMixin, SelectionMixin {
  ExtendedRenderParagraph(
    super.text, {
    super.textAlign = TextAlign.start,
    required super.textDirection,
    super.softWrap = true,
    super.overflow = TextOverflow.clip,
    super.textScaleFactor = 1.0,
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
  }) {
    _oldOverflow = overflow;
    _overflowWidget = overflowWidget;
    _canSelectPlaceholderSpan = canSelectPlaceholderSpan;
  }

  // Layout the child inline widgets. We then pass the dimensions of the
  // children to _textPainter so that appropriate placeholders can be inserted
  // into the LibTxt layout. This does not do anything if no inline widgets were
  // specified.
  @override
  List<PlaceholderDimensions> _layoutChildren(
    BoxConstraints constraints, {
    bool dry = false,
    // zmtzawqlp
    List<int>? hideWidgets,
    // zmtzawqlp
    TextPainter? textPainter,
  }) {
    if (childCount == 0) {
      return <PlaceholderDimensions>[];
    }
    RenderBox? child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>.filled(
            // zmtzawqlp
            textChildCount,
            PlaceholderDimensions.empty);
    int childIndex = 0;
    // Only constrain the width to the maximum width of the paragraph.
    // Leave height unconstrained, which will overflow if expanded past.
    BoxConstraints boxConstraints =
        BoxConstraints(maxWidth: constraints.maxWidth);
    // The content will be enlarged by textScaleFactor during painting phase.
    // We reduce constraints by textScaleFactor, so that the content will fit
    // into the box once it is enlarged.
    boxConstraints = boxConstraints / textScaleFactor;
    // zmtzawqlp
    while (child != null && childIndex < textChildCount) {
      double? baselineOffset;
      final Size childSize;
      if (!dry) {
        child.layout(
          // zmtzawqlp
          hideWidgets != null && hideWidgets.contains(childIndex)
              ? const BoxConstraints(maxWidth: 0)
              : boxConstraints,
          parentUsesSize: true,
        );
        childSize = child.size;
        switch (_placeholderSpans[childIndex].alignment) {
          case ui.PlaceholderAlignment.baseline:
            baselineOffset = child.getDistanceToBaseline(
              _placeholderSpans[childIndex].baseline!,
            );
            break;
          case ui.PlaceholderAlignment.aboveBaseline:
          case ui.PlaceholderAlignment.belowBaseline:
          case ui.PlaceholderAlignment.bottom:
          case ui.PlaceholderAlignment.middle:
          case ui.PlaceholderAlignment.top:
            baselineOffset = null;
            break;
        }
      } else {
        assert(_placeholderSpans[childIndex].alignment !=
            ui.PlaceholderAlignment.baseline);
        childSize = child.getDryLayout(boxConstraints);
      }

      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: childSize,
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
        baselineOffset: baselineOffset,
      );
      child = childAfter(child);
      childIndex += 1;
    }

    if (textPainter != null) {
      textPainter.setPlaceholderDimensions(placeholderDimensions);
      return _placeholderDimensions ?? <PlaceholderDimensions>[];
    }
    return placeholderDimensions;
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    _placeholderDimensions = _layoutChildren(constraints);
    _layoutTextWithConstraints(constraints);
    _setParentData();

    // We grab _textPainter.size and _textPainter.didExceedMaxLines here because
    // assigning to `size` will trigger us to validate our intrinsic sizes,
    // which will change _textPainter's layout because the intrinsic size
    // calculations are destructive. Other _textPainter state will also be
    // affected. See also RenderEditable which has a similar issue.
    final Size textSize = _textPainter.size;
    final bool textDidExceedMaxLines = _textPainter.didExceedMaxLines;
    size = constraints.constrain(textSize);

    final bool didOverflowHeight =
        size.height < textSize.height || textDidExceedMaxLines;
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
          fadeSizePainter.dispose();
      }
    } else {
      _needsClipping = false;
      _overflowShader = null;
    }

    // zmtzawqlp
    _hasVisualOverflow = hasVisualOverflow;
    layoutOverflow();
    _hasVisualOverflow = hasVisualOverflow;
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

    // zmtzawqlp
    // clip rect of over flow
    if (_overflowRect != null) {
      context.canvas.saveLayer(offset & size, Paint());
      // clip should be before textpainter
      if (overflowWidget?.clearType == TextOverflowClearType.clipRect) {
        // crop rect before _overflowRect
        // it's used for [TextOverflowPosition.middle]

        if (_overflowRects != null && _overflowRects!.isNotEmpty) {
          for (final Rect rect in _overflowRects!) {
            context.canvas.clipRect(
              rect.shift(offset),
              clipOp: ui.ClipOp.difference,
            );
          }
        }

        context.canvas.clipRect(
          _overflowRect!.shift(offset),
          clipOp: ui.ClipOp.difference,
        );
      }
    }
    _paintSpecialText(context, offset);
    _textPainter.paint(context.canvas, offset);

    RenderBox? child = firstChild;
    int childIndex = 0;
    // childIndex might be out of index of placeholder boxes. This can happen
    // if engine truncates children due to ellipsis. Sadly, we would not know
    // it until we finish layout, and RenderObject is in immutable state at
    // this point.
    while (child != null &&
        childIndex < _textPainter.inlinePlaceholderBoxes!.length) {
      final TextParentData textParentData = child.parentData! as TextParentData;

      final double scale = textParentData.scale!;
      context.pushTransform(
        needsCompositing,
        offset + textParentData.offset,
        Matrix4.diagonal3Values(scale, scale, scale),
        (PaintingContext context, Offset offset) {
          context.paintChild(
            child!,
            offset,
          );
        },
      );
      child = childAfter(child);
      childIndex += 1;
    }

    // zmtzawqlp
    if (_overflowRect != null) {
      // BlendMode.clear should be after textpainter
      if (overflowWidget?.clearType == TextOverflowClearType.blendModeClear) {
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
      }

      if (kDebugMode &&
          overflowWidget != null &&
          overflowWidget!.debugOverflowRectColor != null) {
        context.canvas.drawRect(_overflowRect!.shift(offset),
            Paint()..color = overflowWidget!.debugOverflowRectColor!);
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
    if (_lastSelectableFragments != null) {
      for (final _SelectableFragment fragment in _lastSelectableFragments!) {
        fragment.paint(context, offset);
      }
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
