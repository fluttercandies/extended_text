import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_candies_demo_library/flutter_candies_demo_library.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ff_annotation_route/ff_annotation_route.dart';

@FFRoute(
    name: 'fluttercandies://TextDemo',
    routeName: 'Text',
    description: 'quickly build special text')
class TextDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('quickly build special text'),
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: ExtendedText(
          '[love]Extended text help you to build rich text quickly. any special text you will have with extended text. '
          '\n\nIt\'s my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[love]'
          '\n\nif you meet any problem, please let me konw @zmtzawqlp .[sun_glasses]',
          onSpecialTextTap: (dynamic parameter) {
            if (parameter.toString().startsWith('\$')) {
              launch('https://github.com/fluttercandies');
            } else if (parameter.toString().startsWith('@')) {
              launch('mailto:zmtzawqlp@live.com');
            }
          },
          specialTextSpanBuilder: MySpecialTextSpanBuilder(),
          overflow: TextOverflow.ellipsis,
          //style: TextStyle(background: Paint()..color = Colors.red),
          maxLines: 10,
        ),
      ),
    );
  }
}
