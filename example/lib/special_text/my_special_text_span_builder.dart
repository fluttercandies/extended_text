import 'package:example/special_text/at_text.dart';
import 'package:example/special_text/dollar_text.dart';
import 'package:example/special_text/emoji_text.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';

class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  @override
  SpecialText createSpecialText(String flag,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap}) {
    if (flag == null || flag == "") return null;
    // TODO: implement createSpecialText

    if (isStart(flag, AtText.flag)) {
      return AtText(textStyle, onTap);
    } else if (isStart(flag, EmojiText.flag)) {
      return EmojiText(textStyle);
    } else if (isStart(flag, DollarText.flag)) {
      return DollarText(textStyle, onTap);
    }
    return null;
  }
}
