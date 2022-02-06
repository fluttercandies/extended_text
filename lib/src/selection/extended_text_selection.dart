// ignore_for_file: always_put_control_body_on_new_line

import 'dart:ui';

import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../extended_render_paragraph.dart';
import '../extended_rich_text.dart';
import '../text_overflow_widget.dart';
import 'extended_text_selection_pointer_handler.dart';

///
///  create by zmtzawqlp on 2019/6/5
///

class ExtendedTextSelection extends StatefulWidget {
  const ExtendedTextSelection({
    this.onTap,
    this.softWrap,
    this.locale,
    this.textDirection,
    this.textAlign,
    this.maxLines,
    this.textScaleFactor,
    this.overflow,
    this.text,
    this.selectionColor,
    this.dragStartBehavior = DragStartBehavior.start,
    this.data,
    this.textSelectionControls,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionHeightStyle = BoxHeightStyle.tight,
    this.selectionWidthStyle = BoxWidthStyle.tight,
    this.overFlowWidget,
    this.strutStyle,
    this.shouldShowSelectionHandles,
    this.textSelectionGestureDetectorBuilder,
    Key? key,
  }) : super(key: key);

  /// create custom TextSelectionGestureDetectorBuilder
  final TextSelectionGestureDetectorBuilderCallback?
      textSelectionGestureDetectorBuilder;

  /// Whether should show selection handles
  /// handles are not shown in desktop or web as default
  /// you can define your behavior
  final ShouldShowSelectionHandlesCallback? shouldShowSelectionHandles;

  final TextOverflowWidget? overFlowWidget;

  /// Controls how tall the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxHeightStyle] for details on available styles.
  final BoxHeightStyle selectionHeightStyle;

  /// Controls how wide the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxWidthStyle] for details on available styles.
  final BoxWidthStyle selectionWidthStyle;

  final TextHeightBehavior? textHeightBehavior;

  final TextWidthBasis? textWidthBasis;

  final GestureTapCallback? onTap;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

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
  final TextDirection? textDirection;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale? locale;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool? softWrap;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// The value given to the constructor as textScaleFactor. If null, will
  /// use the [MediaQueryData.textScaleFactor] obtained from the ambient
  /// [MediaQuery], or 1.0 if there is no [MediaQuery] in scope.
  final double? textScaleFactor;

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
  final int? maxLines;

  final InlineSpan? text;

  final Color? selectionColor;

  final DragStartBehavior dragStartBehavior;

  final String? data;

  final TextSelectionControls? textSelectionControls;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle? strutStyle;

  @override
  ExtendedTextSelectionState createState() => ExtendedTextSelectionState();
}

class ExtendedTextSelectionState extends State<ExtendedTextSelection>
    //with TextEditingActionTarget
    implements
        ExtendedTextSelectionGestureDetectorBuilderDelegate,
        TextSelectionDelegate,
        TextInputClient {
  final GlobalKey _renderParagraphKey = GlobalKey();
  ExtendedRenderParagraph? get _renderParagraph =>
      _renderParagraphKey.currentContext!.findRenderObject()
          as ExtendedRenderParagraph?;
  ExtendedTextSelectionOverlay? _selectionOverlay;
  TextSelectionControls? _textSelectionControls;
  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();
  ExtendedTextSelectionPointerHandlerState? _pointerHandlerState;
  late CommonTextSelectionGestureDetectorBuilder
      _selectionGestureDetectorBuilder;
  ClipboardStatusNotifier? _clipboardStatus;

  FocusNode? _focusNode;
  FocusAttachment? _focusAttachment;
  FocusNode get _effectiveFocusNode => _focusNode ??= FocusNode();
  bool get _hasFocus => _effectiveFocusNode.hasFocus;

  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    SelectAllTextIntent: _makeOverridable(_SelectAllAction(this)),
    CopySelectionTextIntent: _makeOverridable(_CopySelectionAction(this)),
  };
  @override
  void initState() {
    super.initState();
    _initGestureDetectorBuilder();
    _textSelectionControls = widget.textSelectionControls;
    _clipboardStatus =
        kIsWeb && !_selectionGestureDetectorBuilder.showToolbarInWeb
            ? null
            : ClipboardStatusNotifier();
    _clipboardStatus?.addListener(_onChangedClipboardStatus);
    _focusAttachment = _effectiveFocusNode.attach(context);
    _effectiveFocusNode.addListener(_handleFocusChanged);
    textEditingValue = TextEditingValue(
        text: widget.data!,
        selection: const TextSelection.collapsed(offset: 0));
    _effectiveFocusNode.canRequestFocus = true;
  }

  void _initGestureDetectorBuilder() {
    if (widget.textSelectionGestureDetectorBuilder != null) {
      _selectionGestureDetectorBuilder =
          widget.textSelectionGestureDetectorBuilder!(
        delegate: this,
        hideToolbar: hideToolbar,
        showToolbar: showToolbar,
        onTap: widget.onTap,
        context: context,
        requestKeyboard: requestKeyboard,
      );
    } else {
      _selectionGestureDetectorBuilder =
          CommonTextSelectionGestureDetectorBuilder(
        delegate: this,
        hideToolbar: hideToolbar,
        showToolbar: showToolbar,
        onTap: widget.onTap,
        context: context,
        requestKeyboard: requestKeyboard,
      );
    }
  }

  @override
  void didUpdateWidget(ExtendedTextSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textSelectionControls != widget.textSelectionControls) {
      _textSelectionControls = widget.textSelectionControls;
      final ThemeData theme = Theme.of(context);
      switch (theme.platform) {
        case TargetPlatform.iOS:
          _textSelectionControls ??= cupertinoTextSelectionControls;

          break;

        case TargetPlatform.macOS:
          _textSelectionControls ??= cupertinoDesktopTextSelectionControls;

          break;

        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          _textSelectionControls ??= materialTextSelectionControls;

          break;

        case TargetPlatform.linux:
        case TargetPlatform.windows:
          _textSelectionControls ??= desktopTextSelectionControls;
          break;
      }
    }

    if (oldWidget.data != widget.data) {
      textEditingValue = TextEditingValue(
          text: widget.data!,
          selection: const TextSelection.collapsed(offset: 0));
    }
    if (pasteEnabled && widget.textSelectionControls?.canPaste(this) == true) {
      _clipboardStatus?.update();
    }

    if (widget.textSelectionGestureDetectorBuilder !=
        oldWidget.textSelectionGestureDetectorBuilder)
      _initGestureDetectorBuilder();
  }

  @override
  void dispose() {
    _pointerHandlerState?.selectionStates.remove(this);
    _clipboardStatus?.removeListener(_onChangedClipboardStatus);
    _clipboardStatus?.dispose();
    _focusNode?.dispose();
    _focusAttachment?.detach();
    _closeInputConnectionIfNeeded();
    super.dispose();
  }

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  void requestKeyboard() {
    if (_hasFocus) {
      _openInputConnection();
    } else {
      _effectiveFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    _focusAttachment?.reparent();
    final ThemeData theme = Theme.of(context);
    final TextSelectionThemeData selectionTheme =
        TextSelectionTheme.of(context);
    _pointerHandlerState = context
        .findAncestorStateOfType<ExtendedTextSelectionPointerHandlerState>();
    if (_pointerHandlerState != null) {
      if (!_pointerHandlerState!.selectionStates.contains(this)) {
        _pointerHandlerState!.selectionStates.add(this);
      }
    }
    VoidCallback? handleDidGainAccessibilityFocus;
    Color? selectionColor = widget.selectionColor;

    switch (theme.platform) {
      case TargetPlatform.iOS:
        final CupertinoThemeData cupertinoTheme = CupertinoTheme.of(context);
        forcePressEnabled = true;
        _textSelectionControls ??= cupertinoTextSelectionControls;

        selectionColor ??= selectionTheme.selectionColor ??
            cupertinoTheme.primaryColor.withOpacity(0.40);

        break;

      case TargetPlatform.macOS:
        final CupertinoThemeData cupertinoTheme = CupertinoTheme.of(context);
        forcePressEnabled = false;
        _textSelectionControls ??= cupertinoDesktopTextSelectionControls;

        selectionColor ??= selectionTheme.selectionColor ??
            cupertinoTheme.primaryColor.withOpacity(0.40);
        handleDidGainAccessibilityFocus = () {
          // Automatically activate the TextField when it receives accessibility focus.
          if (!_effectiveFocusNode.hasFocus &&
              _effectiveFocusNode.canRequestFocus) {
            _effectiveFocusNode.requestFocus();
          }
        };
        break;

      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        forcePressEnabled = false;
        _textSelectionControls ??= materialTextSelectionControls;
        selectionColor ??= selectionTheme.selectionColor ??
            theme.colorScheme.primary.withOpacity(0.40);
        break;

      case TargetPlatform.linux:
      case TargetPlatform.windows:
        forcePressEnabled = false;
        _textSelectionControls ??= desktopTextSelectionControls;
        selectionColor ??= selectionTheme.selectionColor ??
            theme.colorScheme.primary.withOpacity(0.40);
        if (theme.platform == TargetPlatform.windows)
          handleDidGainAccessibilityFocus = () {
            // Automatically activate the TextField when it receives accessibility focus.
            if (!_effectiveFocusNode.hasFocus &&
                _effectiveFocusNode.canRequestFocus) {
              _effectiveFocusNode.requestFocus();
            }
          };
        break;
    }

    Widget result = RepaintBoundary(
        child: CompositedTransformTarget(
            link: _toolbarLayerLink,
            child: Semantics(
              onCopy: _semanticsOnCopy(_textSelectionControls),
              onDidGainAccessibilityFocus: handleDidGainAccessibilityFocus,
              child: ExtendedRichText(
                textAlign: widget.textAlign!,
                textDirection: widget
                    .textDirection, // RichText uses Directionality.of to obtain a default if this is null.
                locale: widget
                    .locale, // RichText uses Localizations.localeOf to obtain a default if this is null
                softWrap: widget.softWrap!,
                overflow: widget.overflow!,
                textScaleFactor: widget.textScaleFactor!,
                maxLines: widget.maxLines,
                text: widget.text!,
                key: _renderParagraphKey,
                selectionColor: selectionColor,
                selection: textEditingValue.selection,
                startHandleLayerLink: _startHandleLayerLink,
                endHandleLayerLink: _endHandleLayerLink,
                textWidthBasis: widget.textWidthBasis!,
                selectionWidthStyle: widget.selectionWidthStyle,
                selectionHeightStyle: widget.selectionHeightStyle,
                overflowWidget: widget.overFlowWidget,
                hasFocus: _effectiveFocusNode.hasFocus,
                textSelectionDelegate: this,
                strutStyle: widget.strutStyle,
              ),
            )));

    result = _selectionGestureDetectorBuilder.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: result,
    );
    result = MouseRegion(
      child: Actions(
        actions: _actions,
        child: Focus(
          focusNode: _effectiveFocusNode,
          includeSemantics: false,
          debugLabel: 'ExtendedTextSelection',
          child: result,
        ),
      ),
      cursor: SystemMouseCursors.text,
    );
    return result;
  }

  VoidCallback? _semanticsOnCopy(TextSelectionControls? controls) {
    return controls?.canCopy(this) == true
        ? () => controls!.handleCopy(this, _clipboardStatus)
        : null;
  }

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause? cause) {
    // We return early if the selection is not valid. This can happen when the
    // text of [EditableText] is updated at the same time as the selection is
    // changed by a gesture event.
    // if (!widget.controller.isSelectionWithinTextBounds(selection)) {
    //   return;
    // }

    // if (renderEditable.hasSpecialInlineSpanBase) {
    //   final TextEditingValue value = correctCaretOffset(
    //       _value, renderEditable.text!, _textInputConnection,
    //       newSelection: selection);

    //   ///change
    //   if (value != _value) {
    //     selection = value.selection;
    //     _value = value;
    //   }
    // }

    // final bool textChanged = widget.controller.text != renderEditable.plainText;
    // // zmt
    // // if textChanged, text was changed by user,
    // // _didChangeTextEditingValue setstate to change text of ExtendedRenderEditable
    // // but still slower than this method.
    // if (!textChanged) {
    //   widget.controller.selection = selection;
    // }

    // This will show the keyboard for all selection changes on the
    // EditableWidget, not just changes triggered by user gestures.
    requestKeyboard();
    if (_textSelectionControls == null) {
      _selectionOverlay?.dispose();
      _selectionOverlay = null;
    } else {
      if (_selectionOverlay == null) {
        _selectionOverlay = ExtendedTextSelectionOverlay(
          clipboardStatus: _clipboardStatus,
          context: context,
          value: _value,
          debugRequiredFor: widget,
          toolbarLayerLink: _toolbarLayerLink,
          startHandleLayerLink: _startHandleLayerLink,
          endHandleLayerLink: _endHandleLayerLink,
          renderObject: renderEditable,
          selectionControls: _textSelectionControls,
          selectionDelegate: this,
          dragStartBehavior: widget.dragStartBehavior,
          onSelectionHandleTapped: _handleSelectionHandleTapped,
        );
      } else {
        _selectionOverlay!.update(_value);
      }
      _selectionOverlay!.handlesVisible = _shouldShowSelectionHandles(cause);
      _selectionOverlay!.showHandles();
    }
  }

  late TextEditingValue _value;
  @override
  TextEditingValue get textEditingValue => _value;

  @override
  set textEditingValue(TextEditingValue value) {
    //value = _handleSpecialTextSpan(value);

    _selectionOverlay?.update(value);
    _textInputConnection?.setEditingState(value);
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
  /// Returns `false` if a toolbar couldn't be shown, such as when the toolbar
  /// is already shown, or when no text selection currently exists.
  bool showToolbar() {
    // Web is using native dom elements to enable clipboard functionality of the
    // toolbar: copy, paste, select, cut. It might also provide additional
    // functionality depending on the browser (such as translate). Due to this
    // we should not show a Flutter toolbar for the editable text elements.
    if (kIsWeb && !_selectionGestureDetectorBuilder.showToolbarInWeb) {
      return false;
    }

    if (_selectionOverlay == null || _selectionOverlay!.toolbarIsVisible) {
      return false;
    }

    _selectionOverlay!.showToolbar();
    return true;
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    if (hideHandles) {
      // Hide the handles and the toolbar.
      _selectionOverlay?.hide();
    } else if (_selectionOverlay?.toolbarIsVisible ?? false) {
      // Hide only the toolbar but not the handles.
      _selectionOverlay?.hideToolbar();
    }
  }

  /// Toggles the visibility of the toolbar.
  void toggleToolbar() {
    assert(_selectionOverlay != null);
    if (_selectionOverlay!.toolbarIsVisible) {
      hideToolbar();
    } else {
      showToolbar();
    }
  }

  /// hittest
  bool containsPosition(Offset position) {
    //_hideSelectionOverlayIfNeeded();
    return _renderParagraph!.containsPosition(position);
  }

  /// clear selection if it has.
  void clearSelection() {
    if (!textEditingValue.selection.isCollapsed) {
      textEditingValue = textEditingValue.copyWith(
          selection: const TextSelection.collapsed(offset: 0));
    }
  }

  /// Toggle the toolbar when a selection handle is tapped.
  void _handleSelectionHandleTapped() {
    if (textEditingValue.selection.isCollapsed) {
      toggleToolbar();
    }
  }

  @override
  late bool forcePressEnabled;

  @override
  ExtendedTextSelectionRenderObject get renderEditable => _renderParagraph!;

  @override
  bool get selectionEnabled => true;

  /// Whether to create an input connection with the platform for text editing
  /// or not.
  ///
  /// Read-only input fields do not need a connection with the platform since
  /// there's no need for text editing capabilities (e.g. virtual keyboard).
  ///
  /// On the web, we always need a connection because we want some browser
  /// functionalities to continue to work on read-only input fields like:
  ///
  /// - Relevant context menu.
  /// - cmd/ctrl+c shortcut to copy.
  /// - cmd/ctrl+a to select all.
  /// - Changing the selection using a physical keyboard.
  bool get _shouldCreateInputConnection => kIsWeb;
  bool get _hasInputConnection =>
      _textInputConnection != null && _textInputConnection!.attached;

  TextInputConnection? _textInputConnection;

  void _openInputConnection() {
    if (!_shouldCreateInputConnection) {
      return;
    }
    if (!_hasInputConnection) {
      final TextEditingValue localValue = _value;

      // When _needsAutofill == true && currentAutofillScope == null, autofill
      // is allowed but saving the user input from the text field is
      // discouraged.
      //
      // In case the autofillScope changes from a non-null value to null, or
      // _needsAutofill changes to false from true, the platform needs to be
      // notified to exclude this field from the autofill context. So we need to
      // provide the autofillId.
      _textInputConnection = TextInput.attach(this, textInputConfiguration);

      _textInputConnection!.show();

      final TextStyle style = widget.text!.style!;
      _textInputConnection!
        ..setStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          textDirection: widget.textDirection!,
          textAlign: widget.textAlign!,
        )
        ..setEditingState(localValue);
    } else {
      _textInputConnection!.show();
    }
  }

  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
    }
  }

  @override
  void connectionClosed() {
    if (_hasInputConnection) {
      _textInputConnection!.connectionClosedReceived();
      _textInputConnection = null;
    }
  }

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  TextEditingValue? get currentTextEditingValue => _value;

  @override
  void performAction(TextInputAction action) {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void updateEditingValue(TextEditingValue value) {
    // This method handles text editing state updates from the platform text
    // input plugin. The [EditableText] may not have the focus or an open input
    // connection, as autofill can update a disconnected [EditableText].

    // Since we still have to support keyboard select, this is the best place
    // to disable text updating.
    if (!_shouldCreateInputConnection) {
      return;
    }

    // // In the read-only case, we only care about selection changes, and reject
    // // everything else.

    value = _value.copyWith(selection: value.selection);

    if (value == _value) {
      // This is possible, for example, when the numeric keyboard is input,
      // the engine will notify twice for the same value.
      // Track at https://github.com/flutter/flutter/issues/65811
      return;
    }

    if (value.text == _value.text && value.composing == _value.composing) {
      // `selection` is the only change.
      setState(() {
        _value = _value.copyWith(selection: value.selection);
        _handleSelectionChanged(
            value.selection, SelectionChangedCause.keyboard);
      });
    } else {
      //hideToolbar();
      textEditingValue = value;
    }
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  void _handleFocusChanged() {
    _openOrCloseInputConnectionIfNeeded();
    setState(() {});
  }

  void _openOrCloseInputConnectionIfNeeded() {
    if (_hasFocus && _focusNode!.consumeKeyboardToken()) {
      _openInputConnection();
    } else if (!_hasFocus) {
      _closeInputConnectionIfNeeded();
      //widget.controller.clearComposing();
    }
  }

  TextInputConfiguration get textInputConfiguration =>
      const TextInputConfiguration(
        inputAction: TextInputAction.newline,
        inputType: TextInputType.multiline,
      );

  @override
  void userUpdateTextEditingValue(
      TextEditingValue value, SelectionChangedCause cause) {
    // _selectionOverlay?.update(value);
    _textInputConnection?.setEditingState(value);
    final TextSelection old = _value.selection;
    _value = value;
    if (old != value.selection ||
        cause == SelectionChangedCause.longPress ||
        cause == SelectionChangedCause.keyboard) {
      _handleSelectionChanged(value.selection, cause);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    final TextSelection selection = textEditingValue.selection;
    final String text = textEditingValue.text;
    if (selection.isCollapsed || !selection.isValid) {
      return;
    }
    Clipboard.setData(ClipboardData(text: selection.textInside(text)));
    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
      hideToolbar(false);

      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          // Collapse the selection and hide the toolbar and handles.
          userUpdateTextEditingValue(
            TextEditingValue(
              text: textEditingValue.text,
              selection: TextSelection.collapsed(
                  offset: textEditingValue.selection.end),
            ),
            SelectionChangedCause.toolbar,
          );
          break;
      }
    }
  }

  @override
  void cutSelection(SelectionChangedCause cause) {}

  /// {@macro flutter.widgets.TextEditingActionTarget.pasteText}
  @override
  Future<void> pasteText(SelectionChangedCause cause) async {}

  /// Select the entire text value.
  @override
  void selectAll(SelectionChangedCause cause) {
    textEditingValue = textEditingValue.copyWith(
        selection: textEditingValue.selection.copyWith(
      baseOffset: 0,
      extentOffset: textEditingValue.text.length,
    ));
    if (cause == SelectionChangedCause.toolbar) {
      bringIntoView(textEditingValue.selection.extent);
    }
  }

  Action<T> _makeOverridable<T extends Intent>(Action<T> defaultAction) {
    return Action<T>.overridable(
        context: context, defaultAction: defaultAction);
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    if (widget.shouldShowSelectionHandles != null) {
      return widget.shouldShowSelectionHandles!(
        cause,
        _selectionGestureDetectorBuilder,
        _value,
      );
    }
    // When the text field is activated by something that doesn't trigger the
    // selection overlay, we shouldn't show the handles either.
    if (!_selectionGestureDetectorBuilder.shouldShowSelectionToolbar)
      return false;

    if (cause == SelectionChangedCause.keyboard) return false;

    if (_value.selection.isCollapsed) return false;

    if (cause == SelectionChangedCause.longPress) return true;

    if (_value.text.isNotEmpty) return true;

    return false;
  }
}

class _CopySelectionAction extends ContextAction<CopySelectionTextIntent> {
  _CopySelectionAction(this.state);

  final ExtendedTextSelectionState state;

  @override
  void invoke(CopySelectionTextIntent intent, [BuildContext? context]) {
    if (intent.collapseSelection) {
      state.cutSelection(intent.cause);
    } else {
      state.copySelection(intent.cause);
    }
  }

  @override
  bool get isActionEnabled =>
      state._value.selection.isValid && !state._value.selection.isCollapsed;
}

class _SelectAllAction extends ContextAction<SelectAllTextIntent> {
  _SelectAllAction(this.state);

  final ExtendedTextSelectionState state;

  @override
  Object? invoke(SelectAllTextIntent intent, [BuildContext? context]) {
    // zmtzawqlp:  we don't have UpdateSelectionIntent here
    state.selectAll(intent.cause);
    return Actions.invoke(
      context!,
      UpdateSelectionIntent(
        state._value,
        TextSelection(baseOffset: 0, extentOffset: state._value.text.length),
        intent.cause,
      ),
    );
  }

  @override
  bool get isActionEnabled => true;
}
