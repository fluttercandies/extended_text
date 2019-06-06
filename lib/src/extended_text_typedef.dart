import 'package:flutter/material.dart';

import 'extended_render_paragraph.dart';

///
///  create by zmtzawqlp on 2019/6/5
///

typedef WidgetKeyBuilder = Widget Function(Key key);

/// Signature for the callback that reports when the user changes the selection
/// (including the cursor location).
///
/// Used by [ExtendedRenderEditable.onSelectionChanged].
typedef TextSelectionChangedHandler = void Function(TextSelection selection,
    ExtendedRenderParagraph renderObject, SelectionChangedCause cause);
