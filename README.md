# extended_text

[![pub package](https://img.shields.io/pub/v/extended_text.svg)](https://pub.dartlang.org/packages/extended_text)

Language: [English](README.md) | [中文简体](README-ZH.md)

A powerful extended official text for Dart, which supports Speical Text(Image,@somebody), Custom Background, Custom overFlow, Text Selection.

## Table of contents
- [extended_text](#extendedtext)
  - [Table of contents](#Table-of-contents)
  - [Speical Text](#Speical-Text)
    - [Create Speical Text](#Create-Speical-Text)
    - [SpecialTextSpanBuilder](#SpecialTextSpanBuilder)
  - [Image](#Image)
    - [ImageSpan](#ImageSpan)
    - [Cache Image](#Cache-Image)
  - [Selection](#Selection)
    - [TextSelectionControls](#TextSelectionControls)
    - [Control ToolBar Handle](#Control-ToolBar-Handle)
      - [Default Behavior](#Default-Behavior)
      - [Custom Behavior](#Custom-Behavior)
  - [Custom Background](#Custom-Background)
  - [Custom Overflow](#Custom-Overflow)

## Speical Text

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/special_text.jpg)


### Create Speical Text

extended text helps to convert your text to speical textSpan quickly.

for example, follwing code show how to create @xxxx speical textSpan.

```dart
class AtText extends SpecialText {
  static const String flag = "@";
  final int start;

  /// whether show background for @somebody
  final bool showAtBackground;

  final BuilderType type;
  AtText(TextStyle textStyle, SpecialTextGestureTapCallback onTap,
      {this.showAtBackground: false, this.type, this.start})
      : super(flag, " ", textStyle, onTap: onTap);

  @override
  TextSpan finishText() {
    TextStyle textStyle =
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
            recognizer: type == BuilderType.extendedText
                ? (TapGestureRecognizer()
                  ..onTap = () {
                    if (onTap != null) onTap(atText);
                  })
                : null)
        : SpecialTextSpan(
            text: atText,
            actualText: atText,
            start: start,
            style: textStyle,
            recognizer: type == BuilderType.extendedText
                ? (TapGestureRecognizer()
                  ..onTap = () {
                    if (onTap != null) onTap(atText);
                  })
                : null);
  }
}

```

### SpecialTextSpanBuilder

create your SpecialTextSpanBuilder

```dart
class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  /// whether show background for @somebody
  final bool showAtBackground;
  final BuilderType type;
  MySpecialTextSpanBuilder(
      {this.showAtBackground: false, this.type: BuilderType.extendedText});

  @override
  TextSpan build(String data, {TextStyle textStyle, onTap}) {
    var textSpan = super.build(data, textStyle: textStyle, onTap: onTap);
    return textSpan;
  }

  @override
  SpecialText createSpecialText(String flag,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap, int index}) {
    if (flag == null || flag == "") return null;

    ///index is end index of start flag, so text start index should be index-(flag.length-1)
    if (isStart(flag, AtText.flag)) {
      return AtText(textStyle, onTap,
          start: index - (AtText.flag.length - 1),
          showAtBackground: showAtBackground,
          type: type);
    } else if (isStart(flag, EmojiText.flag)) {
      return EmojiText(textStyle, start: index - (EmojiText.flag.length - 1));
    } else if (isStart(flag, DollarText.flag)) {
      return DollarText(textStyle, onTap,
          start: index - (DollarText.flag.length - 1), type: type);
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
ImageSpan(
    ImageProvider image, {
    Key key,
    @required double imageWidth,
    @required double imageHeight,
    EdgeInsets margin,
    int start: 0,
    ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.bottom,
    String actualText,
    TextBaseline baseline,
    TextStyle style,
    BoxFit fit: BoxFit.scaleDown,
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
  })

ImageSpan(AssetImage("xxx.jpg"),
        imageWidth: size,
        imageHeight: size,
        margin: EdgeInsets.only(left: 2.0, bottom: 0.0, right: 2.0));
  }
```

| parameter   | description                                                                   | default  |
| ----------- | ----------------------------------------------------------------------------- | -------- |
| image       | The image to display(ImageProvider).                                          | -        |
| imageWidth  | The width of image(not include margin)                                        | required |
| imageHeight | The height of image(not include margin)                                       | required |
| margin      | The margin of image                                                           | -        |
| actualText  | Actual text, take care of it when enable selection,something likes "\[love\]" | '\uFFFC' |
| start       | Start index of text,take care of it when enable selection.                    | 0        |

### Cache Image

if you want cache the network image, you can use ExtendedNetworkImageProvider and clear them with clearDiskCachedImages

import extended_image_library

```dart
dependencies:
  extended_image_library: ^0.1.4
```

```dart
ExtendedNetworkImageProvider(
  this.url, {
  this.scale = 1.0,
  this.headers,
  this.cache: false,
  this.retries = 3,
  this.timeLimit,
  this.timeRetry = const Duration(milliseconds: 100),
  CancellationToken cancelToken,
})  : assert(url != null),
      assert(scale != null),
      cancelToken = cancelToken ?? CancellationToken();
```

| parameter   | description                                                                           | default             |
| ----------- | ------------------------------------------------------------------------------------- | ------------------- |
| url         | The URL from which the image will be fetched.                                         | required            |
| scale       | The scale to place in the [ImageInfo] object of the image.                            | 1.0                 |
| headers     | The HTTP headers that will be used with [HttpClient.get] to fetch image from network. | -                   |
| cache       | whether cache image to local                                                          | false               |
| retries     | the time to retry to request                                                          | 3                   |
| timeLimit   | time limit to request image                                                           | -                   |
| timeRetry   | the time duration to retry to request                                                 | milliseconds: 100   |
| cancelToken | token to cancel network request                                                       | CancellationToken() |

```dart
/// Clear the disk cache directory then return if it succeed.
///  <param name="duration">timespan to compute whether file has expired or not</param>
Future<bool> clearDiskCachedImages({Duration duration}) async
```

[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/custom_image_demo.dart)


## Selection

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/selection.gif)

| parameter             | description                                                                                                          | default                                                                      |
| --------------------- | -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| selectionEnabled      | Whether enable selection                                                                                             | false                                                                        |
| selectionColor        | Color of selection                                                                                                   | Theme.of(context).textSelectionColor                                         |
| dragStartBehavior     | DragStartBehavior for text selection                                                                                 | DragStartBehavior.start                                                      |
| textSelectionControls | An interface for building the selection UI, to be provided by the implementor of the toolbar widget or handle widget | extendedMaterialTextSelectionControls/extendedCupertinoTextSelectionControls |

### TextSelectionControls

default value of textSelectionControls are extendedMaterialTextSelectionControls/extendedCupertinoTextSelectionControls 

override buildToolbar or buildHandle to custom your toolbar widget or handle widget

```dart
class MyExtendedMaterialTextSelectionControls
    extends ExtendedMaterialTextSelectionControls {
  @override
  Widget buildToolbar(BuildContext context, Rect globalEditableRegion,
      Offset position, TextSelectionDelegate delegate) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));
    return ConstrainedBox(
      constraints: BoxConstraints.tight(globalEditableRegion.size),
      child: CustomSingleChildLayout(
        delegate: ExtendedTextSelectionToolbarLayout(
          MediaQuery.of(context).size,
          globalEditableRegion,
          position,
        ),
        child: _TextSelectionToolbar(
          handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
          handleSelectAll:
              canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
          handleLike: () {
            //mailto:<email address>?subject=<subject>&body=<body>, e.g.
            launch(
                "mailto:zmtzawqlp@live.com?subject=extended_text_share&body=${delegate.textEditingValue.text}");
            delegate.hideToolbar();
          },
        ),
      ),
    );
  }
}

/// Manages a copy/paste text selection toolbar.
class _TextSelectionToolbar extends StatelessWidget {
  const _TextSelectionToolbar(
      {Key key, this.handleCopy, this.handleSelectAll, this.handleLike})
      : super(key: key);

  final VoidCallback handleCopy;
  final VoidCallback handleSelectAll;
  final VoidCallback handleLike;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    if (handleCopy != null)
      items.add(FlatButton(
          child: Text(localizations.copyButtonLabel), onPressed: handleCopy));
    if (handleSelectAll != null)
      items.add(FlatButton(
          child: Text(localizations.selectAllButtonLabel),
          onPressed: handleSelectAll));
    if (handleLike != null)
      items.add(FlatButton(child: Icon(Icons.favorite), onPressed: handleLike));

    return Material(
      elevation: 1.0,
      child: Container(
        height: 44.0,
        child: Row(mainAxisSize: MainAxisSize.min, children: items),
      ),
    );
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
[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/text_selection_demo.dart)

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

[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/background_text_demo.dart)

## Custom Overflow

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/overflow.jpg)

refer to issue [26748](https://github.com/flutter/flutter/issues/26748)

```dart
  ExtendedText(...
      overFlowTextSpan: OverFlowTextSpan(children: <TextSpan>[
              TextSpan(text: '  \u2026  '),
              TextSpan(
                  text: "more detail",
                  style: TextStyle(
                    color: Colors.blue,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launch(
                          "https://github.com/fluttercandies/extended_text");
                    })
            ]),
            ...
          )
```

[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/custom_text_overflow_demo.dart)
