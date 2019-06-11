import 'package:flutter/material.dart';

import '../extended_text_typedef.dart';
import 'extended_text_selection.dart';

///
///  create by zmtzawqlp on 2019/6/6
///

///help to handle multiple selectionable text on same page.
///
class ExtendedTextSelectionPointerHandler extends StatefulWidget {
  final Widget child;
  final TextSelectionPointerHandlerWidgetBuilder builder;
  ExtendedTextSelectionPointerHandler({this.child, this.builder})
      : assert(!(child == null && builder == null)),
        assert(!(child != null && builder != null));
  @override
  ExtendedTextSelectionPointerHandlerState createState() =>
      ExtendedTextSelectionPointerHandlerState();
}

class ExtendedTextSelectionPointerHandlerState
    extends State<ExtendedTextSelectionPointerHandler> {
  List<ExtendedTextSelectionState> _selectionStates =
      <ExtendedTextSelectionState>[];
  List<ExtendedTextSelectionState> get selectionStates => _selectionStates;

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder(_selectionStates);
    }
    return Listener(
      child: widget.child,
      behavior: HitTestBehavior.translucent,
      onPointerDown: (value) {
        for (var state in _selectionStates) {
          if (!state.containsPosition(value.position)) {
            //clear other selection
            state.clearSelection();
          }
        }
      },
      onPointerMove: (value) {
        //clear other selection
        for (var state in _selectionStates) {
          state.clearSelection();
        }
      },
    );
  }
}
