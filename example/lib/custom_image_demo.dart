import 'package:example/main.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:extended_image_library/extended_image_library.dart';

import 'common/pic_swiper.dart';

class CustomImageDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("custom inline-image in text"),
      ),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: ExtendedText.rich(
          TextSpan(children: <TextSpan>[
            TextSpan(text: "click image show it in photo view.\n"),
            ImageSpan(
                ExtendedNetworkImageProvider(
                  imageTestUrls.first,
                ),
                clearMemoryCacheIfFailed: true, beforePaintImage:
                    (Canvas canvas, Rect rect, ImageSpan imageSpan) {
              bool hasPlaceholder = drawPlaceholder(canvas, rect, imageSpan);
              if (!hasPlaceholder) {
                clearRect(rect, canvas);
              }
              return false;
            }, afterPaintImage:
                    (Canvas canvas, Rect rect, ImageSpan imageSpan) {
              drawLoadFailed(canvas, rect, imageSpan);
            },
                margin: EdgeInsets.only(right: 10.0),
                imageWidth: 80.0,
                imageHeight: 60.0,
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    onTap(context, imageTestUrls.first, imageTestUrls);
                  }),
            TextSpan(text: "This is an image with placeholder.\n"),
            TextSpan(text: "This is an image with border"),
            ImageSpan(
                ExtendedNetworkImageProvider(
                  imageTestUrls.length > 1
                      ? imageTestUrls[1]
                      : imageTestUrls.first,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    onTap(
                        context,
                        imageTestUrls.length > 1
                            ? imageTestUrls[1]
                            : imageTestUrls.first,
                        imageTestUrls);
                  },
                clearMemoryCacheIfFailed: true, beforePaintImage:
                    (Canvas canvas, Rect rect, ImageSpan imageSpan) {
              bool hasPlaceholder = drawPlaceholder(canvas, rect, imageSpan);

              if (!hasPlaceholder) {
                clearRect(rect, canvas);
              }

              return false;
            }, afterPaintImage:
                    (Canvas canvas, Rect rect, ImageSpan imageSpan) {
              drawLoadFailed(canvas, rect, imageSpan);
              Border.all(color: Colors.red, width: 1)
                  .paint(canvas, rect, shape: BoxShape.rectangle);
            },
                fit: BoxFit.fill,
                margin: EdgeInsets.only(left: 10.0, right: 10.0),
                imageWidth: 80.0,
                imageHeight: 60.0),
            TextSpan(text: "This is an image with borderRadius"),
            ImageSpan(
                ExtendedNetworkImageProvider(
                  imageTestUrls.length > 2
                      ? imageTestUrls[2]
                      : imageTestUrls.first,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    onTap(
                        context,
                        imageTestUrls.length > 2
                            ? imageTestUrls[2]
                            : imageTestUrls.first,
                        imageTestUrls);
                  },
                clearMemoryCacheIfFailed: true, beforePaintImage:
                    (Canvas canvas, Rect rect, ImageSpan imageSpan) {
              canvas.save();
              canvas.clipPath(Path()
                ..addRRect(BorderRadius.all(Radius.circular(5.0))
                    .resolve(TextDirection.ltr)
                    .toRRect(rect)));
              bool hasPlaceholder = drawPlaceholder(canvas, rect, imageSpan);

              ///you mush be restore canvas when image is not ready,so that it will not working to other image
              if (hasPlaceholder) {
                canvas.restore();
              } else {
                clearRect(rect, canvas);
              }

              return false;
            }, afterPaintImage:
                    (Canvas canvas, Rect rect, ImageSpan imageSpan) {
              drawLoadFailed(canvas, rect, imageSpan);
              Border.all(color: Colors.red, width: 1).paint(canvas, rect,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(5.0)));
              canvas.restore();
            },
                fit: BoxFit.fill,
                margin: EdgeInsets.only(left: 10.0, right: 10.0),
                imageWidth: 80.0,
                imageHeight: 60.0),
            TextSpan(text: "This is an circle image with border"),
            ImageSpan(
                ExtendedNetworkImageProvider(
                  imageTestUrls.length > 3
                      ? imageTestUrls[3]
                      : imageTestUrls.first,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    onTap(
                        context,
                        imageTestUrls.length > 3
                            ? imageTestUrls[3]
                            : imageTestUrls.first,
                        imageTestUrls);
                  },
                clearMemoryCacheIfFailed: true, beforePaintImage:
                    (Canvas canvas, Rect rect, ImageSpan imageSpan) {
              canvas.save();

              var path = Path()..addOval(rect);

              canvas.clipPath(path);
              bool hasPlaceholder = drawPlaceholder(canvas, rect, imageSpan);

              ///you mush be restore canvas when image is not ready,so that it will not working to other image
              if (hasPlaceholder) {
                canvas.restore();
              } else {
                clearRect(rect, canvas);
              }
              return false;
            }, afterPaintImage:
                    (Canvas canvas, Rect rect, ImageSpan imageSpan) {
              drawLoadFailed(canvas, rect, imageSpan);
              Border.all(color: Colors.orange, width: 1)
                  .paint(canvas, rect, shape: BoxShape.circle);
              canvas.restore();
            },
                fit: BoxFit.fill,
                margin: EdgeInsets.only(left: 10.0),
                imageWidth: 60.0,
                imageHeight: 60.0),
          ]),
          overflow: ExtendedTextOverflow.ellipsis,
          //style: TextStyle(background: Paint()..color = Colors.red),
          maxLines: 10,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ///clear memory
          clearMemoryImageCache();

          ///clear local cahced
          clearDiskCachedImages().then((bool done) {
//            showToast(done ? "clear succeed" : "clear failed",
//                position: ToastPosition(align: Alignment.center));
            print(done);
          });
        },
        child: Text(
          "clear cache",
          textAlign: TextAlign.center,
          style: TextStyle(
            inherit: false,
          ),
        ),
      ),
    );
  }

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

  bool drawLoadFailed(Canvas canvas, Rect rect, ImageSpan imageSpan) {
    bool loadFailed = imageSpan.imageSpanResolver.loadFailed;

    if (loadFailed) {
      //canvas.drawRect(rect, Paint()..color = Colors.grey);
      var textPainter = TextPainter(
          text: TextSpan(
              text: "failed",
              style: TextStyle(fontSize: 10.0, color: Colors.red)),
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
    return loadFailed;
  }

  void onTap(BuildContext context, String url, List<String> list) {
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return PicSwiper(
        list.indexOf(url),
        list.map<PicSwiperItem>((f) => PicSwiperItem(f)).toList(),
      );
    }));
  }
}
