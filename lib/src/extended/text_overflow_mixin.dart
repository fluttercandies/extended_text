// ignore_for_file: prefer_final_fields

part of 'package:extended_text/src/extended/rendering/paragraph.dart';

mixin TextOverflowMixin on _RenderParagraph {
  TextOverflow _oldOverflow = TextOverflow.clip;
  Rect? _overflowRect;
  Offset _effectiveOffset = Offset.zero;
  int get textChildCount =>
      overflowWidget != null ? childCount - 1 : childCount;

  /// crop rect before _overflowRect
  /// it's used for [TextOverflowPosition.middle]
  List<Rect>? _overflowRects;
  TextSelection? _overflowSelection;
  bool _hasVisualOverflow = false;
  // Retuns a cached plain text version of the text in the painter.

  TextOverflowWidget? get overflowWidget => _overflowWidget;
  TextOverflowWidget? _overflowWidget;
  set overflowWidget(TextOverflowWidget? value) {
    if (_overflowWidget == value) {
      return;
    }
    if (value != null) {
      overflow = TextOverflow.clip;
    } else {
      overflow = _oldOverflow;
    }
    _overflowWidget = value;
    markNeedsPaint();
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
    _overflowRect = null;
    _overflowRects = null;
    _overflowSelection = null;
    if (overflowWidget != null) {
      // #97, the overflowWidget is already added, we must layout it as official.
      lastChild!.layout(
        BoxConstraints(
          maxWidth: constraints.maxWidth,
          maxHeight:
              overflowWidget!.maxHeight ?? _textPainter.preferredLineHeight,
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
      final int maxOffset = text.toPlainText().runes.length;
      if (textOverflowPosition == TextOverflowPosition.end) {
        final TextSelection overflowSelection = TextSelection(
          baseOffset: _textPainter
              .getPositionForOffset(rect.bottomRight -
                  Offset(
                      overflowWidgetSize.width, overflowWidgetSize.height / 2))
              .offset,
          extentOffset:
              _textPainter.getPositionForOffset(rect.bottomRight).offset,
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
        assert(_textPainter.maxLines != null);

        int start = 0;
        int end = 0;
        final int maxLines = _textPainter.maxLines!;
        final bool even = maxLines % 2 == 0;

        // middle
        if (textOverflowPosition == TextOverflowPosition.middle) {
          // Rect textRect = Offset.zero & reversedTextPainter.size;

          // TextPosition position = reversedTextPainter.getPositionForOffset(even
          //     ? textRect.centerRight - Offset(overflowWidgetSize.width, 0)
          //     : textRect.center - Offset(overflowWidgetSize.width / 2, 0));

          // end = maxOffset - position.offset;

          TextPosition position = _textPainter.getPositionForOffset(even
              ? Offset(0,
                  rect.centerLeft.dy + _textPainter.preferredLineHeight / 2.0)
              : rect.center - Offset(overflowWidgetSize.width / 2, 0));
          position =
              convertTextPainterPostionToTextInputPostion(text, position)!;

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
          TextPosition position = _textPainter.getPositionForOffset(Offset(
              overflowWidgetSize.width, _textPainter.preferredLineHeight / 2));
          position =
              convertTextPainterPostionToTextInputPostion(text, position)!;

          end = position.offset;
        }

        final _TextRange range =
            _TextRange(math.min(start, end), math.max(start, end));
        final List<int> hideWidgets = <int>[];

        final TextPainter testTextPainter = _findNoOverflow(range, hideWidgets);

        assert(!_hasVisualOverflow);

        final InlineSpan oldSpan = _textPainter.text!;
        // recreate text
        _textPainter.text = testTextPainter.text;
        _extractPlaceholderSpans(_textPainter.text!);

        _layoutChildren(constraints, hideWidgets: hideWidgets);
        _layoutText(
          minWidth: constraints.minWidth,
          maxWidth: constraints.maxWidth,
        );

        _setParentData();

        final Size textSize = _textPainter.size;
        size = constraints.constrain(textSize);

        if (textOverflowPosition == TextOverflowPosition.start) {
          final TextSelection overflowSelection = TextSelection(
            baseOffset: _textPainter.getPositionForOffset(Offset.zero).offset,
            extentOffset: _textPainter
                .getPositionForOffset(Offset(overflowWidgetSize.width, 0))
                .offset,
          );

          textParentData.offset = ExtendedTextLibraryUtils.getCaretOffset(
            TextPosition(offset: overflowSelection.baseOffset),
            _textPainter,
            _placeholderSpans.isNotEmpty,
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
            extentOffset: range.start + math.max(1, range.end - range.start),
          );

          overflowSelection = convertTextInputSelectionToTextPainterSelection(
              oldSpan, overflowSelection);

          final List<ui.TextBox> boxs =
              _textPainter.getBoxesForSelection(overflowSelection);
          _overflowRects ??= <Rect>[];
          for (final ui.TextBox box in boxs) {
            final Rect boxRect = box.toRect();
            if (boxRect.width == 0) {
              continue;
            }
            if (boxRect.left + overflowWidgetSize.width < rect.width) {
              textParentData.offset = boxRect.topLeft;

              overflowSelection = TextSelection(
                  baseOffset: _textPainter
                      .getPositionForOffset(boxRect.centerLeft)
                      .offset,
                  extentOffset: _textPainter
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
    final int maxOffset = textSpanToActualText(text).runes.length;
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

        final _TextRange pre = range.copyWith();
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
          // if range is not changed, so maybe we should break.
          if (pre == range) {
            _hasVisualOverflow = false;
          } else {
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

  TextPainter _tryToFindNoOverflow1(_TextRange range, List<int> hideWidgets) {
    final InlineSpan inlineSpan = _cutOffInlineSpan(
      text,
      Accumulator(),
      range,
      hideWidgets,
      Accumulator(),
    );

    final TextPainter testTextPainter = _copyTextPainter(
      inlineSpan: inlineSpan,
      maxLines: _textPainter.maxLines,
    );

    _layoutChildren(
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
    _overflowSelection = overflowSelection;
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
        // https://github.com/dart-lang/sdk/issues/35798
        final List<int> runes = text.runes.toList();

        // if (kDebugMode) {
        //   if (runes.length != text.length) {}
        // }

        final List<int> finallyRunes = <int>[];
        //bool hasUtf16Surrogate = false;
        for (int i = 0; i < runes.length; i++) {
          final int index = i + offset.value;
          if (range.contains(index)) {
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
      textScaleFactor: _textPainter.textScaleFactor,
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
    if (overflowWidget != null && _overflowRect != null) {
      if (overflowWidget!.position == TextOverflowPosition.end) {
        final TextPosition position =
            _textPainter.getPositionForOffset(_overflowRect!.bottomLeft);
        if (result.extentOffset > position.offset) {
          result = result.copyWith(extentOffset: position.offset);
        }
      } else if (overflowWidget!.position == TextOverflowPosition.start) {
        final TextPosition position =
            _textPainter.getPositionForOffset(_overflowRect!.topRight);
        if (result.baseOffset < position.offset) {
          result = result.copyWith(baseOffset: position.offset);
        }
      }
    }
    return result;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (overflowWidget != null && _overflowRect != null) {
      final bool isHit = ExtendedTextLibraryUtils.hitTestChild(
          result, lastChild!, _effectiveOffset,
          position: position);
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

  @override
  void _computeChildrenWidthWithMaxIntrinsics(double height) {
    RenderBox? child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>.filled(
            childCount, PlaceholderDimensions.empty);
    int childIndex = 0;
    while (child != null && childIndex < textChildCount) {
      // Height and baseline is irrelevant as all text will be laid
      // out in a single line. Therefore, using 0.0 as a dummy for the height.
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: Size(child.getMaxIntrinsicWidth(double.infinity), 0.0),
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    _textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  @override
  void _computeChildrenWidthWithMinIntrinsics(double height) {
    RenderBox? child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>.filled(
            childCount, PlaceholderDimensions.empty);
    int childIndex = 0;
    while (child != null && childIndex < textChildCount) {
      // Height and baseline is irrelevant; only looking for the widest word or
      // placeholder. Therefore, using 0.0 as a dummy for height.
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: Size(child.getMinIntrinsicWidth(double.infinity), 0.0),
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    _textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  @override
  void _computeChildrenHeightWithMinIntrinsics(double width) {
    RenderBox? child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>.filled(
            childCount, PlaceholderDimensions.empty);
    int childIndex = 0;
    // Takes textScaleFactor into account because the content of the placeholder
    // span will be scaled up when it paints.
    width = width / textScaleFactor;
    while (child != null && childIndex < textChildCount) {
      final Size size = child.getDryLayout(BoxConstraints(maxWidth: width));
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: size,
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    _textPainter.setPlaceholderDimensions(placeholderDimensions);
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
