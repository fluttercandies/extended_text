import 'package:example/text/regexp_special_text_span_builder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

@FFRoute(
    name: 'fluttercandies://RegExpTextDemo',
    routeName: 'RegExText',
    description: 'quickly build special text with RegExp')
class RegExpTextDemo extends StatelessWidget {
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
          '\n\nif you meet any problem, please let me know @zmtzawqlp and send an mailto:zmtzawqlp@live.com to me .[sun_glasses] ',
          onSpecialTextTap: (dynamic parameter) {
            if (parameter.toString().startsWith('\$')) {
              launch('https://github.com/fluttercandies');
            } else if (parameter.toString().startsWith('@')) {
              launch('mailto:zmtzawqlp@live.com');
            } else if (parameter.toString().startsWith('mailto:')) {
              launch(parameter.toString());
            }
          },
          specialTextSpanBuilder: MyRegExpSpecialTextSpanBuilder(),
          overflow: TextOverflow.ellipsis,
          selectionEnabled: true,
          //style: TextStyle(background: Paint()..color = Colors.red),
          maxLines: 10,
        ),
      ),
    );
  }
}
