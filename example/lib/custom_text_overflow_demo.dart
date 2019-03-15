import 'package:example/special_text/my_special_text_span_builder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomTextOverflowDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("custom text over flow"),
        ),
        body: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ExtendedText(
                    "[love]Extended text help you to build rich text quickly. any special text you will have with extended text. "
                        "\n\nIt's my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[love]"
                        "\n\nif you meet any problem, please let me konw @zmtzawqlp .[sun_glasses] I'm overflow text.I'm overflow text.I'm overflow text.周茂拓你好啊.follwing text is for overflow",
                    onSpecialTextTap: (String data) {
                      if (data.startsWith("\$")) {
                        launch("https://github.com/fluttercandies");
                      } else if (data.startsWith("@")) {
                        launch("mailto:zmtzawqlp@live.com");
                      }
                    },
                    specialTextSpanBuilder: MySpecialTextSpanBuilder(),
                    overflow: TextOverflow.ellipsis,
                    overFlowTextSpan: OverFlowTextSpan(children: <TextSpan>[
                      TextSpan(text: '  \u2026  测试一下哈哈哈哈哈'),
                      TextSpan(
                          text: "see more",
                          style: TextStyle(
                            color: Colors.blue,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              launch(
                                  "https://github.com/fluttercandies/extended_text");
                            })
                    ]),
                    maxLines: 9,
                  ),
                ])));
  }
}
