import 'package:example/special_text/at_text.dart';
import 'package:example/special_text/dollar_text.dart';
import 'package:example/special_text/emoji_text.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';

class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  @override
  TextSpan build(String data,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap}) {
    if (data == null || data == "") return null;
    List<TextSpan> inlineList = new List<TextSpan>();
    if (data != null && data.length > 0) {
      SpecialText specialText;
      String textStack = "";
      //String text
      for (int i = 0; i < data.length; i++) {
        String char = data[i];
        if (specialText != null) {
          if (!specialText.isEnd(char)) {
            specialText.appendContent(char);
          } else {
            inlineList.add(specialText.finishText());
            specialText = null;
          }
        } else {
          textStack += char;
          specialText =
              createSpecialText(textStack, textStyle: textStyle, onTap: onTap);
          if (specialText != null) {
            if (textStack.length - specialText.startFlag.length >= 0) {
              textStack = textStack.substring(
                  0, textStack.length - specialText.startFlag.length);
              if (textStack.length > 0) {
                inlineList.add(TextSpan(text: textStack, style: textStyle));
              }
            }
            textStack = "";
          }
        }
      }

      if (specialText != null) {
        inlineList.add(TextSpan(
            text: specialText.startFlag + specialText.getContent(),
            style: textStyle));
      } else if (textStack.length > 0) {
        inlineList.add(TextSpan(text: textStack, style: textStyle));
      }
    }

    // TODO: implement build
    return TextSpan(children: inlineList, style: textStyle);
  }

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
