import 'package:extended_text/src/extended_text_utils.dart';
import 'package:flutter/material.dart';

abstract class SpecialTextSpanBuilder {
  //build text span to specialText
  TextSpan build(String data,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap});

  //build SpecialText base on startflag
  TextSpan createSpecialText(String flag);
}

abstract class SpecialText {
  final StringBuffer _contetnt;

  ///start flag of SpecialText
  final String startFlag;

  ///end flag of SpecialText
  final String endFlag;

  ///TextStyle of SpecialText
  final TextStyle textStyle;

  ///tap call back of SpecialText
  final SpecialTextGestureTapCallback onTap;

  SpecialText(this.startFlag, this.endFlag, this.textStyle, {this.onTap})
      : _contetnt = StringBuffer();

  ///finish SpecialText
  TextSpan finishText();

  ///is end of SpecialText
  bool isEnd(String value) {
    return value == endFlag;
  }

  ///append text of SpecialText
  void appendText(String value) {
    _contetnt.write(value);
  }

  ///get content of SpecialText
  String getText() {
    return _contetnt.toString();
  }
}
