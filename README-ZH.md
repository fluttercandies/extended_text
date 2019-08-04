# extended_text

[![pub package](https://img.shields.io/pub/v/extended_text.svg)](https://pub.dartlang.org/packages/extended_text)

文档语言: [English](README.md) | [中文简体](README-ZH.md)

官方Text扩展组件，支持特殊文本效果（比如图片，@人）,自定义背景，自定义文本溢出效果,文本选择以及自定义选择菜单和选择器

- [Flutter RichText 支持图片显示和自定义图片效果](https://juejin.im/post/5c8be0d06fb9a049a42ff067)
- [Flutter RichText 支持自定义文本溢出效果](https://juejin.im/post/5c8ca608f265da2dd6394001)
- [Flutter RichText 支持自定义文字背景](https://juejin.im/post/5c8bf9516fb9a049c9669204)
- [Flutter RichText 支持特殊文字效果](https://juejin.im/post/5c8bf4fce51d451066008fa2)
- [Flutter RichText支持文本选择](https://juejin.im/post/5cff71d46fb9a07ea6486a0e)  

欢迎加入[Flutter Candies](https://github.com/fluttercandies)，一起生产可爱的Flutter小糖果(QQ群181398081)

## 目录
- [extended_text](#extendedtext)
  - [目录](#%E7%9B%AE%E5%BD%95)
  - [特殊文本](#%E7%89%B9%E6%AE%8A%E6%96%87%E6%9C%AC)
    - [创建特殊文本](#%E5%88%9B%E5%BB%BA%E7%89%B9%E6%AE%8A%E6%96%87%E6%9C%AC)
    - [特殊文本Builder](#%E7%89%B9%E6%AE%8A%E6%96%87%E6%9C%ACBuilder)
  - [图片](#%E5%9B%BE%E7%89%87)
    - [ImageSpan](#ImageSpan)
    - [缓存图片](#%E7%BC%93%E5%AD%98%E5%9B%BE%E7%89%87)
  - [文本选择](#%E6%96%87%E6%9C%AC%E9%80%89%E6%8B%A9)
    - [文本选择控制器](#%E6%96%87%E6%9C%AC%E9%80%89%E6%8B%A9%E6%8E%A7%E5%88%B6%E5%99%A8)
    - [工具栏和选择器的控制](#%E5%B7%A5%E5%85%B7%E6%A0%8F%E5%92%8C%E9%80%89%E6%8B%A9%E5%99%A8%E7%9A%84%E6%8E%A7%E5%88%B6)
      - [默认行为](#%E9%BB%98%E8%AE%A4%E8%A1%8C%E4%B8%BA)
      - [自定义行为](#%E8%87%AA%E5%AE%9A%E4%B9%89%E8%A1%8C%E4%B8%BA)
  - [自定义背景](#%E8%87%AA%E5%AE%9A%E4%B9%89%E8%83%8C%E6%99%AF)
  - [自定义文本溢出](#%E8%87%AA%E5%AE%9A%E4%B9%89%E6%96%87%E6%9C%AC%E6%BA%A2%E5%87%BA)

## 特殊文本

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/special_text.jpg)


### 创建特殊文本

extended_text 帮助将字符串文本快速转换为特殊的TextSpan

下面的例子告诉你怎么创建一个@xxx

具体思路是对字符串进行进栈遍历，通过判断flag来判定是否是一个特殊字符。
例子：@zmtzawqlp ，以@开头并且以空格结束，我们就认为它是一个@的特殊文本

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

### 特殊文本Builder

创建属于你自己规则的Builder，上面说了你可以继承SpecialText来定义各种各样的特殊文本。
- build 方法中，是通过具体思路是对字符串进行进栈遍历，通过判断flag来判定是否是一个特殊文本。
  感兴趣的，可以看一下SpecialTextSpanBuilder里面build方法的实现，当然你也可以写出属于自己的build逻辑
- createSpecialText 通过判断flag来判定是否是一个特殊文本

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

其实你也不是一定要用这套代码将字符串转换为TextSpan，你可以有自己的方法，给最后的TextSpan就可以了。

[more detail](https://github.com/fluttercandies/extended_text/tree/master/example/lib/special_text)

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

### 缓存图片

你可以用ExtendedNetworkImageProvider来缓存文本中的图片，使用clearDiskCachedImages方法来清掉本地缓存

引入 extended_image_library

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

| 参数        | 描述                | 默认                |
| ----------- | ------------------- | ------------------- |
| url         | 网络请求地址        | required            |
| scale       | ImageInfo中的scale  | 1.0                 |
| headers     | HttpClient的headers | -                   |
| cache       | 是否缓存到本地      | false               |
| retries     | 请求尝试次数        | 3                   |
| timeLimit   | 请求超时            | -                   |
| timeRetry   | 请求重试间隔        | milliseconds: 100   |
| cancelToken | 用于取消请求的Token | CancellationToken() |

```dart
/// Clear the disk cache directory then return if it succeed.
///  <param name="duration">timespan to compute whether file has expired or not</param>
Future<bool> clearDiskCachedImages({Duration duration}) async
```

[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/custom_image_demo.dart)


## 文本选择

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/selection.gif)

| 参数                  | 描述                                                 | 默认                                                                         |
| --------------------- | ---------------------------------------------------- | ---------------------------------------------------------------------------- |
| selectionEnabled      | 是否开启文本选择功能                                 | false                                                                        |
| selectionColor        | 文本选择的颜色                                       | Theme.of(context).textSelectionColor                                         |
| dragStartBehavior     | 文本选择的拖拽行为                                   | DragStartBehavior.start                                                      |
| textSelectionControls | 文本选择控制器，你可以通过重写，来定义工具栏和选择器 | extendedMaterialTextSelectionControls/extendedCupertinoTextSelectionControls |

### 文本选择控制器

extended_text提供了默认的控制器extendedMaterialTextSelectionControls/extendedCupertinoTextSelectionControls 

你可以通过重写，来定义工具栏和选择器

```dart
class MyExtendedMaterialTextSelectionControls
    extends MaterialExtendedTextSelectionControls {
  MyExtendedMaterialTextSelectionControls();
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset position,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
  ) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));

    // The toolbar should appear below the TextField
    // when there is not enough space above the TextField to show it.
    final TextSelectionPoint startTextSelectionPoint = endpoints[0];
    final TextSelectionPoint endTextSelectionPoint =
        (endpoints.length > 1) ? endpoints[1] : null;
    final double x = (endTextSelectionPoint == null)
        ? startTextSelectionPoint.point.dx
        : (startTextSelectionPoint.point.dx + endTextSelectionPoint.point.dx) /
            2.0;
    final double availableHeight = globalEditableRegion.top -
        MediaQuery.of(context).padding.top -
        _kToolbarScreenPadding;
    final double y = (availableHeight < _kToolbarHeight)
        ? startTextSelectionPoint.point.dy +
            globalEditableRegion.height +
            _kToolbarHeight +
            _kToolbarScreenPadding
        : startTextSelectionPoint.point.dy - textLineHeight * 2.0;
    final Offset preciseMidpoint = Offset(x, y);

    return ConstrainedBox(
      constraints: BoxConstraints.tight(globalEditableRegion.size),
      child: CustomSingleChildLayout(
        delegate: MaterialExtendedTextSelectionToolbarLayout(
          MediaQuery.of(context).size,
          globalEditableRegion,
          preciseMidpoint,
        ),
        child: _TextSelectionToolbar(
          handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
          handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
          handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
          handleSelectAll:
              canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
          handleLike: () {
            //mailto:<email address>?subject=<subject>&body=<body>, e.g.
            launch(
                "mailto:zmtzawqlp@live.com?subject=extended_text_share&body=${delegate.textEditingValue.text}");
            delegate.hideToolbar();
            //clear selecction
            delegate.textEditingValue = delegate.textEditingValue.copyWith(
                selection: TextSelection.collapsed(
                    offset: delegate.textEditingValue.selection.end));
          },
        ),
      ),
    );
  }

  @override
  Widget buildHandle(
      BuildContext context, TextSelectionHandleType type, double textHeight) {
    final Widget handle = SizedBox(
      width: _kHandleSize,
      height: _kHandleSize,
      child: Image.asset("assets/love.png"),
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
    assert(type != null);
    return null;
  }
}

/// Manages a copy/paste text selection toolbar.
class _TextSelectionToolbar extends StatelessWidget {
  const _TextSelectionToolbar({
    Key key,
    this.handleCopy,
    this.handleSelectAll,
    this.handleCut,
    this.handlePaste,
    this.handleLike,
  }) : super(key: key);

  final VoidCallback handleCut;
  final VoidCallback handleCopy;
  final VoidCallback handlePaste;
  final VoidCallback handleSelectAll;
  final VoidCallback handleLike;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    if (handleCut != null)
      items.add(FlatButton(
          child: Text(localizations.cutButtonLabel), onPressed: handleCut));
    if (handleCopy != null)
      items.add(FlatButton(
          child: Text(localizations.copyButtonLabel), onPressed: handleCopy));
    if (handlePaste != null)
      items.add(FlatButton(
        child: Text(localizations.pasteButtonLabel),
        onPressed: handlePaste,
      ));
    if (handleSelectAll != null)
      items.add(FlatButton(
          child: Text(localizations.selectAllButtonLabel),
          onPressed: handleSelectAll));

    if (handleLike != null)
      items.add(FlatButton(child: Icon(Icons.favorite), onPressed: handleLike));

    // If there is no option available, build an empty widget.
    if (items.isEmpty) {
      return Container(width: 0.0, height: 0.0);
    }

    return Material(
      elevation: 1.0,
      child: Wrap(children: items),
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
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
[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/text_selection_demo.dart)

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

[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/background_text_demo.dart)

## 自定义文本溢出

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/overflow.jpg)

文本溢出相关issue [26748](https://github.com/flutter/flutter/issues/26748)

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
