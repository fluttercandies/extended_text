import 'package:example/text/my_special_text_span_builder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

@FFRoute(
    name: 'fluttercandies://LineBreakingOverflowStyle',
    routeName: 'LineBreakingOverflowStyle',
    description: 'workaround for issue 18761. LineBreakingOverflowStyle')
class LineBreakingOverflowStyleDemo extends StatelessWidget {
  final String content = 'relate';
  final MySpecialTextSpanBuilder builder = MySpecialTextSpanBuilder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LineBreakingAndOverflowStyle'),
      ),
      body: Container(
        padding: const EdgeInsets.all(20.0),
        child: ExtendedText(
          content,
          onSpecialTextTap: onSpecialTextTap,
          specialTextSpanBuilder: builder,
          selectionEnabled: true,
          perfectLineBreakingAndOverflowStyle: true,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ),
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
