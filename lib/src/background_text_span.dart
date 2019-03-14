import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class BackgroundTextSpan extends TextSpan {
  /// The paint drawn as a background for the text.
  ///
  /// The value should ideally be cached and reused each time if multiple text
  /// styles are created with the same paint settings. Otherwise, each time it
  /// will appear like the style changed, which will result in unnecessary
  /// updates all the way through the framework.
  ///
  /// workaround for 24335 issue
  /// https://github.com/flutter/flutter/issues/24335
  /// https://github.com/flutter/flutter/issues/24337
  /// we will draw background by ourself
  final Paint background;

  BackgroundTextSpan({
    TextStyle style,
    String text,
    List<TextSpan> children,
    GestureRecognizer recognizer,
    this.background,
  }) : super(
            style: style,
            text: text,
            children: children,
            recognizer: recognizer);
}
