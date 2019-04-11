# extended_text

[![pub package](https://img.shields.io/pub/v/extended_text.svg)](https://pub.dartlang.org/packages/extended_text)

extended official text to quickly build special text like inline image or @somebody,it also provide custom background,custom over flow.

[Chinese blog](https://juejin.im/post/5c8be0d06fb9a049a42ff067)

## Speical text

extended text helps you to build speical text quickly.

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/special_text.jpg)

for example, follwing code show how to create @xxxx in your text.

you just to extend SpecialText and define your rule.

```dart
class AtText extends SpecialText {
  static const String flag = "@";
  AtText(TextStyle textStyle, SpecialTextGestureTapCallback onTap)
      : super(flag, " ", textStyle, onTap: onTap);

  @override
  TextSpan finishText() {
    // TODO: implement finishText

    final String atText = toString();
    return TextSpan(
        text: atText,
        style: textStyle?.copyWith(color: Colors.blue, fontSize: 16.0),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (onTap != null) onTap(atText);
          });
  }
}

```

and create your SpecialTextSpanBuilder by extend SpecialTextSpanBuilder

```dart
class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  @override
  TextSpan build(String data,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap}) {
    if (data == null || data == "") return null;
    List<TextSpan> inlineList = new List<TextSpan>();
    if (data != null && data.length > 0) {
      SpecialText specialText;
      String textStack = "";
      //String text
      for (int i = 0; i < data.length; i++) {
        String char = data[i];
        if (specialText != null) {
          if (!specialText.isEnd(char)) {
            specialText.appendContent(char);
          } else {
            inlineList.add(specialText.finishText());
            specialText = null;
          }
        } else {
          textStack += char;
          specialText =
              createSpecialText(textStack, textStyle: textStyle, onTap: onTap);
          if (specialText != null) {
            if (textStack.length - specialText.startFlag.length >= 0) {
              textStack = textStack.substring(
                  0, textStack.length - specialText.startFlag.length);
              if (textStack.length > 0) {
                inlineList.add(TextSpan(text: textStack, style: textStyle));
              }
            }
            textStack = "";
          }
        }
      }

      if (specialText != null) {
        inlineList.add(TextSpan(
            text: specialText.startFlag + specialText.getContent(),
            style: textStyle));
      } else if (textStack.length > 0) {
        inlineList.add(TextSpan(text: textStack, style: textStyle));
      }
    }

    // TODO: implement build
    return TextSpan(children: inlineList, style: textStyle);
  }

  @override
  SpecialText createSpecialText(String flag,
      {TextStyle textStyle, SpecialTextGestureTapCallback onTap}) {
    if (flag == null || flag == "") return null;
    // TODO: implement createSpecialText

    if (isStart(flag, AtText.flag)) {
      return AtText(textStyle, onTap);
    } else if (isStart(flag, EmojiText.flag)) {
      return EmojiText(textStyle);
    } else if (isStart(flag, DollarText.flag)) {
      return DollarText(textStyle, onTap);
    }
    return null;
  }
}
```

at last used them in extended text, import thing is that you can define your self rule to create your text span.

```dart
ExtendedText(
          "[love]Extended text help you to build rich text quickly. any special text you will have with extended text. "
              "\n\nIt's my pleasure to invite you to join \$FlutterCandies\$ if you want to improve flutter .[love]"
              "\n\nif you meet any problem, please let me konw @zmtzawqlp .[sun_glasses]",
          onSpecialTextTap: (String data) {
            if (data.startsWith("\$")) {
              launch("https://github.com/fluttercandies");
            } else if (data.startsWith("@")) {
              launch("mailto:zmtzawqlp@live.com");
            }
          },
          specialTextSpanBuilder: MySpecialTextSpanBuilder(),
          overflow: TextOverflow.ellipsis,
          //style: TextStyle(background: Paint()..color = Colors.red),
          maxLines: 10,
        ),
```

[more detail](https://github.com/fluttercandies/extended_text/tree/master/example/lib/special_text)

## Inline-image

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/custom_image.gif)

to show your inline image, you just to use as follwing
```dart
ImageSpan(this.image,
      {@required this.imageWidth,
      @required this.imageHeight,
      this.margin,
      this.beforePaintImage,
      this.afterPaintImage,
      this.fit: BoxFit.scaleDown})

ImageSpan(AssetImage("xxx.jpg"),
          imageWidth: size,
          imageHeight: size,
          margin: EdgeInsets.only(left: 2.0, bottom: 0.0, right: 2.0));
    }
```

and you can also define your image by using beforePaintImage and afterPaintImage.

it's simple to create a loading placeholder.

```dart
ImageSpan(CachedNetworkImage(imageTestUrls.first), beforePaintImage:
                    (Canvas canvas, Rect rect, ImageSpan imageSpan, clearFailedCache: true) {
              bool hasPlaceholder = drawPlaceholder(canvas, rect, imageSpan);
              if (!hasPlaceholder) {
                clearRect(rect, canvas);
              }
              return false;
            },
                margin: EdgeInsets.only(right: 10.0),
                imageWidth: 80.0,
                imageHeight: 60.0),


bool drawPlaceholder(Canvas canvas, Rect rect, ImageSpan imageSpan) {
    bool hasPlaceholder = imageSpan.imageSpanResolver.imageInfo?.image == null;

    if (hasPlaceholder) {
      canvas.drawRect(rect, Paint()..color = Colors.grey);
      var textPainter = TextPainter(
          text: TextSpan(text: "loading", style: TextStyle(fontSize: 10.0)),
          textAlign: TextAlign.center,
          textScaleFactor: 1,
          textDirection: TextDirection.ltr,
          maxLines: 1)
        ..layout(maxWidth: rect.width);

      textPainter.paint(
          canvas,
          Offset(rect.left + (rect.width - textPainter.width) / 2.0,
              rect.top + (rect.height - textPainter.height) / 2.0));
    }
    return hasPlaceholder;
  }

  void clearRect(Rect rect, Canvas canvas) {
    ///if don't save layer
    ///BlendMode.clear will show black
    ///maybe this is bug for blendMode.clear
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }
```

if you want cache the network image, you can use CachedNetworkImage and clear them with clearExtendedTextDiskCachedImages
```dart
  CachedNetworkImage(this.url,
      {this.scale = 1.0,
      this.headers,
      this.cache: false,
      this.retries = 3,
      this.timeLimit,
      this.timeRetry = const Duration(milliseconds: 100),
      this.clearFailedCache: false})
      : assert(url != null),
        assert(scale != null);
```

```dart
/// Clear the disk cache directory then return if it succeed.
///  <param name="duration">timespan to compute whether file has expired or not</param>
Future<bool> clearExtendedTextDiskCachedImages({Duration duration}) async
```

if network image was loaded failed, and you want to reload it next time,
you can set clearFailedCache= true or use clearLoadFailedImageMemoryCache method

```dart
/// clear load failed image in memory so that it will reload
void clearLoadFailedImageMemoryCache({CachedNetworkImage image}) {
  if (image != null) {
    if (_failedImageCache.remove(image)) image.evict();
  } else {
    _failedImageCache.forEach((image) {
      if (_failedImageCache.remove(image)) image.evict();
    });
  }
}
```

[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/custom_image_demo.dart)

## custom background (refer to issue [24335](https://github.com/flutter/flutter/issues/24335)/[24337](https://github.com/flutter/flutter/issues/24337) about background)

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/background.png)


```dart
 BackgroundTextSpan(
                      text: "错误演示 12345",
                      background: Paint()..color = Colors.blue,
                    ),
```

and you can also to cilp your background with clipBorderRadius or paintBackground

```dart
clipBorderRadius: BorderRadius.all(Radius.circular(3.0)),
paintBackground: (BackgroundTextSpan backgroundTextSpan,
                          Canvas canvas,
                          Offset offset,
                          TextPainter painter,
                          Rect rect,
                          {Offset endOffset}) {}
```

[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/background_text_demo.dart)

## custom overflow (refer to issue [26748](https://github.com/flutter/flutter/issues/26748))

![](https://github.com/fluttercandies/Flutter_Candies/blob/master/gif/extended_text/overflow.jpg)

you can define your custom over flow textspan with overFlowTextSpan.

``` dart
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
                    ], background: Theme.of(context).canvasColor),
                    ...
                  )
```

[more detail](https://github.com/fluttercandies/extended_text/blob/master/example/lib/custom_text_overflow_demo.dart)
