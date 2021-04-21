import 'package:example/text/my_special_text_span_builder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// @FFRoute(
//     name: 'fluttercandies://LineBreakingOverflowStyle',
//     routeName: 'LineBreakingOverflowStyle',
//     description:
//         'make line breaking and overflow style better,workaround for issue 18761.')
class LineBreakingOverflowStyleDemo extends StatelessWidget {
  final String content =
      'relate to \$issue 26748\$ .[love]Extended text help you to build rich text quickly. any special text you will have with extended text. '
      'It\'s my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[love]'
      '1234567 if you meet any problem, please let me konw @zmtzawqlp .';
  final MySpecialTextSpanBuilder builder = MySpecialTextSpanBuilder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('line breaking and overflow'),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.ac_unit_sharp), onPressed: () {})
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildText(
                betterLineBreakingAndOverflowStyle: false,
              ),
              _buildText(
                betterLineBreakingAndOverflowStyle: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText({
    int maxLines = 4,
    String title,
    bool betterLineBreakingAndOverflowStyle = false,
  }) {
    return Card(
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title ??
                    'betterLineBreakingAndOverflowStyle: $betterLineBreakingAndOverflowStyle',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: Colors.grey,
                ),
              ),
              ExtendedText(
                content,
                onSpecialTextTap: onSpecialTextTap,
                specialTextSpanBuilder: builder,
                betterLineBreakingAndOverflowStyle:
                    betterLineBreakingAndOverflowStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: maxLines,
                selectionEnabled: true,
              ),
            ],
          )),
    );
  }

  void onSpecialTextTap(dynamic parameter) {
    if (parameter.toString().startsWith('\$')) {
      if (parameter.toString().contains('issue')) {
        launch('https://github.com/flutter/flutter/issues/26748');
      } else {
        launch('https://github.com/fluttercandies');
      }
    } else if (parameter.toString().startsWith('@')) {
      launch('mailto:zmtzawqlp@live.com');
    }
  }
}
