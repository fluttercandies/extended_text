import 'dart:ui';

import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../extended_render_paragraph.dart';
import '../extended_rich_text.dart';
import '../text_overflow_widget.dart';
import 'extended_text_selection_pointer_handler.dart';

///
///  create by zmtzawqlp on 2019/6/5
///

class ExtendedTextSelection extends StatefulWidget {
  const ExtendedTextSelection(
      {this.onTap,
      this.softWrap,
      this.locale,
      this.textDirection,
      this.textAlign,
      this.maxLines,
      this.textScaleFactor,
      this.overflow,
      this.text,
      this.selectionColor,
      this.dragStartBehavior,
      this.data,
      this.textSelectionControls,
      this.textWidthBasis,
      this.overFlowWidget,
      Key key})
      : super(key: key);
  final TextOverflowWidget overFlowWidget;


  final TextWidthBasis textWidthBasis;

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
  final TextOverflow overflow;

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

  final DragStartBehavior dragStartBehavior;

  final String data;

  final TextSelectionControls textSelectionControls;

  @override
  ExtendedTextSelectionState createState() => ExtendedTextSelectionState();
}

class ExtendedTextSelectionState extends State<ExtendedTextSelection>
    implements
        ExtendedTextSelectionGestureDetectorBuilderDelegate,
        TextSelectionDelegate {
  final GlobalKey _renderParagraphKey = GlobalKey();
  ExtendedRenderParagraph get _renderParagraph =>
      _renderParagraphKey.currentContext.findRenderObject();
  ExtendedTextSelectionOverlay _selectionOverlay;
  TextSelectionControls _textSelectionControls;
  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();
  ExtendedTextSelectionPointerHandlerState _pointerHandlerState;
  CommonTextSelectionGestureDetectorBuilder _selectionGestureDetectorBuilder;
  @override
  void initState() {
    _textSelectionControls = widget.textSelectionControls;
    _selectionGestureDetectorBuilder =
        CommonTextSelectionGestureDetectorBuilder(
      delegate: this,
      hideToolbar: hideToolbar,
      showToolbar: showToolbar,
      onTap: widget.onTap,
      context: context,
      requestKeyboard: null,
    );
    textEditingValue = TextEditingValue(
        text: widget.data, selection: TextSelection.collapsed(offset: 0));
    super.initState();
  }

  @override
  void didUpdateWidget(ExtendedTextSelection oldWidget) {
    if (oldWidget.textSelectionControls != this.widget.textSelectionControls) {
      _textSelectionControls = widget.textSelectionControls;
      final ThemeData themeData = Theme.of(context);
      switch (themeData.platform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          _textSelectionControls ??= extendedMaterialTextSelectionControls;
          break;
        case TargetPlatform.iOS:
        default:
          _textSelectionControls ??= extendedCupertinoTextSelectionControls;
          break;
      }
    }

    if (oldWidget.data != this.widget.data) {
      textEditingValue = TextEditingValue(
          text: widget.data, selection: TextSelection.collapsed(offset: 0));
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _pointerHandlerState?.selectionStates?.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    _pointerHandlerState = context
        .findAncestorStateOfType<ExtendedTextSelectionPointerHandlerState>();
    if (_pointerHandlerState != null) {
      if (!_pointerHandlerState.selectionStates.contains(this)) {
        _pointerHandlerState.selectionStates.add(this);
      }
    }

    switch (themeData.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        forcePressEnabled = false;
        _textSelectionControls ??= extendedMaterialTextSelectionControls;
        break;
      case TargetPlatform.iOS:
      default:
        forcePressEnabled = true;
        _textSelectionControls ??= extendedCupertinoTextSelectionControls;
        break;
    }

    Widget result = RepaintBoundary(
        child: CompositedTransformTarget(
            link: _toolbarLayerLink,
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
                key: _renderParagraphKey,
                selectionColor: widget.selectionColor,
                selection: textEditingValue.selection,
                onSelectionChanged: _handleSelectionChanged,
                startHandleLayerLink: _startHandleLayerLink,
                endHandleLayerLink: _endHandleLayerLink,
                textWidthBasis: widget.textWidthBasis,
                overFlowWidget: widget.overFlowWidget,
              ),
            )));

    result = _selectionGestureDetectorBuilder.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: result,
    );
    return result;
  }

  VoidCallback _semanticsOnCopy(TextSelectionControls controls) {
    return controls?.canCopy(this) == true
        ? () => controls.handleCopy(this)
        : null;
  }

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause cause) {
    textEditingValue = textEditingValue?.copyWith(selection: selection);
    _hideSelectionOverlayIfNeeded();
    //todo
//    if (widget.selectionControls != null) {
    _selectionOverlay = ExtendedTextSelectionOverlay(
        context: context,
        debugRequiredFor: widget,
        toolbarLayerLink: _toolbarLayerLink,
        startHandleLayerLink: _startHandleLayerLink,
        endHandleLayerLink: _endHandleLayerLink,
        renderObject: _renderParagraph,
        value: textEditingValue,
        dragStartBehavior: widget.dragStartBehavior,
        selectionDelegate: this,
        onSelectionHandleTapped: _handleSelectionHandleTapped,
        handlesVisible: true,
        selectionControls: _textSelectionControls);
    final bool longPress = cause == SelectionChangedCause.longPress;
    if (cause != SelectionChangedCause.keyboard &&
        (widget.text.toPlainText().isNotEmpty || longPress))
      _selectionOverlay.showHandles();
//      if (widget.onSelectionChanged != null)
//        widget.onSelectionChanged(selection, cause);
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
  bool get copyEnabled => !textEditingValue.selection.isCollapsed;

  @override
  bool get cutEnabled => false;

  @override
  bool get pasteEnabled => false;

  @override
  bool get selectAllEnabled =>
      textEditingValue.text.isNotEmpty &&
      !(textEditingValue.selection.baseOffset == 0 &&
          textEditingValue.selection.extentOffset ==
              textEditingValue.text.length);

  @override
  void bringIntoView(TextPosition position) {
    //do nothing
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

  /// Toggles the visibility of the toolbar.
  void toggleToolbar() {
    assert(_selectionOverlay != null);
    if (_selectionOverlay.toolbarIsVisible) {
      hideToolbar();
    } else {
      showToolbar();
    }
  }

  void _hideSelectionOverlayIfNeeded() {
    _selectionOverlay?.hide();
    _selectionOverlay = null;
  }

  ///hittest
  bool containsPosition(Offset position) {
    //_hideSelectionOverlayIfNeeded();
    return _renderParagraph.containsPosition(position);
  }

  ///clear selection if it has.
  void clearSelection() {
    if (!textEditingValue.selection.isCollapsed) {
      textEditingValue = textEditingValue.copyWith(
          selection: TextSelection.collapsed(offset: 0));
    }
  }

  /// Toggle the toolbar when a selection handle is tapped.
  void _handleSelectionHandleTapped() {
    if (textEditingValue.selection.isCollapsed) {
      toggleToolbar();
    }
  }

  @override
  bool forcePressEnabled;

  @override
  ExtendedTextSelectionRenderObject get renderEditable => _renderParagraph;

  @override
  bool get selectionEnabled => true;
}
