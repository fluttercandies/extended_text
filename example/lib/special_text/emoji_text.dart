import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/painting/text_span.dart';
import 'package:flutter/src/painting/text_style.dart';

///emoji/image text
class EmojiText extends SpecialText {
  static const String flag = "[";

  EmojiText(TextStyle textStyle) : super(EmojiText.flag, "]", textStyle);

  @override
  TextSpan finishText() {
    // TODO: implement finishText
    var key = toString();
    if (EmojiUitl.instance.emojiMap.containsKey(key)) {
      //fontsize id define image height
      //size = 30.0/26.0 * fontSize
      final double size = 20.0;

      ///fontSize 26 and text height =30.0
      //final double fontSize = 26.0;

      return ImageSpan(AssetImage(EmojiUitl.instance.emojiMap[key]),
          imageWidth: size,
          imageHeight: size,
          margin: EdgeInsets.only(left: 2.0, bottom: 0.0, right: 2.0));
    }

    return TextSpan(text: toString(), style: textStyle);
  }
}

class EmojiUitl {
  final Map<String, String> _emojiMap = new Map<String, String>();

  Map<String, String> get emojiMap => _emojiMap;

  final String _emojiFilePath = "assets";

  static EmojiUitl _instance;
  static EmojiUitl get instance {
    if (_instance == null) _instance = new EmojiUitl._();
    return _instance;
  }

  EmojiUitl._() {
    _emojiMap["[love]"] = "$_emojiFilePath/love.png";
    _emojiMap["[sun_glasses]"] = "$_emojiFilePath/sun_glasses.png";
    _emojiMap["[tears]"] = "$_emojiFilePath/tears.png";
  }
}
