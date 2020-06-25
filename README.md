# extended_text

[![pub package](https://img.shields.io/pub/v/extended_text.svg)](https://pub.dartlang.org/packages/extended_text) [![GitHub stars](https://img.shields.io/github/stars/fluttercandies/extended_text)](https://github.com/fluttercandies/extended_text/stargazers) [![GitHub forks](https://img.shields.io/github/forks/fluttercandies/extended_text)](https://github.com/fluttercandies/extended_text/network)  [![GitHub license](https://img.shields.io/github/license/fluttercandies/extended_text)](https://github.com/fluttercandies/extended_text/blob/master/LICENSE)  [![GitHub issues](https://img.shields.io/github/issues/fluttercandies/extended_text)](https://github.com/fluttercandies/extended_text/issues) <a target="_blank" href="https://jq.qq.com/?_wv=1027&k=5bcc0gy"><img border="0" src="https://pub.idqqimg.com/wpa/images/group.png" alt="flutter-candies" title="flutter-candies"></a>

Language: [English](README.md) | [中文简体](README-ZH.md)

Extended official text to build special text like inline image or @somebody quickly,it also support custom background,custom over flow and custom selection toolbar and handles.

## Table of contents
- [extended_text](#extendedtext)
  - [Table of contents](#table-of-contents)
  - [Speical Text](#speical-text)
    - [Create Speical Text](#create-speical-text)
    - [SpecialTextSpanBuilder](#specialtextspanbuilder)
  - [Image](#image)
    - [ImageSpan](#imagespan)
    - [Cache Image](#cache-image)
  - [Selection](#selection)
    - [TextSelectionControls](#textselectioncontrols)
    - [Control ToolBar Handle](#control-toolbar-handle)
      - [Default Behavior](#default-behavior)
      - [Custom Behavior](#custom-behavior)
  - [Custom Background](#custom-background)
  - [Custom Overflow](#custom-overflow)

## Speical Text

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/special_text.jpg)


### Create Speical Text

extended text helps to convert your text to speical textSpan quickly.

for example, follwing code show how to create @xxxx speical textSpan.

```dart
class AtText extends SpecialText {
  AtText(TextStyle textStyle, SpecialTextGestureTapCallback onTap,
      {this.showAtBackground = false, this.start})
      : super(flag, ' ', textStyle, onTap: onTap);
  static const String flag = '@';
  final int start;

  /// whether show background for @somebody
  final bool showAtBackground;

  @override
  InlineSpan finishText() {
    final TextStyle textStyle =
        this.textStyle?.copyWith(color: Colors.blue, fontSize: 16.0);

    final String atText = toString();

    return showAtBackground
        ? BackgroundTextSpan(
            background: Paint()..color = Colors.blue.withOpacity(0.15),
            text: atText,
            actualText: atText,
            start: start,

            ///caret can move into special text
            deleteAll: true,
            style: textStyle,
            recognizer: (TapGestureRecognizer()
              ..onTap = () {
                if (onTap != null) {
                  onTap(atText);
                }
              }))
        : SpecialTextSpan(
            text: atText,
            actualText: atText,
            start: start,
            style: textStyle,
            recognizer: (TapGestureRecognizer()
              ..onTap = () {
                if (onTap != null) {
                  onTap(atText);
                }
              }));
  }
}
```

### SpecialTextSpanBuilder

create your SpecialTextSpanBuilder

```dart
class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  MySpecialTextSpanBuilder({this.showAtBackground = false});

  /// whether show background for @somebody
  final bool showAtBackground;
  @override
  TextSpan build(String data,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap}) {
    if (kIsWeb) {
      return TextSpan(text: data, style: textStyle);
    }

    return super.build(data, textStyle: textStyle, onTap: onTap);
  }

  @override
  SpecialText createSpecialText(String flag,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap, int index}) {
    if (flag == null || flag == '') {
      return null;
    }

    ///index is end index of start flag, so text start index should be index-(flag.length-1)
    if (isStart(flag, AtText.flag)) {
      return AtText(
        textStyle,
        onTap,
        start: index - (AtText.flag.length - 1),
        showAtBackground: showAtBackground,
      );
    } else if (isStart(flag, EmojiText.flag)) {
      return EmojiText(textStyle, start: index - (EmojiText.flag.length - 1));
    } else if (isStart(flag, DollarText.flag)) {
      return DollarText(textStyle, onTap,
          start: index - (DollarText.flag.length - 1));
    }
    return null;
  }
}
```

[more detail](https://github.com/fluttercandies/extended_text/tree/master/example/lib/special_text)

## Image

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/custom_image.gif)

### ImageSpan

show inline image by using ImageSpan.

```dart
class ImageSpan extends ExtendedWidgetSpan {
  ImageSpan(
    ImageProvider image, {
    Key key,
    @required double imageWidth,
    @required double imageHeight,
    EdgeInsets margin,
    int start = 0,
    ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.bottom,
    String actualText,
    TextBaseline baseline,
    BoxFit fit= BoxFit.scaleDown,
    ImageLoadingBuilder loadingBuilder,
    ImageFrameBuilder frameBuilder,
    String semanticLabel,
    bool excludeFromSemantics = false,
    Color color,
    BlendMode colorBlendMode,
    AlignmentGeometry imageAlignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    FilterQuality filterQuality = FilterQuality.low,
    GestureTapCallback onTap,
    HitTestBehavior behavior = HitTestBehavior.deferToChild,
  })
```

| parameter   | description                                                                   | default  |
| ----------- | ----------------------------------------------------------------------------- | -------- |
| image       | The image to display(ImageProvider).                                          | -        |
| imageWidth  | The width of image(not include margin)                                        | required |
| imageHeight | The height of image(not include margin)                                       | required |
| margin      | The margin of image                                                           | -        |
| actualText  | Actual text, take care of it when enable selection,something likes "\[love\]" | '\uFFFC' |
| start       | Start index of text,take care of it when enable selection.                    | 0        |

## Selection

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/selection.gif)

| parameter             | description                                                                                                          | default                                                                      |
| --------------------- | -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| selectionEnabled      | Whether enable selection                                                                                             | false                                                                        |
| selectionColor        | Color of selection                                                                                                   | Theme.of(context).textSelectionColor                                         |
| dragStartBehavior     | DragStartBehavior for text selection                                                                                 | DragStartBehavior.start                                                      |
| textSelectionControls | An interface for building the selection UI, to be provided by the implementor of the toolbar widget or handle widget | extendedMaterialTextSelectionControls/extendedCupertinoTextSelectionControls |

### TextSelectionControls

default value of textSelectionControls are MaterialExtendedTextSelectionControls/CupertinoExtendedTextSelectionControls

override buildToolbar or buildHandle to custom your toolbar widget or handle widget

```dart
class MyExtendedMaterialTextSelectionControls
    extends ExtendedMaterialTextSelectionControls {
  MyExtendedMaterialTextSelectionControls();
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
  ) {}
  
  @override
  Widget buildHandle(
      BuildContext context, TextSelectionHandleType type, double textHeight) {
  }
}

```

### Control ToolBar Handle

contain your page into ExtendedTextSelectionPointerHandler, so you can control toolbar and handle.

#### Default Behavior

set your page as child of ExtendedTextSelectionPointerHandler

```dart
 return ExtendedTextSelectionPointerHandler(
      //default behavior
       child: result,
    );
```

- tap region outside of extended text, hide toolbar and handle
- scorll, hide toolbar and handle

#### Custom Behavior

get selectionStates(ExtendedTextSelectionState) by builder call back, and handle by your self.

```dart
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
```
[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/pages/text_selection_demo.dart)

## Custom Background

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/background.png)

refer to issues [24335](https://github.com/flutter/flutter/issues/24335)/[24337](https://github.com/flutter/flutter/issues/24337) about background

```dart
  BackgroundTextSpan(
      text:
          "This text has nice background with borderradius,no mattter how many line,it likes nice",
      background: Paint()..color = Colors.indigo,
      clipBorderRadius: BorderRadius.all(Radius.circular(3.0))),
```
| parameter        | description                                                  | default |
| ---------------- | ------------------------------------------------------------ | ------- |
| background       | Background painter                                           | -       |
| clipBorderRadius | Clip BorderRadius                                            | -       |
| paintBackground  | Paint background call back, you can paint background by self | -       |

[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/pages/background_text_demo.dart)

## Custom Overflow

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/overflow.jpg)

refer to issue [26748](https://github.com/flutter/flutter/issues/26748)

| parameter   | description                                                  | default             |
| ----------- | ------------------------------------------------------------ | ------------------- |
| child       | The widget of TextOverflow.                                  | @required           |
| maxHeight   | The maxHeight of [TextOverflowWidget], default is preferredLineHeight. | preferredLineHeight |
| align       | The Align of [TextOverflowWidget], left/right.               | right               |
| fixedOffset | Fixed offset refer to the Text Overflow Rect and [child].    | -                   |

```dart
  ExtendedText(...
            overFlowWidget:
                TextOverflowWidget(
                    //maxHeight: double.infinity,
                    //align: TextOverflowAlign.right,
                    //fixedOffset: Offset.zero,
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
                    ),
                  ),
            ...
          )
```

[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/pages/custom_text_overflow_demo.dart)
