/*
 * @Author: zmtzawqlp
 * @Date: 2020-06-25 01:29:01
 * @Last Modified by: zhoumaotuo
 * @Last Modified time: 2020-06-25 02:13:14
 */
import 'package:flutter/widgets.dart';

enum TextOverflowAlign {
  /// Align the [TextOverflowWidget] on the left edge of the Text Overflow Rect.
  left,

  /// Align the [TextOverflowWidget] on the right edge of the Text Overflow Rect.
  right,
}

class TextOverflowWidget extends StatelessWidget {
  const TextOverflowWidget({
    @required this.child,
    this.align = TextOverflowAlign.right,
    this.maxHeight,
    this.fixedOffset = Offset.zero,
  }) : assert(fixedOffset != null);

  /// The widget of TextOverflow.
  final Widget child;

  /// The Align of [TextOverflowWidget].
  final TextOverflowAlign align;

  /// The maxHeight of [TextOverflowWidget], default is preferredLineHeight.
  final double maxHeight;

  /// Fixed offset refer to the Text Overflow Rect and [child].
  final Offset fixedOffset;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
