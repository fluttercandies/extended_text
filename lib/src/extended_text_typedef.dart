import 'package:extended_text/src/selection/extended_text_selection.dart';
import 'package:flutter/material.dart';

import 'extended_render_paragraph.dart';

///
///  create by zmtzawqlp on 2019/6/5
///

/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
///
/// Used by [ExtendedRenderEditable.onSelectionChanged].
typedef TextSelectionChangedHandler = void Function(TextSelection selection,
    ExtendedRenderParagraph renderObject, SelectionChangedCause cause);

///builder of textSelectionPointerHandler,you can use this to custom your selection behavior
typedef TextSelectionPointerHandlerWidgetBuilder = Widget Function(
    List<ExtendedTextSelectionState> state);
