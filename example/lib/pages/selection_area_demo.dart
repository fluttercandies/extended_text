import 'package:example/text/my_special_text_span_builder.dart';
import 'package:example/text/selection_area.dart';
import 'package:extended_text/extended_text.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

@FFRoute(
  name: 'fluttercandies://SelectionAreaDemo',
  routeName: 'SelectionArea',
  description: 'SelectionArea support',
)
class SelectionAreaDemo extends StatelessWidget {
  const SelectionAreaDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const String content =
        '[love]Extended text help you to build rich text quickly. any special text you will have with extended text. '
        'It\'s my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[love]'
        'if you meet any problem, please let me know @zmtzawqlp .[sun_glasses]';
    return Scaffold(
      appBar: AppBar(
        title: const Text('SelectionArea Support'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(20.0),
          child: CommonSelectionArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // const Text(
                //   content,
                //   maxLines: 4,
                // ),
                const SizedBox(height: 10),
                ExtendedText(
                  content,
                  onSpecialTextTap: (dynamic parameter) {
                    if (parameter.toString().startsWith('\$')) {
                      launchUrl(Uri.parse('https://github.com/fluttercandies'));
                    } else if (parameter.toString().startsWith('@')) {
                      launchUrl(Uri.parse('mailto:zmtzawqlp@live.com'));
                    }
                  },
                  specialTextSpanBuilder: MySpecialTextSpanBuilder(),
                  overflow: TextOverflow.ellipsis,
                  overflowWidget: TextOverflowWidget(
                    position: TextOverflowPosition.middle,
                    align: TextOverflowAlign.center,
                    // just for debug
                    debugOverflowRectColor: Colors.red.withOpacity(0.1),
                    child: Container(
                      //color: Colors.yellow,
                      child:
                          // overwidget text should be not selectable
                          SelectionContainer.disabled(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text('\u2026 '),
                            InkWell(
                              child: const Text(
                                'more',
                              ),
                              onTap: () {
                                launchUrl(Uri.parse(
                                    'https://github.com/fluttercandies/extended_text'));
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
