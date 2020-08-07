import 'package:extended_text/src/selection/extended_text_selection.dart';
import 'package:flutter/material.dart';

///
///  create by zmtzawqlp on 2019/6/5
///

///builder of textSelectionPointerHandler,you can use this to custom your selection behavior
typedef TextSelectionPointerHandlerWidgetBuilder = Widget Function(
    List<ExtendedTextSelectionState> state);
