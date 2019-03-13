import 'package:extended_text/src/extended_text_utils.dart';
import 'package:flutter/material.dart';

abstract class SpecialTextSpanBuilder {
  //build text span to specialText
  TextSpan build(String data,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap});

  //build SpecialText base on startflag
  SpecialText createSpecialText(String flag,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap});

  /// start with SpecialText
  bool isStart(String value, String startFlag) {
    return value.endsWith(startFlag);
  }
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
    return value.endsWith(endFlag);
  }

  ///append text of SpecialText
  void appendContent(String value) {
    _contetnt.write(value);
  }

  ///get content of SpecialText
  String getContent() {
    return _contetnt.toString();
  }

  @override
  String toString() {
    // TODO: implement toString
    return startFlag + getContent() + endFlag;
  }
}
