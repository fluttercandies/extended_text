import 'package:example/text/my_special_text_span_builder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'fluttercandies://SelectableRegionWithTextFieldDemo',
  routeName: 'SelectableRegionWithTextField',
  description: 'SelectableRegion works with TextField',
)
class SelectableRegionWithTextFieldDemo extends StatefulWidget {
  const SelectableRegionWithTextFieldDemo({super.key});

  @override
  State<SelectableRegionWithTextFieldDemo> createState() =>
      _SelectableRegionWithTextFieldDemoState();
}

class _SelectableRegionWithTextFieldDemoState
    extends State<SelectableRegionWithTextFieldDemo> {
  final SelectableRegionFocusNode _myFocusNode = SelectableRegionFocusNode();

  final GlobalKey<SelectableRegionState> _key =
      GlobalKey<SelectableRegionState>();

  @override
  Widget build(BuildContext context) {
    final TextSelectionControls controls = switch (Theme.of(context).platform) {
      TargetPlatform.android ||
      TargetPlatform.fuchsia =>
        materialTextSelectionHandleControls,
      TargetPlatform.linux ||
      TargetPlatform.windows =>
        desktopTextSelectionHandleControls,
      TargetPlatform.iOS => cupertinoTextSelectionHandleControls,
      TargetPlatform.macOS => cupertinoDesktopTextSelectionHandleControls,
    };
    const String content =
        '中文  [love]Extended text help you to build rich text quickly. any special text you will have with extended text. '
        'It\'s my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[love]'
        'if you meet any problem, please let me know @zmtzawqlp .[sun_glasses]';
    return Scaffold(
      appBar: AppBar(
        title: const Text('SelectionArea Support'),
      ),
      body: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            TextButton(
              onPressed: () {
                _myFocusNode.hideMenu();
              },
              child: const Text('hide menu'),
            ),
            SelectableRegion(
              key: _key,
              child: GestureDetector(
                child: ExtendedText(
                  content,
                  specialTextSpanBuilder: MySpecialTextSpanBuilder(),
                ),
                behavior: HitTestBehavior.translucent,
                onLongPress: () {
                  _key.currentState?.selectAll(SelectionChangedCause.toolbar);
                },
              ),
              focusNode: _myFocusNode,
              selectionControls: controls,
              contextMenuBuilder: (BuildContext context,
                  SelectableRegionState selectableRegionState) {
                return AdaptiveTextSelectionToolbar.selectableRegion(
                  selectableRegionState: selectableRegionState,
                );
              },
            ),
            const Spacer(),
            const TextField(
              maxLines: 1,
              style: TextStyle(height: 1),
              strutStyle: StrutStyle(
                height: 2.0,
                forceStrutHeight: true,
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// SelectableRegion don't want to hide menu when TextFiled get focus
/// And when show menu, we don't want to make TextField lose focus
/// so we need to override FocusNode
class SelectableRegionFocusNode extends FocusNode {
  SelectableRegionFocusNode();

  @override
  bool get hasFocus => false;

  @override
  bool get hasPrimaryFocus => false;

  @override
  void requestFocus([FocusNode? node]) {
    return;
  }

  void hideMenu() {
    notifyListeners();
  }
}
