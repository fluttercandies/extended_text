import 'package:flutter/material.dart';

import 'extended_text_selection.dart';

///
///  create by zmtzawqlp on 2019/6/6
///

///help to handle multiple selectionable text on same page.
///
class ExtendedTextSelectionPointerHandler extends StatefulWidget {
  final Widget child;
  ExtendedTextSelectionPointerHandler({@required this.child});
  @override
  ExtendedTextSelectionPointerHandlerState createState() =>
      ExtendedTextSelectionPointerHandlerState();
}

class ExtendedTextSelectionPointerHandlerState
    extends State<ExtendedTextSelectionPointerHandler> {
  List<ExtendedTextSelectionState> _selectionStates =
      <ExtendedTextSelectionState>[];
  List<ExtendedTextSelectionState> get selectionStates => _selectionStates;

  bool _pointerMove = false;
  @override
  Widget build(BuildContext context) {
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
