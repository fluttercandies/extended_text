import 'package:extended_text/extended_text.dart';
import 'package:flutter/src/painting/text_span.dart';
import 'package:flutter/src/painting/text_style.dart';

class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  @override
  TextSpan build(String data, {TextStyle textStyle, onTap}) {
    if (data == null || data == "") return null;

    // TODO: implement build
    return null;
  }

  @override
  TextSpan createSpecialText(String flag) {
    if (flag == null || flag == "") return null;
    // TODO: implement createSpecialText
    return null;
  }
}
