part of 'extended_render_paragraph.dart';

mixin TextOverflowMixin on ExtendedTextSelectionRenderObject {
  TextOverflow get oldOverflow;
  Rect? _overflowRect;

  /// crop rect before _overflowRect
  /// it's used for [TextOverflowPosition.middle]
  List<Rect>? _overflowRects;
  bool _hasVisualOverflow = false;
  ui.Shader? _overflowShader;
  bool _needsClipping = false;
  // Retuns a cached plain text version of the text in the painter.
  String? _cachedPlainText;
  @override
  TextOverflowWidget? get overflowWidget => _overflowWidget;

  TextOverflowWidget? _overflowWidget;
  set overflowWidget(TextOverflowWidget? value) {
    if (_overflowWidget == value) {
      return;
    }
    if (value != null) {
      overflow = TextOverflow.clip;
    } else {
      overflow = oldOverflow;
    }
    _overflowWidget = value;
    markNeedsPaint();
  }

  /// How visual overflow should be handled.
  @override
  TextOverflow get overflow => _overflow;
  late TextOverflow _overflow;
  set overflow(TextOverflow value) {
    final TextOverflow temp =
        overflowWidget != null ? TextOverflow.clip : value;
    if (_overflow == temp) {
      return;
    }
    _overflow = temp;
    textPainter.ellipsis = value == TextOverflow.ellipsis ? _kEllipsis : null;
    markNeedsTextLayout();
  }

  void layoutOverflow() {
    final bool didOverflowWidth = _didVisualOverflow();
    layoutOfficalOverflow(didOverflowWidth);
    _overflowRect = null;
    _overflowRects = null;
    if (overflowWidget != null) {
      // #97, the overflowWidget is already added, we must layout it as official.
      lastChild!.layout(
        BoxConstraints(
          maxWidth: constraints.maxWidth,
          maxHeight:
              overflowWidget!.maxHeight ?? textPainter.preferredLineHeight,
        ),
        parentUsesSize: true,
      );

      if (!_hasVisualOverflow) {
        return;
      }
      //assert(textPainter.width >= lastChild!.size.width);

      final TextParentData textParentData =
          lastChild!.parentData as TextParentData;
      textParentData.scale = 1.0;

      final Rect rect = Offset.zero & size;
      final Size overflowWidgetSize = lastChild!.size;
      final TextOverflowPosition textOverflowPosition =
          overflowWidget!.position;
      final int maxOffset = text!.toPlainText().length;
      if (textOverflowPosition == TextOverflowPosition.end) {
        final TextSelection overflowSelection = TextSelection(
          baseOffset: textPainter
              .getPositionForOffset(rect.bottomRight -
                  Offset(
                      overflowWidgetSize.width, overflowWidgetSize.height / 2))
              .offset,
          extentOffset:
              textPainter.getPositionForOffset(rect.bottomRight).offset,
        );

        textParentData.offset = rect.bottomRight -
            Offset(overflowWidgetSize.width, overflowWidgetSize.height);

        _setOverflowRect(
          overflowSelection,
          overflowWidgetSize,
          textParentData,
          rect,
          maxOffset,
          overflowWidget!.position,
        );
      }
      // middle/start
      else {
        assert(textPainter.maxLines != null);

        int start = 0;
        int end = 0;
        final int maxLines = textPainter.maxLines!;
        final bool even = maxLines % 2 == 0;

        // middle
        if (textOverflowPosition == TextOverflowPosition.middle) {
          // Rect textRect = Offset.zero & reversedTextPainter.size;

          // TextPosition position = reversedTextPainter.getPositionForOffset(even
          //     ? textRect.centerRight - Offset(overflowWidgetSize.width, 0)
          //     : textRect.center - Offset(overflowWidgetSize.width / 2, 0));

          // end = maxOffset - position.offset;

          TextPosition position = textPainter.getPositionForOffset(even
              ? Offset(
                  0, rect.centerLeft.dy + textPainter.preferredLineHeight / 2.0)
              : rect.center - Offset(overflowWidgetSize.width / 2, 0));
          position =
              convertTextPainterPostionToTextInputPostion(text!, position)!;

          start = position.offset;
          end = start + 1;
        }
        // start
        else {
          // final TextPainter reversedTextPainter = _copyTextPainter(
          //   inlineSpan: _reversedSpan(text!),
          //   maxLines: textPainter.maxLines,
          // );
          // reversedTextPainter.setPlaceholderDimensions(
          //     placeholderDimensions?.reversed.toList());
          // reversedTextPainter.layout(
          //   minWidth: constraints.minWidth,
          //   maxWidth: constraints.maxWidth,
          // );
          // final TextPosition position =
          //     reversedTextPainter.getPositionForOffset(rect.bottomRight);
          TextPosition position = textPainter.getPositionForOffset(Offset(
              overflowWidgetSize.width, textPainter.preferredLineHeight / 2));
          position =
              convertTextPainterPostionToTextInputPostion(text!, position)!;

          end = position.offset;
        }

        final _TextRange range =
            _TextRange(math.min(start, end), math.max(start, end));
        final List<int> hideWidgets = <int>[];

        final TextPainter testTextPainter = _findNoOverflow(range, hideWidgets);

        assert(!_hasVisualOverflow);

        final InlineSpan oldSpan = textPainter.text!;
        // recreate text
        textPainter.text = testTextPainter.text;
        extractPlaceholderSpans(textPainter.text!);
        _cachedPlainText = null;
        layoutChildren(constraints, hideWidgets: hideWidgets);
        layoutText(
          minWidth: constraints.minWidth,
          maxWidth: constraints.maxWidth,
          forceLayout: true,
        );

        setParentData();

        final Size textSize = textPainter.size;
        size = constraints.constrain(textSize);

        if (textOverflowPosition == TextOverflowPosition.start) {
          final TextSelection overflowSelection = TextSelection(
            baseOffset: textPainter.getPositionForOffset(Offset.zero).offset,
            extentOffset: textPainter
                .getPositionForOffset(Offset(overflowWidgetSize.width, 0))
                .offset,
          );

          textParentData.offset = getCaretOffset(
            TextPosition(offset: overflowSelection.baseOffset),
          );

          _setOverflowRect(
            overflowSelection,
            overflowWidgetSize,
            textParentData,
            rect,
            maxOffset,
            overflowWidget!.position,
          );
        }
        // middle
        else {
          TextSelection overflowSelection = TextSelection(
            baseOffset: range.start,
            extentOffset: range.end,
          );

          overflowSelection = convertTextInputSelectionToTextPainterSelection(
              oldSpan, overflowSelection);

          final List<ui.TextBox> boxs = textPainter.getBoxesForSelection(
            overflowSelection,
            boxWidthStyle: selectionWidthStyle,
            boxHeightStyle: selectionHeightStyle,
          );
          _overflowRects ??= <Rect>[];
          for (final ui.TextBox box in boxs) {
            final Rect boxRect = box.toRect();
            if (boxRect.width == 0) {
              continue;
            }
            if (boxRect.left + overflowWidgetSize.width < rect.width) {
              textParentData.offset = boxRect.topLeft;

              overflowSelection = TextSelection(
                  baseOffset: textPainter
                      .getPositionForOffset(boxRect.centerLeft)
                      .offset,
                  extentOffset: textPainter
                      .getPositionForOffset(boxRect.centerLeft +
                          Offset(overflowWidgetSize.width, 0))
                      .offset);

              break;
            } else {
              _overflowRects?.add(boxRect);
            }
          }

          _setOverflowRect(
            overflowSelection,
            overflowWidgetSize,
            textParentData,
            rect,
            maxOffset,
            overflowWidget!.position,
          );
        }
      }
    }
  }

  int _layoutCount = 0;
  TextPainter _findNoOverflow(_TextRange range, List<int> hideWidgets) {
    _layoutCount = 0;
    late TextPainter testTextPainter;
    final int maxOffset = textSpanToActualText(text!).length;
    int maxEnd = maxOffset;
    while (_hasVisualOverflow) {
      testTextPainter = _tryToFindNoOverflow1(range, hideWidgets);
      // try to find no overflow

      if (_hasVisualOverflow) {
        // not find
        assert(range.end != maxOffset, 'can\' find no overflow');
        range.end = math.min(
            range.end + math.max((maxEnd - range.end) ~/ 2, 1), maxOffset);
        hideWidgets.clear();
      } else {
        // see pre one whether overflow
        range.end = math.min(range.end - 1, maxOffset);
        _tryToFindNoOverflow1(range, <int>[]);
        if (_hasVisualOverflow) {
          // fix end
          range.end = math.min(range.end + 1, maxOffset);
          // find the one
          _hasVisualOverflow = false;
        } else {
          maxEnd = range.end;
          range.end = math.max(
              range.start,
              math.min(
                  maxEnd - math.max((maxEnd - range.start) ~/ 2, 1), maxEnd));
          // continue
          _hasVisualOverflow = true;
        }
      }
    }
    if (kDebugMode && overflowWidget?.debugOverflowRectColor != null) {
      print(
          '${overflowWidget?.position}: find no overflow by layout TextPainter $_layoutCount times.');
    }

    return testTextPainter;
  }

  TextPainter _tryToFindNoOverflow1(_TextRange range, List<int> hideWidgets) {
    final InlineSpan inlineSpan = _cutOffInlineSpan(
      text!,
      Accumulator(),
      range,
      hideWidgets,
      Accumulator(),
    );

    final TextPainter testTextPainter = _copyTextPainter(
      inlineSpan: inlineSpan,
      maxLines: textPainter.maxLines,
    );

    layoutChildren(
      constraints,
      textPainter: testTextPainter,
      hideWidgets: hideWidgets,
    );

    testTextPainter.layout(
      minWidth: constraints.minWidth,
      maxWidth: constraints.maxWidth,
    );
    if (kDebugMode) {
      _layoutCount++;
    }
    _didVisualOverflow(textPainter: testTextPainter);
    _hasVisualOverflow = testTextPainter.didExceedMaxLines;
    return testTextPainter;
  }

  void _setOverflowRect(
    TextSelection overflowSelection,
    Size overFlowWidgetSize,
    TextParentData textParentData,
    Rect rect,
    int maxOffset,
    TextOverflowPosition position,
  ) {
    _overflowRect = textParentData.offset & overFlowWidgetSize;
    Rect overflowRect = getTextRect(
      overflowSelection,
      position,
      effectiveOffset: Offset.zero,
    );

    final bool rightBig = _overflowRect!.right > overflowRect.right;

    final bool leftBig = _overflowRect!.left > overflowRect.left;

    if (
        //position != TextOverflowPosition.middle ||
        _overflowRect!.overlaps(overflowRect)) {
      if (overflowRect.width == 0) {
        overflowRect = Rect.fromLTWH(overflowRect.left, _overflowRect!.top,
            overflowRect.width, _overflowRect!.height);
      }
      _overflowRect = _overflowRect!.expandToInclude(overflowRect);
    }

    bool go = true;
    while (go) {
      go = false;
      if (overflowSelection.baseOffset > 0 &&
          rect.left < _overflowRect!.left &&
          (leftBig
              ? _overflowRect!.left > overflowRect.left
              : _overflowRect!.left < overflowRect.left)) {
        overflowSelection = overflowSelection.copyWith(
            baseOffset: overflowSelection.baseOffset - 1);
        go = true;
      }
      if (overflowSelection.extentOffset < maxOffset &&
          rect.right > _overflowRect!.right &&
          (rightBig
              ? _overflowRect!.right > overflowRect.right
              : _overflowRect!.right < overflowRect.right)) {
        overflowSelection = overflowSelection.copyWith(
          extentOffset: overflowSelection.extentOffset + 1,
        );
        go = true;
      }

      if (!go) {
        break;
      }

      overflowRect = getTextRect(
        overflowSelection,
        position,
        effectiveOffset: Offset.zero,
      );
      // igore zero width
      if (_overflowRect!.overlaps(overflowRect)) {
        if (overflowRect.width == 0) {
          overflowRect = Rect.fromLTWH(overflowRect.left, _overflowRect!.top,
              overflowRect.width, _overflowRect!.height);
        }
        _overflowRect = _overflowRect!.expandToInclude(overflowRect);
      } else {
        // out _overflowRect and reach rect
        if (rect.left >= _overflowRect!.left ||
            rect.right <= _overflowRect!.right) {
          // see whether in the same line
          overflowRect = Rect.fromLTRB(_overflowRect!.left, overflowRect.top,
              _overflowRect!.right, overflowRect.bottom);
          if (_overflowRect!.overlaps(overflowRect)) {
            _overflowRect = _overflowRect!.expandToInclude(overflowRect);
          }
          go = false;
        }
      }

      // final Rect temp = getTextRect(
      //   overflowSelection,
      //   position,
      //   effectiveOffset: Offset.zero,
      // );

      // if (position == TextOverflowPosition.middle) {
      //   if (temp != overflowRect) {
      //     overflowRect = temp;
      //     if (_overflowRect!.overlaps(overflowRect)) {
      //       _overflowRect = _overflowRect!.expandToInclude(overflowRect);
      //     }
      //     // line breaking
      //     else {
      //       break;
      //     }
      //   }
      //   // line breaking
      //   else {
      //     break;
      //   }
      // } else {
      //   overflowRect = temp;
      //   _overflowRect = _overflowRect!.expandToInclude(overflowRect);
      // }
    }

    late double left;
    switch (overflowWidget!.align) {
      case TextOverflowAlign.left:
        left = _overflowRect!.left;
        break;
      case TextOverflowAlign.right:
        left = _overflowRect!.right - overFlowWidgetSize.width;
        break;
      case TextOverflowAlign.center:
        left = _overflowRect!.center.dx - overFlowWidgetSize.width / 2;
        break;
      default:
    }
    textParentData.offset = Offset(
        left,
        _overflowRect!.top +
            (_overflowRect!.height - overFlowWidgetSize.height) / 2.0);
  }

  void _paintTextOverflow(PaintingContext context, Offset offset) {
    if (overflowWidget != null && _overflowRect != null) {
      //assert(textPainter.width >= lastChild!.size.width);

      final TextParentData textParentData =
          lastChild!.parentData as TextParentData;
      final double scale = textParentData.scale!;
      context.pushTransform(
        needsCompositing,
        offset + textParentData.offset,
        Matrix4.diagonal3Values(scale, scale, scale),
        (PaintingContext context, Offset offset) {
          context.paintChild(
            lastChild!,
            offset,
          );
        },
      );
    }
  }

  /// cut off InlineSpan by range
  InlineSpan _cutOffInlineSpan(
    InlineSpan value,
    Accumulator offset,
    _TextRange range,
    List<int> hideWidgets,
    Accumulator hideWidgetIndex,
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
        String temp = '';
        for (int i = 0; i < text.length; i++) {
          final int index = i + offset.value;
          if (range.contains(index)) {
            continue;
          }
          temp += text[i];
        }
        text = temp;
      }

      actualText ??= value.text;
      if (actualText != null) {
        offset.increment(actualText.length);
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
      output = ExtendedWidgetSpan(
        child: range.contains(offset.value)
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
        hide: range.contains(offset.value),
      );
      if (range.contains(offset.value)) {
        hideWidgets.add(hideWidgetIndex.value);
      }

      offset.increment(actualText?.length ?? 1);
      hideWidgetIndex.increment(1);
    } else {
      output = value;
    }

    return output;
  }

  TextPainter _copyTextPainter({
    InlineSpan? inlineSpan,
    int? maxLines,
  }) {
    return TextPainter(
      text: inlineSpan ?? text,
      textAlign: textPainter.textAlign,
      textDirection: textPainter.textDirection,
      textScaleFactor: textPainter.textScaleFactor,
      maxLines: maxLines,
      ellipsis: null,
      locale: textPainter.locale,
      strutStyle: textPainter.strutStyle,
      textWidthBasis: textPainter.textWidthBasis,
      textHeightBehavior: textPainter.textHeightBehavior,
    );
  }

  bool _didVisualOverflow({TextPainter? textPainter}) {
    final Size textSize = (textPainter ?? this.textPainter).size;
    final bool textDidExceedMaxLines =
        (textPainter ?? this.textPainter).didExceedMaxLines;
    final bool didOverflowHeight =
        size.height < textSize.height || textDidExceedMaxLines;
    final bool didOverflowWidth = size.width < textSize.width;
    // (abarth): We're only measuring the sizes of the line boxes here. If
    // the glyphs draw outside the line boxes, we might think that there isn't
    // visual overflow when there actually is visual overflow. This can become
    // a problem if we start having horizontal overflow and introduce a clip
    // that affects the actual (but undetected) vertical overflow.
    _hasVisualOverflow = didOverflowWidth || didOverflowHeight;
    return didOverflowWidth;
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

  void layoutOfficalOverflow(bool didOverflowWidth) {
    if (_hasVisualOverflow) {
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
            text: TextSpan(style: textPainter.text!.style, text: '\u2026'),
            textDirection: textDirection,
            textScaleFactor: textPainter.textScaleFactor,
            locale: textPainter.locale,
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
      _needsClipping = false;
      _overflowShader = null;
    }
  }

  Rect getTextRect(
    TextSelection selection,
    TextOverflowPosition position, {
    Offset? effectiveOffset,
    Rect caretPrototype = Rect.zero,
  }) {
    effectiveOffset ??= Offset.zero;

    final List<TextBox> boxs = textPainter.getBoxesForSelection(
      selection,
      boxWidthStyle: selectionWidthStyle,
      boxHeightStyle: selectionHeightStyle,
    );
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
            textPainter.getOffsetForCaret(textPosition, Rect.zero);
        final double? height =
            textPainter.getFullHeightForCaret(textPosition, caretPrototype);
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
    if (overflowWidget != null && _overflowRect != null) {
      if (overflowWidget!.position == TextOverflowPosition.end) {
        final TextPosition position =
            textPainter.getPositionForOffset(_overflowRect!.bottomLeft);
        if (result.extentOffset > position.offset) {
          result = result.copyWith(extentOffset: position.offset);
        }
      } else if (overflowWidget!.position == TextOverflowPosition.start) {
        final TextPosition position =
            textPainter.getPositionForOffset(_overflowRect!.topRight);
        if (result.baseOffset < position.offset) {
          result = result.copyWith(baseOffset: position.offset);
        }
      }
    }
    return result;
  }
}

class _TextRange {
  _TextRange(this.start, this.end) : assert(start <= end);
  int start;
  int end;

  bool contains(int value) {
    return start <= value && value <= end;
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
