import 'package:extended_text/extended_text.dart';
import 'package:flutter/src/painting/text_span.dart';
import 'package:flutter/src/painting/text_style.dart';

class AtText extends SpecialText {
  static const String flag = "@";
  AtText(TextStyle textStyle) : super(flag, " ", textStyle);

  @override
  TextSpan finishText() {
    // TODO: implement finishText
    return null;
  }
}
