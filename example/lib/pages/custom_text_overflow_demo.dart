import 'package:example/text/my_extended_text_selection_controls.dart';
import 'package:example/text/my_special_text_span_builder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:url_launcher/url_launcher.dart';

// @FFRoute(
//     name: 'fluttercandies://CustomTextOverflowDemo',
//     routeName: 'CustomTextOverflow',
//     description: 'workaround for issue 26748. how to custom text overflow')
class CustomTextOverflowDemo extends StatefulWidget {
  @override
  _CustomTextOverflowDemoState createState() => _CustomTextOverflowDemoState();
}

class _CustomTextOverflowDemoState extends State<CustomTextOverflowDemo> {
  final String content = ''
      'relate to \$issue 26748\$ .[love]Extended text help you to build rich text quickly. any special text you will have with extended text. '
      'It\'s my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[love]'
      '1234567 if you meet any problem, please let me konw @zmtzawqlp .';
  final MySpecialTextSpanBuilder builder = MySpecialTextSpanBuilder();
  bool _betterLineBreakingAndOverflowStyle = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('custom text over flow'),
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.style),
              onPressed: () {
                setState(() {
                  _betterLineBreakingAndOverflowStyle =
                      !_betterLineBreakingAndOverflowStyle;
                });
              })
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildText(maxLines: null, title: 'Full Text'),
              _buildText(position: TextOverflowPosition.end),
              _buildText(position: TextOverflowPosition.start),
              _buildText(position: TextOverflowPosition.middle),
              _buildText(position: TextOverflowPosition.middle, maxLines: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText({
    TextOverflowPosition position = TextOverflowPosition.end,
    int maxLines = 4,
    String title,
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
                    'position: ${position.toString().replaceAll('TextOverflowPosition.', '')}${maxLines != null ? ' , maxLines: $maxLines' : ''}',
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
                selectionEnabled: true,
                // if betterLineBreakingAndOverflowStyle is true, you must take care of copy text.
                // override [TextSelectionControls.handleCopy], remove zero width space.
                selectionControls: MyTextSelectionControls(
                  joinZeroWidthSpace:
                      _betterLineBreakingAndOverflowStyle,
                ),
                betterLineBreakingAndOverflowStyle:
                    _betterLineBreakingAndOverflowStyle,
                overflowWidget: TextOverflowWidget(
                  position: position,
                  align: TextOverflowAlign.center,
                  // just for debug
                  debugOverflowRectColor: Colors.red.withOpacity(0.1),
                  child: Container(
                    //color: Colors.yellow,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('\u2026 '),
                        InkWell(
                          child: const Text(
                            'more',
                          ),
                          onTap: () {
                            launch(
                                'https://github.com/fluttercandies/extended_text');
                          },
                        )
                      ],
                    ),
                  ),
                ),
                maxLines: maxLines,
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
