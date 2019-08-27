import 'package:example/special_text/my_special_text_span_builder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ff_annotation_route/ff_annotation_route.dart';

@FFRoute(
    name: "fluttercandies://CustomTextOverflowDemo",
    routeName: "CustomTextOverflow",
    description: "workaround for issue 26748. how to custom text overflow")
class CustomTextOverflowDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("custom text over flow"),
        ),
        body: Container(
          padding: EdgeInsets.all(20.0),
          child: ExtendedText(
            "relate to \$issue 26748\$ .[love]Extended text help you to build rich text quickly. any special text you will have with extended text. "
            "It's my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[love]"
            "if you meet any problem, please let me konw @zmtzawqlp .[sun_glasses] "
            "relate to \$issue 26748\$ .[love]Extended text help you to build rich text quickly. any special text you will have with extended text. "
            "It's my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[love]"
            "if you meet any problem, please let me konw @zmtzawqlp .[sun_glasses] ",
            onSpecialTextTap: (dynamic parameter) {
              if (parameter.startsWith("\$")) {
                if (parameter.contains("issue")) {
                  launch("https://github.com/flutter/flutter/issues/26748");
                } else {
                  launch("https://github.com/fluttercandies");
                }
              } else if (parameter.startsWith("@")) {
                launch("mailto:zmtzawqlp@live.com");
              }
            },
            specialTextSpanBuilder: MySpecialTextSpanBuilder(),
            //overflow: TextOverflow.ellipsis,
            overFlowTextSpan: OverFlowTextSpan(children: <TextSpan>[
              TextSpan(text: '  \u2026  '),
              TextSpan(
                  text: "more detail",
                  style: TextStyle(
                    color: Colors.blue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launch("https://github.com/fluttercandies/extended_text");
                    })
            ]),
            maxLines: 10,
          ),
        ));
  }
}
