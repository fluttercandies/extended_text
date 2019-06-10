import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../extended_text.dart';
import '../extended_rich_text.dart';
import '../extended_text_typedef.dart';
import 'extended_text_selection_overlay.dart';
import 'extended_text_selection_pointer_handler.dart';
import 'selection_controls/cupertino_text_selection_controls.dart';
import 'selection_controls/material_text_selection_controls.dart';

///
///  create by zmtzawqlp on 2019/6/5
///

class ExtendedTextSelection extends StatefulWidget {
  final WidgetKeyBuilder builder;
  final GestureTapCallback onTap;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [data] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient [Directionality], if any.
  final TextDirection textDirection;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale locale;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final ExtendedTextOverflow overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// The value given to the constructor as textScaleFactor. If null, will
  /// use the [MediaQueryData.textScaleFactor] obtained from the ambient
  /// [MediaQuery], or 1.0 if there is no [MediaQuery] in scope.
  final double textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  ///
  /// If this is null, but there is an ambient [DefaultTextStyle] that specifies
  /// an explicit number for its [DefaultTextStyle.maxLines], then the
  /// [DefaultTextStyle] value will take precedence. You can use a [RichText]
  /// widget directly to entirely override the [DefaultTextStyle].
  final int maxLines;

  final TextSpan text;

  final Color selectionColor;

  /// the custom text over flow TextSpan
  final OverFlowTextSpan overFlowTextSpan;

  final DragStartBehavior dragStartBehavior;

  final String data;

  final ExtendedTextSelectionControls textSelectionControls;

  ExtendedTextSelection(
      {this.builder,
      this.onTap,
      this.softWrap,
      this.locale,
      this.textDirection,
      this.textAlign,
      this.maxLines,
      this.textScaleFactor,
      this.overflow,
      this.text,
      this.overFlowTextSpan,
      this.selectionColor,
      this.dragStartBehavior,
      this.data,
      this.textSelectionControls,
      Key key})
      : super(key: key);

  @override
  ExtendedTextSelectionState createState() => ExtendedTextSelectionState();
}

class ExtendedTextSelectionState extends State<ExtendedTextSelection>
    implements TextSelectionDelegate {
  final GlobalKey _renderParagraphKey = GlobalKey();
  ExtendedRenderParagraph get _renderParagraph =>
      _renderParagraphKey.currentContext.findRenderObject();
  ExtendedTextSelectionOverlay _selectionOverlay;
  ExtendedTextSelectionControls _textSelectionControls;
  final LayerLink _layerLink = LayerLink();
  ExtendedTextSelectionPointerHandlerState _pointerHandlerState;
  @override
  void initState() {
    _textSelectionControls = widget.textSelectionControls;
    textEditingValue = TextEditingValue(
        text: widget.data, selection: TextSelection.collapsed(offset: 0));

    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    _pointerHandlerState?.selectionStates.remove(this);
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    _pointerHandlerState = context.ancestorStateOfType(
        TypeMatcher<ExtendedTextSelectionPointerHandlerState>());
    if (_pointerHandlerState != null) {
      if (!_pointerHandlerState.selectionStates.contains(this)) {
        _pointerHandlerState.selectionStates.add(this);
      }
    }
    bool forcePressEnabled;

    switch (themeData.platform) {
      case TargetPlatform.iOS:
        forcePressEnabled = true;
        _textSelectionControls ??= extendedCupertinoTextSelectionControls;
        break;

      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        forcePressEnabled = false;
        _textSelectionControls ??= extendedMaterialTextSelectionControls;
        break;
    }

    Widget result = TextSelectionGestureDetector(
        onTapDown: _handleTapDown,
        onForcePressStart: forcePressEnabled ? _handleForcePressStarted : null,
        onSingleTapUp: _handleSingleTapUp,
        // onSingleTapCancel: _handleSingleTapCancel,
        onSingleLongTapStart: _handleSingleLongTapStart,
        onSingleLongTapMoveUpdate: _handleSingleLongTapMoveUpdate,
        onSingleLongTapEnd: _handleSingleLongTapEnd,
        onDoubleTapDown: _handleDoubleTapDown,
        onDragSelectionStart: _handleMouseDragSelectionStart,
        onDragSelectionUpdate: _handleMouseDragSelectionUpdate,
        behavior: HitTestBehavior.translucent,
        child: RepaintBoundary(
            child: CompositedTransformTarget(
                link: _layerLink,
                child: Semantics(
                  onCopy: _semanticsOnCopy(_textSelectionControls),
                  child: ExtendedRichText(
                      textAlign: widget.textAlign,
                      textDirection: widget
                          .textDirection, // RichText uses Directionality.of to obtain a default if this is null.
                      locale: widget
                          .locale, // RichText uses Localizations.localeOf to obtain a default if this is null
                      softWrap: widget.softWrap,
                      overflow: widget.overflow,
                      textScaleFactor: widget.textScaleFactor,
                      maxLines: widget.maxLines,
                      text: widget.text,
                      overFlowTextSpan: widget.overFlowTextSpan,
                      key: _renderParagraphKey,
                      selectionColor: widget.selectionColor,
                      selection: textEditingValue.selection,
                      onSelectionChanged: _handleSelectionChanged),
                ))));

    return result;
  }

  void _handleTapDown(TapDownDetails details) {
    _renderParagraph.handleTapDown(details);
  }

  void _handleForcePressStarted(ForcePressDetails details) {
    _renderParagraph.selectWordsInRange(
      from: details.globalPosition,
      cause: SelectionChangedCause.forcePress,
    );
    showToolbar();
  }

  void _handleSingleTapUp(TapUpDetails details) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        _renderParagraph.selectWordEdge(cause: SelectionChangedCause.tap);
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        _renderParagraph.selectPosition(cause: SelectionChangedCause.tap);
        break;
    }

    if (widget.onTap != null) widget.onTap();
  }

  void _handleSingleLongTapStart(LongPressStartDetails details) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        _renderParagraph.selectPositionAt(
          from: details.globalPosition,
          cause: SelectionChangedCause.longPress,
        );
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        _renderParagraph.selectWord(cause: SelectionChangedCause.longPress);
        Feedback.forLongPress(context);
        break;
    }
  }

  void _handleSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        _renderParagraph.selectPositionAt(
          from: details.globalPosition,
          cause: SelectionChangedCause.longPress,
        );
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        _renderParagraph.selectWordsInRange(
          from: details.globalPosition - details.offsetFromOrigin,
          to: details.globalPosition,
          cause: SelectionChangedCause.longPress,
        );
        break;
    }
  }

  void _handleSingleLongTapEnd(LongPressEndDetails details) {
    showToolbar();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _renderParagraph.selectWord(cause: SelectionChangedCause.doubleTap);
    showToolbar();
  }

  void _handleMouseDragSelectionStart(DragStartDetails details) {
    _renderParagraph.selectPositionAt(
      from: details.globalPosition,
      cause: SelectionChangedCause.drag,
    );
  }

  void _handleMouseDragSelectionUpdate(
    DragStartDetails startDetails,
    DragUpdateDetails updateDetails,
  ) {
    _renderParagraph.selectPositionAt(
      from: startDetails.globalPosition,
      to: updateDetails.globalPosition,
      cause: SelectionChangedCause.drag,
    );
  }

  void _handleSelectionChanged(TextSelection selection,
      ExtendedRenderParagraph renderObject, SelectionChangedCause cause) {
    textEditingValue = textEditingValue?.copyWith(selection: selection);
    _hideSelectionOverlayIfNeeded();
    //todo
//    if (widget.selectionControls != null) {
    _selectionOverlay = ExtendedTextSelectionOverlay(
        context: context,
        debugRequiredFor: widget,
        layerLink: _layerLink,
        renderObject: renderObject,
        value: textEditingValue,
        dragStartBehavior: widget.dragStartBehavior,
        selectionDelegate: this,
        selectionControls: _textSelectionControls);
    final bool longPress = cause == SelectionChangedCause.longPress;
    if (cause != SelectionChangedCause.keyboard &&
        (widget.text.toPlainText().isNotEmpty || longPress))
      _selectionOverlay.showHandles();
//      if (widget.onSelectionChanged != null)
//        widget.onSelectionChanged(selection, cause);
  }

  VoidCallback _semanticsOnCopy(ExtendedTextSelectionControls controls) {
    return controls?.canCopy(this) == true
        ? () => controls.handleCopy(this)
        : null;
  }

  TextEditingValue _value;
  @override
  TextEditingValue get textEditingValue => _value;

  @override
  set textEditingValue(TextEditingValue value) {
    //value = _handleSpecialTextSpan(value);
    _selectionOverlay?.update(value);
    if (mounted) {
      setState(() {
        _value = value;
      });
    }
    //_formatAndSetValue(value);
  }

  @override
  void bringIntoView(TextPosition position) {
//    _scrollController.jumpTo(_getScrollOffsetForCaret(
//        renderEditable.getLocalRectForCaret(position)));
  }

  /// Shows the selection toolbar at the location of the current cursor.
  ///
  /// Returns `false` if a toolbar couldn't be shown such as when no text
  /// selection currently exists.
  bool showToolbar() {
    if (_selectionOverlay == null) return false;
    _selectionOverlay.showToolbar();
    return true;
  }

  @override
  void hideToolbar() {
    _selectionOverlay?.hide();
  }

  void _hideSelectionOverlayIfNeeded() {
    _selectionOverlay?.hide();
    _selectionOverlay = null;
  }

  bool containsPosition(Offset position) {
    //_hideSelectionOverlayIfNeeded();
    return _renderParagraph.containsPosition(position);
  }

  void clearSelection() {
    if (!textEditingValue.selection.isCollapsed) {
      textEditingValue = textEditingValue.copyWith(
          selection: TextSelection.collapsed(offset: 0));
    }
  }
}
