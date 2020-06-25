///
///  photo_view_demo.dart
///  create by zmtzawqlp on 2019/4/4
///

import 'package:example/text/my_extended_text_selection_controls.dart';
import 'package:example/text/my_special_text_span_builder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart' hide CircularProgressIndicator;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

import 'package:ff_annotation_route/ff_annotation_route.dart';

@FFRoute(
    name: "fluttercandies://TextSelectionDemo",
    routeName: "TextSelection",
    description: "text selection support")
class TextSelectionDemo extends StatefulWidget {
  @override
  _TextSelectionDemoState createState() => _TextSelectionDemoState();
}

class _TextSelectionDemoState extends State<TextSelectionDemo> {
  MyExtendedMaterialTextSelectionControls
      _myExtendedMaterialTextSelectionControls;
  final String _attachContent =
      "[love]Extended text help you to build rich text quickly. any special text you will have with extended text.It's my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[love] if you meet any problem, please let me konw @zmtzawqlp .[sun_glasses]";
  @override
  void initState() {
    _myExtendedMaterialTextSelectionControls =
        MyExtendedMaterialTextSelectionControls();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Widget result = Material(
      child: Column(
        children: <Widget>[
          AppBar(
            title: Text("text selection support"),
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: ExtendedText(
                    _attachContent,
                    onSpecialTextTap: (dynamic parameter) {
                      if (parameter.toString().startsWith('\$')) {
                        launch('https://github.com/fluttercandies');
                      } else if (parameter.toString().startsWith('@')) {
                        launch('mailto:zmtzawqlp@live.com');
                      }
                    },
                    specialTextSpanBuilder: MySpecialTextSpanBuilder(),
                    //overflow: ExtendedTextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 4,
                    overFlowWidget: kIsWeb
                        ? null
                        : TextOverflowWidget(
                            child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text('\u2026 '),
                              RaisedButton(
                                child: const Text('more'),
                                onPressed: () {
                                  launch(
                                      'https://github.com/fluttercandies/extended_text');
                                },
                              )
                            ],
                          )),
                    selectionEnabled: true,
                    textSelectionControls:
                        _myExtendedMaterialTextSelectionControls,
                  ),
                );
              },
              itemCount: 100,
            ),
          ),
        ],
      ),
    );

    return ExtendedTextSelectionPointerHandler(
      //default behavior
      // child: result,
      //custom your behavior
      builder: (states) {
        return Listener(
          child: result,
          behavior: HitTestBehavior.translucent,
          onPointerDown: (value) {
            for (var state in states) {
              if (!state.containsPosition(value.position)) {
                //clear other selection
                state.clearSelection();
              }
            }
          },
          onPointerMove: (value) {
            //clear other selection
            for (var state in states) {
              state.clearSelection();
            }
          },
        );
      },
    );
  }
}
