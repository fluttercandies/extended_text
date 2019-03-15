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
                        "\n\nif you meet any problem, please let me konw @zmtzawqlp .[sun_glasses] "
                        "\n notice: fail to clear text under overflow span, with BlendMode.clear. "
                        "so paint a backgounrd (Theme.of(context).canvasColor) over text. let me know if you have any idea.I'm overflow text.I'm overflow text.I'm overflow text.I'm overflow text.",
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
                      TextSpan(text: '  \u2026  '),
                      TextSpan(
                          text: "more",
                          style: TextStyle(
                            color: Colors.blue,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              launch(
                                  "https://github.com/fluttercandies/extended_text");
                            })
                    ], background: Theme.of(context).canvasColor),
                    maxLines: 12,
                  ),
                ])));
  }
}
