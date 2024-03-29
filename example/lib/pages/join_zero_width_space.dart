import 'package:example/text/my_special_text_span_builder.dart';
import 'package:example/text/selection_area.dart';
import 'package:extended_text/extended_text.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

@FFRoute(
    name: 'fluttercandies://JoinZeroWidthSpace',
    routeName: 'JoinZeroWidthSpace',
    description:
        'make line breaking and overflow style better, workaround for issue 18761.')
class JoinZeroWidthSpaceDemo extends StatelessWidget {
  final String content =
      'relate to \$issue 26748\$ .[love]Extended text help you to build rich text quickly. any special text you will have with extended text. '
      'It\'s my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[love]'
      '1234567 if you meet any problem, please let me know @zmtzawqlp .';
  final MySpecialTextSpanBuilder builder = MySpecialTextSpanBuilder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Zero-Width Space'),
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildText(
                joinZeroWidthSpace: false,
              ),
              _buildText(
                joinZeroWidthSpace: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText({
    int? maxLines = 4,
    String? title,
    bool joinZeroWidthSpace = false,
  }) {
    return Card(
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title ?? 'joinZeroWidthSpace: $joinZeroWidthSpace',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: Colors.grey,
                ),
              ),
              CommonSelectionArea(
                // if betterLineBreakingAndOverflowStyle is true, you must take care of copy text.
                // override [TextSelectionControls.handleCopy], remove zero width space.
                joinZeroWidthSpace: joinZeroWidthSpace,
                child: ExtendedText(
                  content,
                  onSpecialTextTap: onSpecialTextTap,
                  specialTextSpanBuilder: builder,
                  joinZeroWidthSpace: joinZeroWidthSpace,
                  overflow: TextOverflow.ellipsis,
                  maxLines: maxLines,
                ),
              ),
            ],
          )),
    );
  }

  void onSpecialTextTap(dynamic parameter) {
    if (parameter.toString().startsWith('\$')) {
      if (parameter.toString().contains('issue')) {
        launchUrl(Uri.parse('https://github.com/flutter/flutter/issues/26748'));
      } else {
        launchUrl(Uri.parse('https://github.com/fluttercandies'));
      }
    } else if (parameter.toString().startsWith('@')) {
      launchUrl(Uri.parse('mailto:zmtzawqlp@live.com'));
    }
  }
}
