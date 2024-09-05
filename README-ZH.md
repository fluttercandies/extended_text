# extended_text

[![pub package](https://img.shields.io/pub/v/extended_text.svg)](https://pub.dartlang.org/packages/extended_text) [![GitHub stars](https://img.shields.io/github/stars/fluttercandies/extended_text)](https://github.com/fluttercandies/extended_text/stargazers) [![GitHub forks](https://img.shields.io/github/forks/fluttercandies/extended_text)](https://github.com/fluttercandies/extended_text/network)  [![GitHub license](https://img.shields.io/github/license/fluttercandies/extended_text)](https://github.com/fluttercandies/extended_text/blob/master/LICENSE)  [![GitHub issues](https://img.shields.io/github/issues/fluttercandies/extended_text)](https://github.com/fluttercandies/extended_text/issues) <a target="_blank" href="https://jq.qq.com/?_wv=1027&k=5bcc0gy"><img border="0" src="https://pub.idqqimg.com/wpa/images/group.png" alt="flutter-candies" title="flutter-candies"></a>

文档语言: [English](README.md) | 中文简体

官方Text扩展组件，支持特殊文本效果（比如图片，@人）,自定义背景，自定义文本溢出效果,文本选择以及自定义选择菜单和选择器

[ExtendedText 在线 Demo](https://fluttercandies.github.io/extended_text/)

- [Flutter RichText 支持图片显示和自定义图片效果](https://juejin.im/post/5c8be0d06fb9a049a42ff067)
- [Flutter RichText 支持自定义文本溢出效果](https://juejin.im/post/5c8ca608f265da2dd6394001)
- [Flutter RichText 支持自定义文字背景](https://juejin.im/post/5c8bf9516fb9a049c9669204)
- [Flutter RichText 支持特殊文字效果](https://juejin.im/post/5c8bf4fce51d451066008fa2)
- [Flutter RichText支持文本选择](https://juejin.im/post/5cff71d46fb9a07ea6486a0e)


ExtendedText 是 Flutter 官方 Text 的三方扩展库，主要扩展功能如下:
| 功能                       | ExtendedText                                                | Flutter 官方 Text                                                                                                           |
| -------------------------- | ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 支持自定义文本溢出效果     | 支持，可以自定义溢出的 Widget，并控制溢出位置（前、中、后） | 不支 持 ([26748](https://github.com/flutter/flutter/issues/26748),[45336](https://github.com/flutter/flutter/issues/45336)) |
| 支持复制特殊文本的真实值   | 支持，可以复制出文本的真实值，而不仅是 WidgetSpan 的占位值  | 只能复制出 WidgetSpan 的占位值 (\uFFFC)                                                                                     |
| 根据文本格式快速构建富文本 | 支持，可以根据文本格式快速构建富文本                        | 不支持                                                                                                                      |

> 已支持 `HarmonyOS`. 请使用最新的带有 `ohos` 标志的版本. 你可以在 `Versions` 签查找.

```yaml
dependencies:
  extended_text: 10.0.1-ohos
```

## 目录
- [extended_text](#extendedtext)
  - [目录](#%e7%9b%ae%e5%bd%95)
  - [特殊文本](#%e7%89%b9%e6%ae%8a%e6%96%87%e6%9c%ac)
    - [创建特殊文本](#%e5%88%9b%e5%bb%ba%e7%89%b9%e6%ae%8a%e6%96%87%e6%9c%ac)
    - [特殊文本Builder](#%e7%89%b9%e6%ae%8a%e6%96%87%e6%9c%acbuilder)
  - [图片](#%e5%9b%be%e7%89%87)
    - [ImageSpan](#imagespan)
    - [缓存图片](#%e7%bc%93%e5%ad%98%e5%9b%be%e7%89%87)
  - [文本选择](#%e6%96%87%e6%9c%ac%e9%80%89%e6%8b%a9)
    - [文本选择控制器](#%e6%96%87%e6%9c%ac%e9%80%89%e6%8b%a9%e6%8e%a7%e5%88%b6%e5%99%a8)
    - [工具栏和选择器的控制](#%e5%b7%a5%e5%85%b7%e6%a0%8f%e5%92%8c%e9%80%89%e6%8b%a9%e5%99%a8%e7%9a%84%e6%8e%a7%e5%88%b6)
      - [默认行为](#%e9%bb%98%e8%ae%a4%e8%a1%8c%e4%b8%ba)
      - [自定义行为](#%e8%87%aa%e5%ae%9a%e4%b9%89%e8%a1%8c%e4%b8%ba)
  - [自定义背景](#%e8%87%aa%e5%ae%9a%e4%b9%89%e8%83%8c%e6%99%af)
  - [自定义文本溢出](#%e8%87%aa%e5%ae%9a%e4%b9%89%e6%96%87%e6%9c%ac%e6%ba%a2%e5%87%ba)

## 特殊文本

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/special_text.jpg)


### 创建特殊文本

extended_text 帮助将字符串文本快速转换为特殊的TextSpan

下面的例子告诉你怎么创建一个@xxx

具体思路是对字符串进行进栈遍历，通过判断flag来判定是否是一个特殊字符。
例子：@zmtzawqlp ，以@开头并且以空格结束，我们就认为它是一个@的特殊文本

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

### 特殊文本Builder

创建属于你自己规则的Builder，上面说了你可以继承SpecialText来定义各种各样的特殊文本。
- build 方法中，是通过具体思路是对字符串进行进栈遍历，通过判断flag来判定是否是一个特殊文本。
  感兴趣的，可以看一下SpecialTextSpanBuilder里面build方法的实现，当然你也可以写出属于自己的build逻辑
- createSpecialText 通过判断flag来判定是否是一个特殊文本

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

其实你也不是一定要用这套代码将字符串转换为TextSpan，你可以有自己的方法，给最后的TextSpan就可以了。


## 图片

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/custom_image.gif)

### ImageSpan

使用ImageSpan 展示图片

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

| 参数        | 描述                                                              | 默认             |
| ----------- | ----------------------------------------------------------------- | ---------------- |
| image       | 图片展示的Provider(ImageProvider)                                 | -                |
| imageWidth  | 宽度，不包括 margin                                               | 必填             |
| imageHeight | 高度，不包括 margin                                               | 必填             |
| margin      | 图片的margin                                                      | -                |
| actualText  | 真实的文本,当你开启文本选择功能的时候，必须设置,比如图片"\[love\] | 空占位符'\uFFFC' |
| start       | 在文本字符串中的开始位置,当你开启文本选择功能的时候，必须设置     | 0                |

## 文本选择

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/selection.gif)

| 参数                  | 描述                                                 | 默认                                                                         |
| --------------------- | ---------------------------------------------------- | ---------------------------------------------------------------------------- |
| selectionEnabled      | 是否开启文本选择功能                                 | false                                                                        |
| selectionColor        | 文本选择的颜色                                       | Theme.of(context).textSelectionColor                                         |
| dragStartBehavior     | 文本选择的拖拽行为                                   | DragStartBehavior.start                                                      |
| textSelectionControls | 文本选择控制器，你可以通过重写，来定义工具栏和选择器 | extendedMaterialTextSelectionControls/extendedCupertinoTextSelectionControls |

### 文本选择控制器

 
你可以通过重写 [SelectionArea.contextMenuBuilder] 和 [TextSelectionControls]， 来定义工具栏和选择器

```dart
const double _kHandleSize = 22.0;

/// Android Material styled text selection controls.

class MyTextSelectionControls extends TextSelectionControls
    with TextSelectionHandleControls {
  MyTextSelectionControls({this.joinZeroWidthSpace = false});
  final bool joinZeroWidthSpace;

  /// Returns the size of the Material handle.
  @override
  Size getHandleSize(double textLineHeight) =>
      const Size(_kHandleSize, _kHandleSize);

  /// Builder for material-style text selection handles.
  @override
  Widget buildHandle(
      BuildContext context, TextSelectionHandleType type, double textLineHeight,
      [VoidCallback? onTap, double? startGlyphHeight, double? endGlyphHeight]) {
    final Widget handle = SizedBox(
      width: _kHandleSize,
      height: _kHandleSize,
      child: Image.asset(
        'assets/40.png',
      ),
    );

    // [handle] is a circle, with a rectangle in the top left quadrant of that
    // circle (an onion pointing to 10:30). We rotate [handle] to point
    // straight up or up-right depending on the handle type.
    switch (type) {
      case TextSelectionHandleType.left: // points up-right
        return Transform.rotate(
          angle: math.pi / 4.0,
          child: handle,
        );
      case TextSelectionHandleType.right: // points up-left
        return Transform.rotate(
          angle: -math.pi / 4.0,
          child: handle,
        );
      case TextSelectionHandleType.collapsed: // points up
        return handle;
    }
  }

  /// Gets anchor for material-style text selection handles.
  ///
  /// See [TextSelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight,
      [double? startGlyphHeight, double? endGlyphHeight]) {
    switch (type) {
      case TextSelectionHandleType.left:
        return const Offset(_kHandleSize, 0);
      case TextSelectionHandleType.right:
        return Offset.zero;
      default:
        return const Offset(_kHandleSize / 2, -4);
    }
  }
}

class CommonSelectionArea extends StatelessWidget {
  const CommonSelectionArea({
    super.key,
    required this.child,
    this.joinZeroWidthSpace = false,
  });
  final Widget child;
  final bool joinZeroWidthSpace;

  @override
  Widget build(BuildContext context) {
    SelectedContent? _selectedContent;
    return SelectionArea(
      contextMenuBuilder:
          (BuildContext context, SelectableRegionState selectableRegionState) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          buttonItems: <ContextMenuButtonItem>[
            ContextMenuButtonItem(
              onPressed: () {
                // TODO(zmtzawqlp):  how to get Selectable
                // and  _clearSelection is not public
                // https://github.com/flutter/flutter/issues/126980

                //  onCopy: () {
                //   _copy();

                //   // In Android copy should clear the selection.
                //   switch (defaultTargetPlatform) {
                //     case TargetPlatform.android:
                //     case TargetPlatform.fuchsia:
                //       _clearSelection();
                //     case TargetPlatform.iOS:
                //       hideToolbar(false);
                //     case TargetPlatform.linux:
                //     case TargetPlatform.macOS:
                //     case TargetPlatform.windows:
                //       hideToolbar();
                //   }
                // },

                // if (_selectedContent != null) {
                //   String content = _selectedContent!.plainText;
                //   if (joinZeroWidthSpace) {
                //     content = content.replaceAll(zeroWidthSpace, '');
                //   }

                //   Clipboard.setData(ClipboardData(text: content));
                //   selectableRegionState.hideToolbar(true);
                //   selectableRegionState._clearSelection();
                // }

                selectableRegionState
                    .copySelection(SelectionChangedCause.toolbar);

                // remove zeroWidthSpace
                if (joinZeroWidthSpace) {
                  Clipboard.getData('text/plain').then((ClipboardData? value) {
                    if (value != null) {
                      // remove zeroWidthSpace
                      final String? plainText =
                          value.text?.replaceAll(ExtendedTextLibraryUtils.zeroWidthSpace, '');
                      if (plainText != null) {
                        Clipboard.setData(ClipboardData(text: plainText));
                      }
                    }
                  });
                }
              },
              type: ContextMenuButtonType.copy,
            ),
            ContextMenuButtonItem(
              onPressed: () {
                selectableRegionState.selectAll(SelectionChangedCause.toolbar);
              },
              type: ContextMenuButtonType.selectAll,
            ),
            ContextMenuButtonItem(
              onPressed: () {
                launchUrl(Uri.parse(
                    'mailto:zmtzawqlp@live.com?subject=extended_text_share&body=${_selectedContent?.plainText}'));
                selectableRegionState.hideToolbar();
              },
              type: ContextMenuButtonType.custom,
              label: 'like',
            ),
          ],
          anchors: selectableRegionState.contextMenuAnchors,
        );
        // return AdaptiveTextSelectionToolbar.selectableRegion(
        //   selectableRegionState: selectableRegionState,
        // );
      },
      // magnifierConfiguration: TextMagnifierConfiguration(
      //   magnifierBuilder: (
      //     BuildContext context,
      //     MagnifierController controller,
      //     ValueNotifier<MagnifierInfo> magnifierInfo,
      //   ) {
      //     return TextMagnifier(
      //       magnifierInfo: magnifierInfo,
      //     );
      //     // switch (defaultTargetPlatform) {
      //     //   case TargetPlatform.iOS:
      //     //     return CupertinoTextMagnifier(
      //     //       controller: controller,
      //     //       magnifierInfo: magnifierInfo,
      //     //     );
      //     //   case TargetPlatform.android:
      //     //     return TextMagnifier(
      //     //       magnifierInfo: magnifierInfo,
      //     //     );
      //     //   case TargetPlatform.fuchsia:
      //     //   case TargetPlatform.linux:
      //     //   case TargetPlatform.macOS:
      //     //   case TargetPlatform.windows:
      //     //     return null;
      //     // }
      //   },
      // ),
      // selectionControls: MyTextSelectionControls(),
      onSelectionChanged: (SelectedContent? value) {
        print(value?.plainText);
        _selectedContent = value;
      },
      child: child,
    );
  }
}
```

### 工具栏和选择器的控制

你可以通过将你的页面包裹到ExtendedTextSelectionPointerHandler里面来定义不同的行为效果。

#### 默认行为

通过赋值ExtendedTextSelectionPointerHandler的child为你的页面，将会有默认的行为

```dart
 return ExtendedTextSelectionPointerHandler(
      //default behavior
       child: result,
    );
```

- 当点击extended_text之外的区域的时候，关闭工具栏和选择器
- 滚动的时候，关闭工具栏和选择器

#### 自定义行为

你可以通过builder方法获取到页面上面的全部的selectionStates(ExtendedTextSelectionState)，并且通过自己获取点击事件来处理工具栏和选择器

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

## 自定义背景

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/background.png)

Text背景相关的issue[24335](https://github.com/flutter/flutter/issues/24335)/[24337](https://github.com/flutter/flutter/issues/24337)

```dart
  BackgroundTextSpan(
      text:
          "This text has nice background with borderradius,no mattter how many line,it likes nice",
      background: Paint()..color = Colors.indigo,
      clipBorderRadius: BorderRadius.all(Radius.circular(3.0))),
```
| 参数             | 描述                                       | 默认 |
| ---------------- | ------------------------------------------ | ---- |
| background       | 背景画刷                                   | -    |
| clipBorderRadius | 用于裁剪背景                               | -    |
| paintBackground  | 绘制背景的回调，你可以按照你的想法绘画背景 | -    |

## 自定义文本溢出

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/overflow.jpg)

文本溢出相关issue [26748](https://github.com/flutter/flutter/issues/26748)

| parameter | description                                                           | default                  |
| --------- | --------------------------------------------------------------------- | ------------------------ |
| child     | The widget of TextOverflow.                                           | @required                |
| maxHeight | Widget的最大高度，默认为 TextPaint计算出来的行高 preferredLineHeight. | preferredLineHeight      |
| align     | left，靠近最后裁剪文本；right，靠近文本的右下角                       | right                    |
| position  | 溢出文本出现的地方.                                                   | TextOverflowPosition.end |

```dart
  ExtendedText(
   overflowWidget: TextOverflowWidget(
     position: TextOverflowPosition.end,
     align: TextOverflowAlign.center,
     // just for debug
     debugOverflowRectColor: Colors.red.withOpacity(0.1),
     child: Container(
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
  )
```

## Join Zero-Width Space

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/JoinZeroWidthSpace.jpg)

相关问题 [18761](https://github.com/flutter/flutter/issues/18761)

如果[ExtendedText.joinZeroWidthSpace] 为 true, 将会添加'\u{200B}' 到文本中, 让换行或者文本溢出看起来更好。

```dart
  ExtendedText(
      joinZeroWidthSpace: true,
    )
```

或者你也可以通过下面的方法自己转换

1. 文本

```dart
  String input='abc'.joinChar();
```

2. InlineSpan

```dart
     InlineSpan innerTextSpan;
     innerTextSpan = joinChar(
        innerTextSpan,
        Accumulator(),
        zeroWidthSpace,
    );
```
注意以下问题:

1. word 不再是 word，你将无法通过双击选择 word。

2. 文本被修改了, 如果 [ExtendedText.selectionEnabled] 为 true, 你需要重写 TextSelectionControls，将字符串还原。

``` dart

class MyTextSelectionControls extends TextSelectionControls {

  @override
  void handleCopy(TextSelectionDelegate delegate,
      ClipboardStatusNotifier? clipboardStatus) {
    final TextEditingValue value = delegate.textEditingValue;

    String data = value.selection.textInside(value.text);
    // remove zeroWidthSpace
    data = data.replaceAll(zeroWidthSpace, '');

    Clipboard.setData(ClipboardData(
      text: value.selection.textInside(value.text),
    ));
    clipboardStatus?.update();
    delegate.textEditingValue = TextEditingValue(
      text: value.text,
      selection: TextSelection.collapsed(offset: value.selection.end),
    );
    delegate.bringIntoView(delegate.textEditingValue.selection.extent);
    delegate.hideToolbar();
  }
}

```

## Gradient

### GradientConfig


用于配置文本渐变的设置。

* [gradient] 是要应用于文本的渐变效果。
* [ignoreWidgetSpan] 决定是否将 WidgetSpan 元素包含在渐变应用中。默认情况下，WidgetSpan 被忽略。
* [renderMode] 指定渐变应用于文本的方式。默认值为 [GradientRenderMode.fullText]，即将渐变应用于整个文本。
* [ignoreRegex] 是一个正则表达式，用于排除文本中的某些部分，使其不受渐变效果影响。例如，可以用来排除特定字符或词语（如表情符号或特殊符号）以免它们受到渐变的影响。
* [beforeDrawGradient] 在渐变被绘制到文本之前调用的回调函数。

* [blendMode] 应用于渐变的混合模式。
   默认值: [BlendMode.srcIn]（即渐变将应用于文本上）。
   推荐使用 [BlendMode.srcIn] 或 [BlendMode.srcATop]。

``` dart
  GradientConfig _config = GradientConfig(
    gradient: const LinearGradient(
      colors: <Color>[Colors.blue, Colors.red],
    ),
    ignoreRegex: GradientConfig.ignoreEmojiRegex,
    ignoreWidgetSpan: true,
    renderMode: GradientRenderMode.fullText,
  );
```

### IgnoreGradientSpan

该 `InlineSpan` 将始终忽略渐变效果。

``` dart
class IgnoreGradientTextSpan extends TextSpan with IgnoreGradientSpan {
  IgnoreGradientTextSpan({String? text, List<InlineSpan>? children})
      : super(
          text: text,
          children: children,
        );
}
```



## ☕️Buy me a coffee

![img](http://zmtzawqlp.gitee.io/my_images/images/qrcode.png)
