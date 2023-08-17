/*
 * @Author: zmtzawqlp
 * @Date: 2020-06-25 01:29:01
 * @Last Modified by: zmtzawqlp
 * @Last Modified time: 2020-06-25 02:13:14
 */
import 'package:flutter/widgets.dart';

enum TextOverflowAlign {
  /// Align the [TextOverflowWidget] on the left edge of the Text Overflow Rect.
  left,

  /// Align the [TextOverflowWidget] on the right edge of the Text Overflow Rect.
  right,

  /// Align the [TextOverflowWidget] on the center of the Text Overflow Rect.
  center,
}

/// The position which TextOverflowWidget should be shown
/// https://github.com/flutter/flutter/issues/45336
enum TextOverflowPosition {
  start,
  middle,
  end,
}

/// https://github.com/fluttercandies/extended_text/issues/118
/// Clear the text under TextOverflowWidget
/// default:  Paint()..BlendMode.clear
/// Canvas.clipRect
/// BlendMode.clear will make BackdropFilter to be black background
enum TextOverflowClearType {
  ///
  clipRect,

  /// Paint()..BlendMode.clear
  blendModeClear,
}

class TextOverflowWidget extends StatelessWidget {
  const TextOverflowWidget({
    required this.child,
    this.align = TextOverflowAlign.right,
    this.maxHeight,
    this.position = TextOverflowPosition.end,
    this.debugOverflowRectColor,
    this.clearType = TextOverflowClearType.blendModeClear,
  });

  /// The widget of TextOverflow.
  final Widget child;

  /// The Align of [TextOverflowWidget].
  final TextOverflowAlign align;

  /// The maxHeight of [TextOverflowWidget], default is preferredLineHeight.
  final double? maxHeight;

  /// The position which TextOverflowWidget should be shown
  final TextOverflowPosition position;

  /// Whether paint overflow rect, just for debug
  /// https://github.com/flutter/flutter/issues/45336
  final Color? debugOverflowRectColor;

  /// https://github.com/fluttercandies/extended_text/issues/118
  /// Clear the text under TextOverflowWidget
  /// default:  Paint()..BlendMode.clear
  /// Canvas.clipRect
  /// BlendMode.clear will make BackdropFilter to be black background
  final TextOverflowClearType clearType;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
