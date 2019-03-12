import 'package:extended_text/extended_text.dart';
import 'package:flutter/src/painting/text_span.dart';
import 'package:flutter/src/painting/text_style.dart';

///emoji/image text
class EmojiText extends SpecialText {
  static const String flag = "[";

  EmojiText(TextStyle textStyle) : super(EmojiText.flag, "]", textStyle);

  @override
  TextSpan finishText() {
    // TODO: implement finishText
    return null;
  }
}
