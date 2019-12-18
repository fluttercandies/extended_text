
import 'package:example/main.dart';
import 'package:extended_image/extended_image.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:extended_image_library/extended_image_library.dart';
import '../common/pic_swiper.dart';
import 'package:ff_annotation_route/ff_annotation_route.dart';

@FFRoute(
    name: "fluttercandies://CustomImageDemo",
    routeName: "CustomImage",
    description: "custom inline-image in text")
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
          TextSpan(children: <InlineSpan>[
            TextSpan(text: "click image show it in photo view.\n"),
            TextSpan(text: "This is an image with placeholder."),
            WidgetSpan(
              child: GestureDetector(
                  onTap: () {
                    onTap(context, imageTestUrls[0], imageTestUrls);
                  },
                  child: ExtendedImage.network(imageTestUrls[0],
                      width: 80.0,
                      height: 80.0,
                      loadStateChanged: loadStateChanged)),
            ),
            TextSpan(text: "This is an image with border"),
            WidgetSpan(
              child: GestureDetector(
                  onTap: () {
                    onTap(
                        context,
                        imageTestUrls.length > 1
                            ? imageTestUrls[1]
                            : imageTestUrls.first,
                        imageTestUrls);
                  },
                  child: ExtendedImage.network(
                      imageTestUrls.length > 1
                          ? imageTestUrls[1]
                          : imageTestUrls.first,
                      width: 80.0,
                      height: 80.0,
                      border: Border.all(color: Colors.red, width: 1.0),
                      shape: BoxShape.rectangle,
                      loadStateChanged: loadStateChanged)),
            ),
            TextSpan(text: "This is an image with borderRadius"),
            WidgetSpan(
              child: GestureDetector(
                  onTap: () {
                    onTap(
                        context,
                        imageTestUrls.length > 2
                            ? imageTestUrls[2]
                            : imageTestUrls.first,
                        imageTestUrls);
                  },
                  child: ExtendedImage.network(
                      imageTestUrls.length > 2
                          ? imageTestUrls[2]
                          : imageTestUrls.first,
                      width: 80.0,
                      height: 60.0,
                      border: Border.all(color: Colors.red, width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      shape: BoxShape.rectangle,
                      loadStateChanged: loadStateChanged)),
            ),
            TextSpan(text: "This is an circle image with border\n"),
            WidgetSpan(
              child: GestureDetector(
                  onTap: () {
                    onTap(
                        context,
                        imageTestUrls.length > 3
                            ? imageTestUrls[3]
                            : imageTestUrls.first,
                        imageTestUrls);
                  },
                  child: ExtendedImage.network(
                      imageTestUrls.length > 3
                          ? imageTestUrls[3]
                          : imageTestUrls.first,
                      width: 80.0,
                      height: 80.0,
                      border: Border.all(color: Colors.red, width: 1.0),
                      shape: BoxShape.circle,
                      loadStateChanged: loadStateChanged)),
            ),
          ]),
          overflow: TextOverflow.ellipsis,
          //style: TextStyle(background: Paint()..color = Colors.red),
          maxLines: 15,
          selectionEnabled: true,
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

  Widget loadStateChanged(ExtendedImageState state) {
    switch (state.extendedImageLoadState) {
      case LoadState.loading:
        return Container(
          color: Colors.grey,
        );
      case LoadState.completed:
        return null;
      case LoadState.failed:
        state.imageProvider.evict();
        return GestureDetector(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                "assets/failed.jpg",
                fit: BoxFit.fill,
              ),
              Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                child: Text(
                  "load image failed, click to reload",
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
          onTap: () {
            state.reLoadImage();
          },
        );
    }
    return Container();
  }

  void onTap(BuildContext context, String url, List<String> list) {
    Navigator.pushNamed(context, "fluttercandies://picswiper", arguments: {
      "index": list.indexOf(url),
      "pics": list.map<PicSwiperItem>((f) => PicSwiperItem(f)).toList(),
    });
  }
}
