///
///  create by zmtzawqlp on 2019/6/5
///

import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../extended_render_paragraph.dart';
import 'selection_controls/extended_text_selection_controls.dart';

final List<OverlayEntry> _entries = <OverlayEntry>[];

/// The text position that a give selection handle manipulates. Dragging the
/// [start] handle always moves the [start]/[baseOffset] of the selection.
enum _TextSelectionHandlePosition { start, end }

/// An object that manages a pair of text selection handles.
///
/// The selection handles are displayed in the [Overlay] that most closely
/// encloses the given [BuildContext].
class ExtendedTextSelectionOverlay {
  /// Creates an object that manages overly entries for selection handles.
  ///
  /// The [context] must not be null and must have an [Overlay] as an ancestor.
  ExtendedTextSelectionOverlay({
    @required TextEditingValue value,
    @required this.context,
    this.debugRequiredFor,
    @required this.layerLink,
    @required this.renderObject,
    this.selectionControls,
    this.selectionDelegate,
    this.dragStartBehavior = DragStartBehavior.start,
  })  : assert(value != null),
        assert(context != null),
        _value = value {
    final OverlayState overlay = Overlay.of(context);
    assert(
        overlay != null,
        'No Overlay widget exists above $context.\n'
        'Usually the Navigator created by WidgetsApp provides the overlay. Perhaps your '
        'app content was created above the Navigator with the WidgetsApp builder parameter.');
    _toolbarController =
        AnimationController(duration: fadeDuration, vsync: overlay);
  }

  /// The context in which the selection handles should appear.
  ///
  /// This context must have an [Overlay] as an ancestor because this object
  /// will display the text selection handles in that [Overlay].
  final BuildContext context;

  /// Debugging information for explaining why the [Overlay] is required.
  final Widget debugRequiredFor;

  /// The object supplied to the [CompositedTransformTarget] that wraps the text
  /// field.
  final LayerLink layerLink;

  // TODO(mpcomplete): what if the renderObject is removed or replaced, or
  // moves? Not sure what cases I need to handle, or how to handle them.
  /// The editable line in which the selected text is being displayed.
  final ExtendedRenderParagraph renderObject;

  /// Builds text selection handles and toolbar.
  final ExtendedTextSelectionControls selectionControls;

  /// The delegate for manipulating the current selection in the owning
  /// text field.
  final TextSelectionDelegate selectionDelegate;

  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], handle drag behavior will
  /// begin upon the detection of a drag gesture. If set to
  /// [DragStartBehavior.down] it will begin when a down event is first detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for the different behaviors.
  final DragStartBehavior dragStartBehavior;

  /// Controls the fade-in and fade-out animations for the toolbar and handles.
  static const Duration fadeDuration = Duration(milliseconds: 150);

  AnimationController _toolbarController;
  Animation<double> get _toolbarOpacity => _toolbarController.view;

  TextEditingValue _value;

  /// A pair of handles. If this is non-null, there are always 2, though the
  /// second is hidden when the selection is collapsed.
  List<OverlayEntry> _handles;

  /// A copy/paste toolbar.
  OverlayEntry _toolbar;

  TextSelection get _selection => _value.selection;

  /// Shows the handles by inserting them into the [context]'s overlay.
  void showHandles() {
    assert(_handles == null);
    _handles = <OverlayEntry>[
      OverlayEntry(
          builder: (BuildContext context) =>
              _buildHandle(context, _TextSelectionHandlePosition.start)),
      OverlayEntry(
          builder: (BuildContext context) =>
              _buildHandle(context, _TextSelectionHandlePosition.end)),
    ];
    //_hitTest.remove();

    var overlay = Overlay.of(context, debugRequiredFor: debugRequiredFor);
    overlay.insertAll(_handles);
    //overlay.insert(_hitTest);
  }

  /// Shows the toolbar by inserting it into the [context]'s overlay.
  void showToolbar() {
    assert(_toolbar == null);
    _toolbar = OverlayEntry(builder: _buildToolbar);

    var overlay = Overlay.of(context, debugRequiredFor: debugRequiredFor);
    overlay.insert(_toolbar);
    //overlay.insert(_hitTest);

    _toolbarController.forward(from: 0.0);
  }

  /// Updates the overlay after the selection has changed.
  ///
  /// If this method is called while the [SchedulerBinding.schedulerPhase] is
  /// [SchedulerPhase.persistentCallbacks], i.e. during the build, layout, or
  /// paint phases (see [WidgetsBinding.drawFrame]), then the update is delayed
  /// until the post-frame callbacks phase. Otherwise the update is done
  /// synchronously. This means that it is safe to call during builds, but also
  /// that if you do call this during a build, the UI will not update until the
  /// next frame (i.e. many milliseconds later).
  void update(TextEditingValue newValue) {
    if (_value == newValue) return;
    _value = newValue;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback(_markNeedsBuild);
    } else {
      _markNeedsBuild();
    }
  }

  /// Causes the overlay to update its rendering.
  ///
  /// This is intended to be called when the [renderObject] may have changed its
  /// text metrics (e.g. because the text was scrolled).
  void updateForScroll() {
    _markNeedsBuild();
  }

  void _markNeedsBuild([Duration duration]) {
    if (_handles != null) {
      _handles[0].markNeedsBuild();
      _handles[1].markNeedsBuild();
    }
    _toolbar?.markNeedsBuild();
  }

  /// Whether the handles are currently visible.
  bool get handlesAreVisible => _handles != null;

  /// Whether the toolbar is currently visible.
  bool get toolbarIsVisible => _toolbar != null;

  /// Hides the overlay.
  void hide() {
    if (_handles != null) {
      _handles[0].remove();
      _handles[1].remove();
      _handles = null;
    }
    _toolbar?.remove();
    _toolbar = null;

    //_hitTest.remove();
    _toolbarController.stop();
  }

  /// Final cleanup.
  void dispose() {
    hide();
    _toolbarController.dispose();
  }

  Widget _buildHandle(
      BuildContext context, _TextSelectionHandlePosition position) {
    if ((_selection.isCollapsed &&
            position == _TextSelectionHandlePosition.end) ||
        selectionControls == null)
      return Container(); // hide the second handle when collapsed
    return _TextSelectionHandleOverlay(
      onSelectionHandleChanged: (TextSelection newSelection) {
        _handleSelectionHandleChanged(newSelection, position);
      },
      onSelectionHandleTapped: _handleSelectionHandleTapped,
      layerLink: layerLink,
      renderObject: renderObject,
      selection: _selection,
      selectionControls: selectionControls,
      position: position,
      dragStartBehavior: dragStartBehavior,
    );
  }

  Widget _buildToolbar(BuildContext context) {
    if (selectionControls == null) return Container();
    if (renderObject == null || !renderObject.attached) return Container();
    // Find the horizontal midpoint, just above the selected text.
    final List<TextSelectionPoint> endpoints =
        renderObject.getEndpointsForSelection(_selection, toolbar: true);
    if (endpoints == null) return Container();

    final Offset midpoint = Offset(
      (endpoints.length == 1)
          ? endpoints[0].point.dx
          : (endpoints[0].point.dx + endpoints[1].point.dx) / 2.0,
      endpoints[0].point.dy - renderObject.preferredLineHeight,
    );

    final Rect editingRegion = Rect.fromPoints(
      renderObject.localToGlobal(Offset.zero),
      renderObject.localToGlobal(renderObject.size.bottomRight(Offset.zero)),
    );

    return FadeTransition(
      opacity: _toolbarOpacity,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: -editingRegion.topLeft,
        child: selectionControls.buildToolbar(
            context, editingRegion, midpoint, selectionDelegate),
      ),
    );
  }

  void _handleSelectionHandleChanged(
      TextSelection newSelection, _TextSelectionHandlePosition position) {
    TextPosition textPosition;
    switch (position) {
      case _TextSelectionHandlePosition.start:
        textPosition = newSelection.base;
        break;
      case _TextSelectionHandlePosition.end:
        textPosition = newSelection.extent;
        break;
    }
    selectionDelegate.textEditingValue =
        _value.copyWith(selection: newSelection, composing: TextRange.empty);
    selectionDelegate.bringIntoView(textPosition);
  }

  void _handleSelectionHandleTapped() {
    if (_value.selection.isCollapsed) {
      if (_toolbar != null) {
        _toolbar?.remove();
        _toolbar = null;
      } else {
        showToolbar();
      }
    }
  }
}

/// This widget represents a single draggable text selection handle.
class _TextSelectionHandleOverlay extends StatefulWidget {
  const _TextSelectionHandleOverlay({
    Key key,
    @required this.selection,
    @required this.position,
    @required this.layerLink,
    @required this.renderObject,
    @required this.onSelectionHandleChanged,
    @required this.onSelectionHandleTapped,
    @required this.selectionControls,
    this.dragStartBehavior = DragStartBehavior.start,
  }) : super(key: key);

  final TextSelection selection;
  final _TextSelectionHandlePosition position;
  final LayerLink layerLink;
  final ExtendedRenderParagraph renderObject;
  final ValueChanged<TextSelection> onSelectionHandleChanged;
  final VoidCallback onSelectionHandleTapped;
  final ExtendedTextSelectionControls selectionControls;
  final DragStartBehavior dragStartBehavior;

  @override
  _TextSelectionHandleOverlayState createState() =>
      _TextSelectionHandleOverlayState();

  ValueListenable<bool> get _visibility {
    switch (position) {
      case _TextSelectionHandlePosition.start:
        return renderObject.selectionStartInViewport;
      case _TextSelectionHandlePosition.end:
        return renderObject.selectionEndInViewport;
    }
    return null;
  }
}

class _TextSelectionHandleOverlayState
    extends State<_TextSelectionHandleOverlay>
    with SingleTickerProviderStateMixin {
  Offset _dragPosition;

  AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: ExtendedTextSelectionOverlay.fadeDuration, vsync: this);

    _handleVisibilityChanged();
    widget._visibility.addListener(_handleVisibilityChanged);
  }

  void _handleVisibilityChanged() {
    if (widget._visibility.value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(_TextSelectionHandleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget._visibility.removeListener(_handleVisibilityChanged);
    _handleVisibilityChanged();
    widget._visibility.addListener(_handleVisibilityChanged);
  }

  @override
  void dispose() {
    widget._visibility.removeListener(_handleVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _dragPosition = details.globalPosition +
        Offset(0.0, -widget.selectionControls.handleSize.height);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragPosition += details.delta;
    TextPosition position =
        widget.renderObject.getPositionForPoint(_dragPosition);

    ///zmt
    if (widget.renderObject.handleSpecialText) {
      position = convertTextPainterPostionToTextInputPostion(
          widget.renderObject.text, position);
    }

    if (widget.selection.isCollapsed) {
      widget.onSelectionHandleChanged(TextSelection.fromPosition(position));
      return;
    }

    TextSelection newSelection;
    switch (widget.position) {
      case _TextSelectionHandlePosition.start:
        newSelection = TextSelection(
          baseOffset: position.offset,
          extentOffset: widget.selection.extentOffset,
        );
        break;
      case _TextSelectionHandlePosition.end:
        newSelection = TextSelection(
          baseOffset: widget.selection.baseOffset,
          extentOffset: position.offset,
        );
        break;
    }

    if (newSelection.baseOffset >= newSelection.extentOffset)
      return; // don't allow order swapping.

    widget.onSelectionHandleChanged(newSelection);
  }

  void _handleTap() {
    widget.onSelectionHandleTapped();
  }

  @override
  Widget build(BuildContext context) {
    final List<TextSelectionPoint> endpoints =
        widget.renderObject.getEndpointsForSelection(widget.selection);
    if (endpoints == null) return Container();
    Offset point;
    TextSelectionHandleType type;

    switch (widget.position) {
      case _TextSelectionHandlePosition.start:
        point = endpoints[0].point;
        type = _chooseType(endpoints[0], TextSelectionHandleType.left,
            TextSelectionHandleType.right);
        break;
      case _TextSelectionHandlePosition.end:
        // [endpoints] will only contain 1 point for collapsed selections, in
        // which case we shouldn't be building the [end] handle.
        assert(endpoints.length == 2);
        point = endpoints[1].point;
        type = _chooseType(endpoints[1], TextSelectionHandleType.right,
            TextSelectionHandleType.left);
        break;
    }

    final Size viewport = widget.renderObject.size;
    point = Offset(
      point.dx.clamp(0.0, viewport.width),
      point.dy.clamp(0.0, viewport.height),
    );

    return CompositedTransformFollower(
      link: widget.layerLink,
      showWhenUnlinked: false,
      child: FadeTransition(
        opacity: _opacity,
        child: GestureDetector(
          dragStartBehavior: widget.dragStartBehavior,
          onPanStart: _handleDragStart,
          onPanUpdate: _handleDragUpdate,
          onTap: _handleTap,
          child: Stack(
            // Always let the selection handles draw outside of the conceptual
            // box where (0,0) is the top left corner of the RenderEditable.
            overflow: Overflow.visible,
            children: <Widget>[
              Positioned(
                left: point.dx,
                top: point.dy,
                child: widget.selectionControls.buildHandle(
                  context,
                  type,
                  widget.renderObject.preferredLineHeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSelectionHandleType _chooseType(
    TextSelectionPoint endpoint,
    TextSelectionHandleType ltrType,
    TextSelectionHandleType rtlType,
  ) {
    if (widget.selection.isCollapsed) return TextSelectionHandleType.collapsed;

    assert(endpoint.direction != null);
    switch (endpoint.direction) {
      case TextDirection.ltr:
        return ltrType;
      case TextDirection.rtl:
        return rtlType;
    }
    return null;
  }
}
