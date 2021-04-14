import 'package:example/text/my_special_text_span_builder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

@FFRoute(
    name: 'fluttercandies://MiddleTextOverflowDemo',
    routeName: 'MiddleTextOverflow',
    description: 'how to make text overflow in middle.')
class MiddleTextOverflowDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('custom text over flow'),
        ),
        body: Container(
          padding: const EdgeInsets.all(20.0),
          child: ExtendedText(
            'https://github.com/flutter/flutter/issues/26748' * 4,
            onSpecialTextTap: (dynamic parameter) {
              if (parameter.toString().startsWith('\$')) {
                if (parameter.toString().contains('issue')) {
                  launch('https://github.com/flutter/flutter/issues/26748');
                } else {
                  launch('https://github.com/fluttercandies');
                }
              } else if (parameter.toString().startsWith('@')) {
                launch('mailto:zmtzawqlp@live.com');
              }
            },
            specialTextSpanBuilder: MySpecialTextSpanBuilder(),
            selectionEnabled: true,
            maxLines: 2,
          ),
        ));
  }
}
