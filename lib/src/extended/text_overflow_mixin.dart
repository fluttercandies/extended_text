// ignore_for_file: prefer_final_fields

part of 'package:extended_text/src/extended/rendering/paragraph.dart';

mixin TextOverflowMixin on _RenderParagraph {
  TextOverflow _oldOverflow = TextOverflow.clip;

  // Offset _effectiveOffset = Offset.zero;
  int get textChildCount => childCount - overflowWidgetChildrenCount;

  int get overflowWidgetChildrenCount => overflowWidget != null
      ? (overflowWidget?.position == TextOverflowPosition.auto ? 2 : 1)
      : 0;

  List<RenderBox> get overflowWidgetChildren {
    final List<RenderBox> result = <RenderBox>[];
    if (overflowWidget != null) {
      if (overflowWidget!.position == TextOverflowPosition.auto) {
        result.add(childBefore(lastChild!)!);
      }
      result.add(lastChild!);
    }
    return result;
  }

  /// crop rect before _overflowRect
  /// it's used for [TextOverflowPosition.middle]
  List<Rect>? _overflowClipTextRects;
  List<Rect>? _overflowRects;
  List<_TextRange>? _overflowSelections;

  bool _hasVisualOverflow = false;
  // Retuns a cached plain text version of the text in the painter.

  TextOverflowWidget? get overflowWidget => _overflowWidget;
  TextOverflowWidget? _overflowWidget;
  set overflowWidget(TextOverflowWidget? value) {
    if (_overflowWidget == value) {
      return;
    }
    _overflowRects = null;
    _overflowClipTextRects = null;
    _overflowSelections = null;
    if (value != null) {
      overflow = TextOverflow.clip;
    } else {
      overflow = _oldOverflow;
    }
    _overflowWidget = value;
    markNeedsLayout();
  }

  /// How visual overflow should be handled.

  @override
  set overflow(TextOverflow value) {
    _oldOverflow = value;
    final TextOverflow temp =
        overflowWidget != null ? TextOverflow.clip : value;
    if (_overflow == temp) {
      return;
    }
    _overflow = temp;
    _textPainter.ellipsis = value == TextOverflow.ellipsis ? _kEllipsis : null;
    // markNeedsTextLayout();
    markNeedsLayout();
  }

  void layoutOverflow() {
    // final bool didOverflowWidth = _didVisualOverflow();
    // layoutOfficalOverflow(didOverflowWidth);
    _overflowRects = null;
    _overflowClipTextRects = null;
    _overflowSelections = null;

    if (overflowWidget != null) {
      // #97, the overflowWidget is already added, we must layout it as official.
      for (final RenderBox element in overflowWidgetChildren) {
        element.layout(
          BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight:
                overflowWidget!.maxHeight ?? _textPainter.preferredLineHeight,
          ),
          parentUsesSize: true,
        );
      }

      if (!_hasVisualOverflow) {
        return;
      }
      //assert(textPainter.width >= lastChild!.size.width);

      TextOverflowPosition textOverflowPosition = overflowWidget!.position;

      if (textOverflowPosition != TextOverflowPosition.end) {
        TextPainter testTextPainter = _textPainter;
        final List<int> hideWidgets = <int>[];
        if (textOverflowPosition == TextOverflowPosition.auto) {
          final List<_TextRange> ranges = _getEstimatedCropRange();
          testTextPainter = _findNoOverflowWithAuto(
            ranges[0],
            ranges[1],
            hideWidgets,
            (TextOverflowPosition p) {
              textOverflowPosition = p;
            },
          );
        } else {
          final _TextRange range = _getEstimatedCropRange()[0];
          testTextPainter = _findNoOverflow(
            range,
            hideWidgets,
          );
        }

        assert(!_hasVisualOverflow);

        // recreate text

        _textPainter.text = testTextPainter.text;
        _placeholderDimensions = layoutInlineChildren(
          constraints.maxWidth,
          ChildLayoutHelper.layoutChild,
          ChildLayoutHelper.getDryBaseline,
          hideWidgets: hideWidgets,
        );
        _layoutTextWithConstraints(constraints);
        positionInlineChildren(_textPainter.inlinePlaceholderBoxes!);

        final Size textSize = _textPainter.size;
        size = constraints.constrain(textSize);
      }

      _hasVisualOverflow = _didVisualOverflow();
      if (_hasVisualOverflow) {
        _needsClipping = true;
        _overflowShader = null;
      }
      _setOverflowRect(textOverflowPosition);
    }
  }

  List<_TextRange> _getEstimatedCropRange() {
    int start = 0;
    int end = 0;
    final Size overflowWidgetSize = lastChild!.size;
    final TextOverflowPosition position = overflowWidget!.position;

    final TextPainter oneLineTextPainter = _copyTextPainter();

    final List<PlaceholderDimensions> placeholderDimensions =
        layoutInlineChildren(
      constraints.maxWidth,
      ChildLayoutHelper.layoutChild,
      ChildLayoutHelper.getDryBaseline,
      textPainter: oneLineTextPainter,
      hideWidgets: <int>[],
    );
    oneLineTextPainter.setPlaceholderDimensions(placeholderDimensions);
    oneLineTextPainter.layout();
    double oneLineWidth = oneLineTextPainter.width;
    final List<ui.LineMetrics> lines = _textPainter.computeLineMetrics();

    final List<_TextRange> ranges = <_TextRange>[];
    switch (position) {
      case TextOverflowPosition.start:
        for (final ui.LineMetrics line in lines) {
          oneLineWidth -= line.width;
        }

        end = ExtendedTextLibraryUtils
                .convertTextPainterPostionToTextInputPostion(
                    text,
                    oneLineTextPainter.getPositionForOffset(Offset(
                        math.max(oneLineWidth, overflowWidgetSize.width),
                        oneLineTextPainter.height / 2)))!
            .offset;
        ranges.add(_TextRange(start, end));
        break;
      case TextOverflowPosition.middle:
        final int lineNum = (lines.length / 2).floor();
        final bool isEven = lines.length.isEven;
        final ui.LineMetrics line = lines[lineNum];
        double lineTop = 0;

        for (int index = 0; index < lineNum; index++) {
          final ui.LineMetrics line = lines[index];
          lineTop += line.height;
        }

        final double lineCenter = lineTop + line.height / 2;
        ui.Rect overflowRect = Rect.zero;
        final double textWidth = _textPainter.width;
        if (isEven) {
          overflowRect = Rect.fromLTRB(
            0,
            lineCenter - overflowWidgetSize.height / 2,
            overflowWidgetSize.width,
            lineCenter + overflowWidgetSize.height / 2,
          );
        } else {
          overflowRect = Rect.fromLTRB(
            textWidth / 2 - overflowWidgetSize.width / 2,
            lineCenter - overflowWidgetSize.height / 2,
            textWidth / 2 + overflowWidgetSize.width / 2,
            lineCenter + overflowWidgetSize.height / 2,
          );
        }

        start = ExtendedTextLibraryUtils
                .convertTextPainterPostionToTextInputPostion(
                    text,
                    _textPainter
                        .getPositionForOffset(overflowRect.centerRight))!
            .offset;

        for (int index = lines.length - 1; index > lineNum; index--) {
          final ui.LineMetrics line = lines[index];
          oneLineWidth -= line.width;
        }

        oneLineWidth -= line.width - overflowRect.right;

        end = ExtendedTextLibraryUtils
                .convertTextPainterPostionToTextInputPostion(
                    text,
                    oneLineTextPainter.getPositionForOffset(Offset(
                        math.max(oneLineWidth, overflowWidgetSize.width),
                        oneLineTextPainter.height / 2)))!
            .offset;

        ranges.add(_TextRange(start, end));
        break;

      case TextOverflowPosition.auto:
        SpecialInlineSpanBase? keepVisibleSpan;
        text.visitChildren((InlineSpan span) {
          if (span is SpecialInlineSpanBase &&
              (span as SpecialInlineSpanBase).keepVisible == true) {
            keepVisibleSpan = span as SpecialInlineSpanBase;
            return false;
          }
          return true;
        });

        assert(keepVisibleSpan != null,
            'TextOverflowPosition.auto only works when any span is setting to keepVisible');
        _TextRange keepVisibleRange = _TextRange(
            keepVisibleSpan!.textRange.start, keepVisibleSpan!.textRange.end);

        final List<ui.TextBox> rects = oneLineTextPainter.getBoxesForSelection(
            ExtendedTextLibraryUtils
                .convertTextInputSelectionToTextPainterSelection(
          text,
          TextSelection(
              baseOffset: keepVisibleRange.start,
              extentOffset: keepVisibleRange.end),
        ));

        double left = double.infinity;
        double right = 0;
        for (int index = 0; index < rects.length; index++) {
          final ui.TextBox rect = rects[index];
          left = math.min(rect.left, left);
          right = math.max(rect.right, right);
        }

        keepVisibleRange = _TextRange(
          ExtendedTextLibraryUtils.convertTextPainterPostionToTextInputPostion(
                  text,
                  oneLineTextPainter.getPositionForOffset(Offset(
                      left - overflowWidgetSize.width,
                      oneLineTextPainter.height / 2)))!
              .offset,
          ExtendedTextLibraryUtils.convertTextPainterPostionToTextInputPostion(
                  text,
                  oneLineTextPainter.getPositionForOffset(Offset(
                      right + overflowWidgetSize.width,
                      oneLineTextPainter.height / 2)))!
              .offset,
        );

        final double totalWidth =
            _textPainter.computeLineMetrics().length * size.width;
        final double half = math.max(
            (totalWidth - (right - left)) / 2, overflowWidgetSize.width * 2);

        left = left - half;
        right = right + half;

        if (left < 0) {
          right -= left;
          left = 0;
        }
        final double maxIntrinsicWidth = oneLineTextPainter.width;
        if (right > maxIntrinsicWidth) {
          left -= right - maxIntrinsicWidth;
          right = maxIntrinsicWidth;
        }

        final _TextRange estimatedRange = _TextRange(
          ExtendedTextLibraryUtils.convertTextPainterPostionToTextInputPostion(
                  text,
                  oneLineTextPainter.getPositionForOffset(
                      Offset(left, oneLineTextPainter.height / 2)))!
              .offset,
          ExtendedTextLibraryUtils.convertTextPainterPostionToTextInputPostion(
                  text,
                  oneLineTextPainter.getPositionForOffset(
                      Offset(right, oneLineTextPainter.height / 2)))!
              .offset,
        );

        ranges.add(estimatedRange);
        ranges.add(keepVisibleRange);
        break;
      default:
    }

    return ranges;
  }

  int _layoutCount = 0;

  TextPainter _findNoOverflowWithAuto(
    _TextRange estimatedRange,
    _TextRange keepVisibleRange,
    List<int> hideWidgets,
    Function(TextOverflowPosition position) onChangeOverflowPosition,
  ) {
    _layoutCount = 0;

    late TextPainter testTextPainter;
    final int maxOffset =
        ExtendedTextLibraryUtils.textSpanToActualText(text).runes.length;
    while (_hasVisualOverflow) {
      testTextPainter = _tryToFindNoOverflow1(
        estimatedRange,
        hideWidgets,
        false,
      );
      // try to find no overflow

      if (_hasVisualOverflow) {
        final int start = estimatedRange.start;
        final int end = estimatedRange.end;
        if (start == 0) {
          estimatedRange.end =
              math.max(estimatedRange.end - 1, keepVisibleRange.end);
          if (estimatedRange.end == end) {
            estimatedRange.start =
                math.min(estimatedRange.start + 1, keepVisibleRange.start);
          }
        } else if (end == maxOffset) {
          estimatedRange.start =
              math.min(estimatedRange.start + 1, keepVisibleRange.start);
          if (estimatedRange.start == start) {
            estimatedRange.end =
                math.max(estimatedRange.end - 1, keepVisibleRange.end);
          }
        } else {
          estimatedRange.start =
              math.min(estimatedRange.start + 1, keepVisibleRange.start);
          estimatedRange.end =
              math.max(estimatedRange.end - 1, keepVisibleRange.end);
        }
        hideWidgets.clear();
      } else {
        // end
        if (estimatedRange.start == 0) {
          onChangeOverflowPosition(TextOverflowPosition.end);
          return testTextPainter;
        }
        _hasVisualOverflow = true;
        final _TextRange pre = _TextRange(
          estimatedRange.start,
          estimatedRange.end,
        );

        void _dothing(List<_TextRange> ranges, int index) {
          hideWidgets.clear();
          final TextPainter testResult =
              testTextPainter = _tryToFindNoOverflow1(
            ranges[index],
            hideWidgets,
            false,
          );

          if (_hasVisualOverflow) {
            _hasVisualOverflow = false;
            // end
            if (pre.start == 0) {
              onChangeOverflowPosition(TextOverflowPosition.end);
            }
            // start
            else if (pre.end == maxOffset) {
              onChangeOverflowPosition(TextOverflowPosition.start);
            }
            // start and end
            else {
              onChangeOverflowPosition(TextOverflowPosition.auto);
            }
          } else {
            testTextPainter = testResult;
            estimatedRange = ranges[index];
            index++;
            if (index < ranges.length) {
              _dothing(ranges, index);
            }
          }
        }

        _dothing(<_TextRange>[
          _TextRange(
            math.max(pre.start - 1, 0),
            pre.end,
          ),
          _TextRange(
            pre.start,
            math.min(pre.end + 1, maxOffset),
          ),
          _TextRange(
            math.max(pre.start - 1, 0),
            math.min(pre.end + 1, maxOffset),
          ),
        ], 0);
      }
    }
    if (kDebugMode && overflowWidget?.debugOverflowRectColor != null) {
      print(
          '${overflowWidget?.position}: find no overflow by layout TextPainter $_layoutCount times.');
    }

    return testTextPainter;
  }

  TextPainter _findNoOverflow(
    _TextRange range,
    List<int> hideWidgets,
  ) {
    _layoutCount = 0;

    late TextPainter testTextPainter;
    final int maxOffset =
        ExtendedTextLibraryUtils.textSpanToActualText(text).runes.length;
    int maxEnd = maxOffset;
    while (_hasVisualOverflow) {
      testTextPainter = _tryToFindNoOverflow1(
        range,
        hideWidgets,
        true,
      );
      // try to find no overflow

      if (_hasVisualOverflow) {
        // not find
        assert(range.end != maxOffset, 'can\' find no overflow');
        range.end = math.min(
            range.end + 1
            // math.max((maxEnd - range.end) ~/ 2, 1)
            ,
            maxOffset);
        hideWidgets.clear();
      } else {
        // see pre one whether overflow
        range.end = math.min(range.end - 1, maxOffset);

        final _TextRange pre = range.copyWith();
        _tryToFindNoOverflow1(range, <int>[], true);

        if (_hasVisualOverflow) {
          // fix end
          range.end = math.min(range.end + 1, maxOffset);
          // find the one
          _hasVisualOverflow = false;
        } else {
          maxEnd = range.end;
          range.end = math.max(
            range.start,
            maxEnd - 1,
            // math.min(
            //     math.max((maxEnd - range.start) ~/ 2, 1),
            //     maxEnd)
          );
          // if range is not changed, so maybe we should break.
          if (pre == range) {
            _hasVisualOverflow = false;
          } else {
            hideWidgets.clear();
            _hasVisualOverflow = true;
          }
        }
      }
    }
    if (kDebugMode && overflowWidget?.debugOverflowRectColor != null) {
      print(
          '${overflowWidget?.position}: find no overflow by layout TextPainter $_layoutCount times.');
    }

    return testTextPainter;
  }

  TextPainter _tryToFindNoOverflow1(
    _TextRange range,
    List<int> hideWidgets,
    bool excludeRange,
  ) {
    final InlineSpan inlineSpan = _cutOffInlineSpan(
      text,
      Accumulator(),
      range,
      hideWidgets,
      Accumulator(),
      excludeRange,
    );

    final TextPainter testTextPainter = _copyTextPainter(
      inlineSpan: inlineSpan,
      maxLines: _textPainter.maxLines,
    );

    final List<PlaceholderDimensions> placeholderDimensions =
        layoutInlineChildren(
      constraints.maxWidth,
      ChildLayoutHelper.layoutChild,
      ChildLayoutHelper.getDryBaseline,
      textPainter: testTextPainter,
      hideWidgets: hideWidgets,
    );

    testTextPainter
      ..setPlaceholderDimensions(placeholderDimensions)
      ..layout(
          minWidth: constraints.minWidth,
          maxWidth: _adjustMaxWidth(constraints.maxWidth));

    if (kDebugMode) {
      _layoutCount++;
    }
    _hasVisualOverflow = _didVisualOverflow(textPainter: testTextPainter);
    return testTextPainter;
  }

  List<Rect> _getOverflowRect(TextOverflowPosition position) {
    final double textWidth = _textPainter.width;

    final List<Rect> overflowWidgetRects = <Rect>[];

    final ui.Size overflowWidgetSize = lastChild!.size;

    final List<ui.LineMetrics> lines = _textPainter.computeLineMetrics();

    switch (position) {
      case TextOverflowPosition.start:
        {
          final ui.LineMetrics line = lines[0];
          final double lineCenter = line.height / 2;
          overflowWidgetRects.add(Rect.fromLTRB(
            0,
            lineCenter - overflowWidgetSize.height / 2,
            overflowWidgetSize.width,
            lineCenter + overflowWidgetSize.height / 2,
          ));
        }
        break;
      case TextOverflowPosition.middle:
        {
          final int lineNum = (lines.length / 2).floor();
          final bool isEven = lines.length.isEven;
          final ui.LineMetrics line = lines[lineNum];
          double lineTop = 0;
          for (int index = 0; index < lineNum; index++) {
            final ui.LineMetrics line = lines[index];
            lineTop += line.height;
          }
          final double lineCenter = lineTop + line.height / 2;

          if (isEven) {
            overflowWidgetRects.add(Rect.fromLTRB(
              0,
              lineCenter - overflowWidgetSize.height / 2,
              overflowWidgetSize.width,
              lineCenter + overflowWidgetSize.height / 2,
            ));
          } else {
            overflowWidgetRects.add(Rect.fromLTRB(
              textWidth / 2 - overflowWidgetSize.width / 2,
              lineCenter - overflowWidgetSize.height / 2,
              textWidth / 2 + overflowWidgetSize.width / 2,
              lineCenter + overflowWidgetSize.height / 2,
            ));
          }
        }
        break;
      case TextOverflowPosition.end:
        {
          final ui.LineMetrics line = lines[lines.length - 1];
          double lineTop = 0;
          for (int index = 0; index < lines.length - 1; index++) {
            final ui.LineMetrics line = lines[index];
            lineTop += line.height;
          }
          final double lineCenter = lineTop + line.height / 2;
          overflowWidgetRects.add(Rect.fromLTRB(
            textWidth - overflowWidgetSize.width,
            lineCenter - overflowWidgetSize.height / 2,
            textWidth,
            lineCenter + overflowWidgetSize.height / 2,
          ));
        }
        break;

      case TextOverflowPosition.auto:
        {
          ui.LineMetrics line = lines[0];
          double lineCenter = line.height / 2;
          overflowWidgetRects.add(Rect.fromLTRB(
            0,
            lineCenter - overflowWidgetSize.height / 2,
            overflowWidgetSize.width,
            lineCenter + overflowWidgetSize.height / 2,
          ));

          line = lines[lines.length - 1];
          double lineTop = 0;
          for (int index = 0; index < lines.length - 1; index++) {
            final ui.LineMetrics line = lines[index];
            lineTop += line.height;
          }
          lineCenter = lineTop + line.height / 2;
          overflowWidgetRects.add(Rect.fromLTRB(
            textWidth - overflowWidgetSize.width,
            lineCenter - overflowWidgetSize.height / 2,
            textWidth,
            lineCenter + overflowWidgetSize.height / 2,
          ));
        }
        break;
    }
    return overflowWidgetRects;
  }

  void _setOverflowRect(TextOverflowPosition position) {
    _overflowClipTextRects = <ui.Rect>[];
    _overflowRects = <ui.Rect>[];
    _overflowSelections = <_TextRange>[];
    final List<ui.Rect> overflowWidgetRects = _getOverflowRect(position);

    final List<RenderBox> overflowChildren = overflowWidgetChildren;

    for (int index = 0; index < overflowWidgetRects.length; index++) {
      ui.Rect overflowWidgetRect = overflowWidgetRects[index];
      final RenderBox overflowChild = overflowChildren[index];
      final _TextParentData parentData =
          overflowChild.parentData as _TextParentData;
      final ui.Size overflowWidgetSize = overflowChild.size;
      final double x = overflowWidgetRect.width / 5;

      int start = _textPainter
          .getPositionForOffset(Offset(overflowWidgetRect.left - x,
              overflowWidgetRect.top + overflowWidgetSize.height / 2))
          .offset;
      int end = _textPainter
          .getPositionForOffset(Offset(overflowWidgetRect.right + x,
              overflowWidgetRect.top + overflowWidgetSize.height / 2))
          .offset;

      final List<ui.TextBox> rects = _textPainter.getBoxesForSelection(
        TextSelection(
          baseOffset: start,
          extentOffset: end,
        ),
        // boxHeightStyle: ui.BoxHeightStyle.max,
        // boxWidthStyle: ui.BoxWidthStyle.max,
      );

      double rectLeft = overflowWidgetRect.left;
      double rectRight = overflowWidgetRect.right;
      for (int index = 0; index < rects.length; index++) {
        final ui.TextBox rect = rects[index];
        double left = math.max(rect.left, overflowWidgetRect.left);
        double right = math.min(rect.right, overflowWidgetRect.right);

        if (left < right) {
          if (left > rect.left) {
            left = rect.left;
          }
          if (right < rect.right) {
            right = rect.right;
          }

          final ui.Rect clipRect = Rect.fromLTRB(
            left,
            rect.top,
            right,
            rect.bottom,
          );
          rectLeft = math.min(rectLeft, clipRect.left);
          rectRight = math.max(rectRight, clipRect.right);
          _overflowClipTextRects!.add(clipRect);
        }
      }

      switch (overflowWidget!.align) {
        case TextOverflowAlign.left:
          break;
        case TextOverflowAlign.right:
          rectLeft = rectRight - overflowWidgetSize.width;
          break;
        case TextOverflowAlign.center:
          rectLeft = rectLeft +
              (rectRight - rectLeft) / 2 -
              overflowWidgetSize.width / 2;
          break;
        default:
      }
      overflowWidgetRect = Rect.fromLTRB(
        rectLeft,
        overflowWidgetRect.top,
        rectRight,
        overflowWidgetRect.bottom,
      );

      parentData._offset = overflowWidgetRect.topLeft;

      start = _textPainter
          .getPositionForOffset(overflowWidgetRect.centerLeft)
          .offset;
      end = _textPainter
          .getPositionForOffset(overflowWidgetRect.centerRight)
          .offset;
      _overflowSelections!.add(_TextRange(start, end));
      _overflowRects!.add(overflowWidgetRect);
    }
  }

  void _paintTextOverflow(PaintingContext context, Offset offset) {
    if (overflowWidget != null && _overflowRects != null) {
      //assert(textPainter.width >= lastChild!.size.width);
      final List<RenderBox> children = overflowWidgetChildren;
      for (int i = 0; i < _overflowRects!.length; i++) {
        final RenderBox element = children[i];
        final _TextParentData textParentData =
            element.parentData as _TextParentData;
        context.pushTransform(
          needsCompositing,
          offset + textParentData._offset!,
          Matrix4.diagonal3Values(1.0, 1.0, 1.0),
          (PaintingContext context, Offset offset) {
            context.paintChild(
              element,
              offset,
            );
          },
        );
      }
    }
  }

  /// cut off InlineSpan by range
  InlineSpan _cutOffInlineSpan(
    InlineSpan value,
    Accumulator offset,
    _TextRange range,
    List<int> hideWidgets,
    Accumulator hideWidgetIndex,
    bool excludeRange,
  ) {
    late InlineSpan output;
    String? actualText;
    bool deleteAll = false;
    if (value is SpecialInlineSpanBase) {
      final SpecialInlineSpanBase base = value as SpecialInlineSpanBase;
      actualText = base.actualText;
      deleteAll = base.deleteAll;
    } else {
      deleteAll = false;
    }
    if (value is TextSpan) {
      List<InlineSpan>? children;
      final int start = offset.value;

      String? text = value.text;
      if (text != null) {
        // https://github.com/dart-lang/sdk/issues/35798
        final List<int> runes = text.runes.toList();

        // if (kDebugMode) {
        //   if (runes.length != text.length) {}
        // }

        final List<int> finallyRunes = <int>[];
        //bool hasUtf16Surrogate = false;
        for (int i = 0; i < runes.length; i++) {
          final int index = i + offset.value;
          if (excludeRange ? range.contains(index) : !range.contains(index)) {
            // if (_isUtf16Surrogate(text.codeUnitAt(index))) {
            //   hasUtf16Surrogate = true;
            // }
            continue;
          }
          finallyRunes.add(runes[i]);
        }
        text = String.fromCharCodes(finallyRunes);

        // String temp = '';
        // for (int i = 0; i < text.length; i++) {
        //   final int index = i + offset.value;
        //   if (range.contains(index)) {
        //     continue;
        //   }
        //   temp += text[i];
        // }
        // text = temp;
      }

      actualText ??= value.text;
      if (actualText != null) {
        offset.increment(actualText.runes.length);
      }

      if (value.children != null) {
        children = <InlineSpan>[];
        for (final InlineSpan child in value.children!) {
          children.add(_cutOffInlineSpan(
            child,
            offset,
            range,
            hideWidgets,
            hideWidgetIndex,
            excludeRange,
          ));
        }
      }
      if (value is BackgroundTextSpan) {
        output = BackgroundTextSpan(
          background: value.background,
          clipBorderRadius: value.clipBorderRadius,
          paintBackground: value.paintBackground,
          text: text ?? '',
          actualText: actualText,
          start: start,
          style: value.style,
          recognizer: value.recognizer,
          deleteAll: deleteAll,
          semanticsLabel: value.semanticsLabel,
        );
      } else {
        output = SpecialTextSpan(
          text: text ?? '',
          actualText: actualText,
          children: children,
          start: start,
          style: value.style,
          recognizer: value.recognizer,
          deleteAll: deleteAll,
          semanticsLabel: value.semanticsLabel,
        );
      }
    } else if (value is WidgetSpan) {
      final bool hide = excludeRange
          ? range.contains(offset.value)
          : !range.contains(offset.value);
      output = ExtendedWidgetSpan(
        child: hide
            ? const SizedBox(
                width: 0,
                height: 0,
              )
            : value.child,
        start: offset.value,
        alignment: value.alignment,
        style: value.style,
        baseline: value.baseline,
        actualText: actualText,
        hide: hide,
      );
      if (hide) {
        hideWidgets.add(hideWidgetIndex.value);
      }

      offset.increment(actualText?.length ?? 1);
      hideWidgetIndex.increment(1);
    } else {
      output = value;
    }

    return output;
  }

  // ignore: unused_element
  bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }

  TextPainter _copyTextPainter({
    InlineSpan? inlineSpan,
    int? maxLines,
  }) {
    return TextPainter(
      text: inlineSpan ?? text,
      textAlign: _textPainter.textAlign,
      textDirection: _textPainter.textDirection,
      textScaler: _textPainter.textScaler,
      maxLines: maxLines,
      ellipsis: null,
      locale: _textPainter.locale,
      strutStyle: _textPainter.strutStyle,
      textWidthBasis: _textPainter.textWidthBasis,
      textHeightBehavior: _textPainter.textHeightBehavior,
    );
  }

  bool _didVisualOverflow({TextPainter? textPainter}) {
    final Size textSize = (textPainter ?? _textPainter).size;
    final bool textDidExceedMaxLines =
        (textPainter ?? _textPainter).didExceedMaxLines;
    final bool didOverflowHeight =
        size.height < textSize.height || textDidExceedMaxLines;
    final bool didOverflowWidth = size.width < textSize.width;

    if (size.height < textSize.height) {
      size = constraints.constrain(textSize);
    }

    return didOverflowWidth || didOverflowHeight;
  }

  // InlineSpan _reversedSpan(InlineSpan inlineSpan) {
  //   if (inlineSpan is TextSpan) {
  //     String? text = inlineSpan.text;
  //     if (text != null) {
  //       // add '\u{200B}' , make word close
  //       text = Characters(text).toList().reversed.join(zeroWidthSpace);
  //     }
  //     List<InlineSpan>? children;
  //     if (inlineSpan.children != null) {
  //       children = <InlineSpan>[];
  //       for (final InlineSpan child in inlineSpan.children!) {
  //         children.add(_reversedSpan(child));
  //       }
  //       children = children.reversed.toList();
  //     }

  //     return _ReversedTextSapn(
  //       text: text,
  //       children: children,
  //       style: inlineSpan.style,
  //       recognizer: inlineSpan.recognizer,
  //       semanticsLabel: inlineSpan.semanticsLabel,
  //     );
  //   } else {
  //     return inlineSpan;
  //   }
  // }

  // void layoutOfficalOverflow(bool didOverflowWidth) {
  //   if (_hasVisualOverflow) {
  //     switch (_overflow) {
  //       case TextOverflow.visible:
  //         _needsClipping = false;
  //         _overflowShader = null;
  //         break;
  //       case TextOverflow.clip:
  //       case TextOverflow.ellipsis:
  //         _needsClipping = true;
  //         _overflowShader = null;
  //         break;
  //       case TextOverflow.fade:
  //         _needsClipping = true;
  //         final TextPainter fadeSizePainter = TextPainter(
  //           text: TextSpan(style: _textPainter.text!.style, text: '\u2026'),
  //           textDirection: textDirection,
  //           textScaleFactor: _textPainter.textScaleFactor,
  //           locale: _textPainter.locale,
  //         )..layout();
  //         if (didOverflowWidth) {
  //           double fadeEnd, fadeStart;
  //           switch (textDirection) {
  //             case TextDirection.rtl:
  //               fadeEnd = 0.0;
  //               fadeStart = fadeSizePainter.width;
  //               break;
  //             case TextDirection.ltr:
  //               fadeEnd = size.width;
  //               fadeStart = fadeEnd - fadeSizePainter.width;
  //               break;
  //           }
  //           _overflowShader = ui.Gradient.linear(
  //             Offset(fadeStart, 0.0),
  //             Offset(fadeEnd, 0.0),
  //             <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
  //           );
  //         } else {
  //           final double fadeEnd = size.height;
  //           final double fadeStart = fadeEnd - fadeSizePainter.height / 2.0;
  //           _overflowShader = ui.Gradient.linear(
  //             Offset(0.0, fadeStart),
  //             Offset(0.0, fadeEnd),
  //             <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
  //           );
  //         }
  //         break;
  //     }
  //   } else {
  //     _needsClipping = false;
  //     _overflowShader = null;
  //   }
  // }

  Rect getTextRect(
    TextSelection selection,
    TextOverflowPosition position, {
    Offset? effectiveOffset,
    Rect caretPrototype = Rect.zero,
  }) {
    effectiveOffset ??= Offset.zero;

    final List<TextBox> boxs = _textPainter.getBoxesForSelection(selection);
    if (boxs.isNotEmpty) {
      Rect? rect;
      for (final TextBox box in boxs) {
        final Rect boxRect = box.toRect();
        if (rect == null) {
          rect = boxRect;
        } else
        // if (rect.overlaps(boxRect))
        {
          rect = rect.expandToInclude(boxRect);
        }
        // line breaking
        //else {
        //  break;
        // }
      }
      return rect!.shift(effectiveOffset);
    } else {
      Rect? rect;
      for (int i = selection.baseOffset; i <= selection.extentOffset; i++) {
        final TextPosition textPosition = TextPosition(offset: i);
        final Offset offset =
            _textPainter.getOffsetForCaret(textPosition, Rect.zero);
        final double? height =
            _textPainter.getFullHeightForCaret(textPosition, caretPrototype);
        //assert(height != null, 'can\' find selection');
        if (rect == null) {
          rect = Rect.fromLTWH(offset.dx, offset.dy, 1, height ?? 0);
        } else {
          rect = rect.expandToInclude(
              Rect.fromLTWH(offset.dx, offset.dy, 1, height ?? 0));
        }
      }

      return rect!;
    }
  }

  /// never drag over the over flow text span
  TextSelection neverDragOnOverflow(TextSelection result) {
    if (overflowWidget != null && _overflowRects != null) {
      if (overflowWidget!.position == TextOverflowPosition.end) {
        final TextPosition position =
            _textPainter.getPositionForOffset(_overflowRects!.first.centerLeft);
        if (result.extentOffset > position.offset) {
          result = result.copyWith(extentOffset: position.offset);
        }
      } else if (overflowWidget!.position == TextOverflowPosition.start) {
        final TextPosition position = _textPainter
            .getPositionForOffset(_overflowRects!.first.centerRight);
        if (result.baseOffset < position.offset) {
          result = result.copyWith(baseOffset: position.offset);
        }
      } else if (overflowWidget!.position == TextOverflowPosition.auto) {
        TextPosition position =
            _textPainter.getPositionForOffset(_overflowRects!.first.centerLeft);
        if (result.extentOffset > position.offset) {
          result = result.copyWith(extentOffset: position.offset);
        }

        position =
            _textPainter.getPositionForOffset(_overflowRects!.last.centerRight);
        if (result.baseOffset < position.offset) {
          result = result.copyWith(baseOffset: position.offset);
        }
      }
    }
    return result;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (overflowWidget != null && _overflowRects != null) {
      for (final RenderBox element in overflowWidgetChildren) {
        final bool isHit = ExtendedTextLibraryUtils.hitTestChild(
          result,
          element,
          // _effectiveOffset is not the same under 3.10.0
          // it should be zero for [ExtendedTexts]
          // _effectiveOffset,
          Offset.zero,
          position: position,
        );
        if (isHit) {
          return true;
        }
      }
      // stop hittest if overflowRect contains position
      for (final ui.Rect rect in _overflowRects!) {
        if (rect.contains(position)) {
          return false;
        }
      }
    }
    return super.hitTestChildren(result, position: position);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    _semanticsInfo = text.getSemanticsInformation();
    // add SemanticsInformation for overflowWidget
    // add into _semanticsInfo even if _hasVisualOverflow is false.
    // make sure that assert(childIndex == children.length)
    // is passed in assembleSemanticsNode method.
    // zmtzawqlp
    if (overflowWidget != null) {
      _semanticsInfo!
          .addAll(WidgetSpan(child: overflowWidget!).getSemanticsInformation());
    }

    bool needsAssembleSemanticsNode = false;
    bool needsChildConfigrationsDelegate = false;
    for (final InlineSpanSemanticsInformation info in _semanticsInfo!) {
      if (info.recognizer != null) {
        needsAssembleSemanticsNode = true;
        break;
      }
      needsChildConfigrationsDelegate =
          needsChildConfigrationsDelegate || info.isPlaceholder;
    }

    if (needsAssembleSemanticsNode) {
      config.explicitChildNodes = true;
      config.isSemanticBoundary = true;
    } else if (needsChildConfigrationsDelegate) {
      config.childConfigurationsDelegate =
          _childSemanticsConfigurationsDelegate;
    } else {
      if (_cachedAttributedLabels == null) {
        final StringBuffer buffer = StringBuffer();
        int offset = 0;
        final List<StringAttribute> attributes = <StringAttribute>[];
        for (final InlineSpanSemanticsInformation info in _semanticsInfo!) {
          final String label = info.semanticsLabel ?? info.text;
          for (final StringAttribute infoAttribute in info.stringAttributes) {
            final TextRange originalRange = infoAttribute.range;
            attributes.add(
              infoAttribute.copy(
                range: TextRange(
                  start: offset + originalRange.start,
                  end: offset + originalRange.end,
                ),
              ),
            );
          }
          buffer.write(label);
          offset += label.length;
        }
        _cachedAttributedLabels = <AttributedString>[
          AttributedString(buffer.toString(), attributes: attributes)
        ];
      }
      config.attributedLabel = _cachedAttributedLabels![0];
      config.textDirection = textDirection;
    }
  }

  @override
  List<PlaceholderDimensions> layoutInlineChildren(
    double maxWidth,
    ChildLayouter layoutChild,
    ChildBaselineGetter getChildBaseline, {
    // zmtzawqlp
    List<int>? hideWidgets,
    // zmtzawqlp
    TextPainter? textPainter,
  }) {
    if (childCount == 0) {
      return <PlaceholderDimensions>[];
    }
    final BoxConstraints constraints = BoxConstraints(maxWidth: maxWidth);
    RenderBox? child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>.filled(
            // zmtzawqlp
            textChildCount,
            PlaceholderDimensions.empty);
    int childIndex = 0;
    while (child != null && childIndex < textChildCount) {
      // zmtzawqlp
      if (hideWidgets == null || !hideWidgets.contains(childIndex)) {
        placeholderDimensions[childIndex] =
            ExtendedRenderParagraph._layoutChild(
          child,
          constraints,
          layoutChild,
          getChildBaseline,
        );
      }

      child = childAfter(child);
      childIndex += 1;
    }
    if (textPainter != null) {
      textPainter.setPlaceholderDimensions(placeholderDimensions);
      // return _placeholderDimensions ?? <PlaceholderDimensions>[];
    }
    return placeholderDimensions;

    // final BoxConstraints constraints = BoxConstraints(maxWidth: maxWidth);
    // return <PlaceholderDimensions>[
    //   for (RenderBox? child = firstChild;
    //       child != null;
    //       child = childAfter(child))
    //     _layoutChild(child, constraints, layoutChild, getChildBaseline),
    // ];
  }

  @override
  void positionInlineChildren(List<ui.TextBox> boxes) {
    RenderBox? child = firstChild;
    int childIndex = 0;
    for (final ui.TextBox box in boxes) {
      if (child == null) {
        assert(false,
            'The length of boxes (${boxes.length}) should be greater than childCount ($childCount)');
        return;
      }
      final _TextParentData textParentData =
          child.parentData! as _TextParentData;
      // not paint zero width widget
      if ((box.left - box.right).abs() < precisionErrorTolerance) {
        textParentData._offset = null;
      } else {
        textParentData._offset = Offset(box.left, box.top);
      }
      child = childAfter(child);
      childIndex++;
    }
    // zmtzawqlp
    while (child != null && childIndex < textChildCount) {
      final _TextParentData textParentData =
          child.parentData! as _TextParentData;
      textParentData._offset = null;
      child = childAfter(child);
      childIndex++;
    }
  }

  /// Paints each inline child.
  ///
  /// Render children whose [TextParentData.offset] is null will be skipped by
  /// this method.
  @override
  @protected
  void paintInlineChildren(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    int childIndex = 0;
    while (child != null && childIndex < textChildCount) {
      final TextParentData childParentData =
          child.parentData! as TextParentData;
      final Offset? childOffset = childParentData.offset;
      if (childOffset == null) {
        child = childAfter(child);
        childIndex++;
        // zmtzawqlp
        continue;
      }
      context.paintChild(child, childOffset + offset);
      child = childAfter(child);
      childIndex++;
    }
  }
}

class _TextRange {
  _TextRange(this.start, this.end) : assert(start <= end);
  int start;
  int end;

  bool contains(int value) {
    return start <= value && value <= end;
  }

  int get length => (end - start) + 1;

  _TextRange copyWith({int? start, int? end}) => _TextRange(
        start ?? this.start,
        end ?? this.end,
      );

  @override
  int get hashCode => Object.hash(start, end);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return (other is _TextRange) && start == other.start && end == other.end;
  }
}

// @immutable
// class _ReversedTextSapn extends TextSpan {
//   const _ReversedTextSapn({
//     String? text,
//     List<InlineSpan>? children,
//     TextStyle? style,
//     GestureRecognizer? recognizer,
//     String? semanticsLabel,
//   }) : super(
//           text: text,
//           children: children,
//           style: style,
//           recognizer: recognizer,
//           semanticsLabel: semanticsLabel,
//         );

//   @override
//   void computeToPlainText(StringBuffer buffer,
//       {bool includeSemanticsLabels = true, bool includePlaceholders = true}) {
//     assert(debugAssertIsValid());
//     if (children != null) {
//       for (final InlineSpan child in children!) {
//         child.computeToPlainText(
//           buffer,
//           includeSemanticsLabels: includeSemanticsLabels,
//           includePlaceholders: includePlaceholders,
//         );
//       }
//     }
//     if (semanticsLabel != null && includeSemanticsLabels) {
//       buffer.write(semanticsLabel);
//     } else if (text != null) {
//       buffer.write(text);
//     }
//   }

//   @override
//   void build(
//     ui.ParagraphBuilder builder, {
//     double textScaleFactor = 1.0,
//     List<PlaceholderDimensions>? dimensions,
//   }) {
//     assert(debugAssertIsValid());
//     final bool hasStyle = style != null;
//     if (hasStyle)
//       builder.pushStyle(style!.getTextStyle(textScaleFactor: textScaleFactor));
//     if (children != null) {
//       for (final InlineSpan child in children!) {
//         child.build(
//           builder,
//           textScaleFactor: textScaleFactor,
//           dimensions: dimensions,
//         );
//       }
//     }
//     if (text != null) {
//       builder.addText(text!);
//     }

//     if (hasStyle) {
//       builder.pop();
//     }
//   }
// }
