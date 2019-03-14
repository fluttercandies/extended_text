import 'package:flutter/material.dart';

///[imageSpanTransparentPlaceholder] width is zero,
///so that we can define letterSpacing as Image Span width
const String imageSpanTransparentPlaceholder = "\u200B";

///transparentPlaceholder is transparent text
//fontsize id define image height
//size = 30.0/26.0 * fontSize
///final double size = 30.0;
///fontSize 26 and text height =30.0
//final double fontSize = 26.0;

double dpToFontSize(double dp) {
  return dp / 30.0 * 26.0;
}

class ImageSpan extends TextSpan {
  ///image provider
  final ImageProvider image;

  final EdgeInsets margin;

  final double imageWidth;

  final double imageHeight;

  ///width include margin
  final double width;

  ///height include margin
  final double height;

  ///you can paint your placeholder or clip
  ///any thing you want
  final BeforePaintImage beforePaintImage;

  ///you can paint border,shadow etc
  final AfterPaintImage afterPaintImage;

  final BoxFit fit;

  ImageListener _listener;

  ImageSpan(this.image,
      {@required this.imageWidth,
      @required this.imageHeight,
      this.margin,
      this.beforePaintImage,
      this.afterPaintImage,
      this.fit: BoxFit.scaleDown})
      : assert(image != null),
        assert(imageWidth != null),
        assert(imageHeight != null),
        assert(fit != null),
        width = imageWidth + (margin == null ? 0 : margin.horizontal),
        height = imageHeight + (margin == null ? 0 : margin.vertical),
        super(
            text: imageSpanTransparentPlaceholder,
            children: null,
            style: TextStyle(
              color: Colors.transparent,
              height: 1,
              letterSpacing:
                  imageWidth + (margin == null ? 0 : margin.horizontal),
              fontSize: dpToFontSize(
                  imageHeight + (margin == null ? 0 : margin.vertical)),
            ));

  ImageStream _imageStream;
  ImageInfo _imageInfo;
  ImageInfo get imageInfo => _imageInfo;

  bool _isListeningToStream = false;
  ImageConfiguration _imageConfiguration;

//  void didUpdateWidget(Image oldWidget) {
//    super.didUpdateWidget(oldWidget);
//    if (widget.image != oldWidget.image)
//      _resolveImage();
//  }

  void resolveImage({BuildContext context, ImageListener listener}) {
    if (context != null)
      _imageConfiguration = createLocalImageConfiguration(context,
          size: (imageWidth != null && imageHeight != null)
              ? Size(imageWidth, imageHeight)
              : null);
    assert(_imageConfiguration != null);
    if (listener != null) _listener = listener;
    final ImageStream newStream = image.resolve(_imageConfiguration);
    assert(newStream != null);
    _updateSourceStream(newStream);
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    //setState(() {
    _imageInfo = imageInfo;
    _listener?.call(imageInfo, synchronousCall);
    //});
  }

  // Update _imageStream to newStream, and moves the stream listener
  // registration from the old stream to the new stream (if a listener was
  // registered).
  void _updateSourceStream(ImageStream newStream) {
    if (_imageStream?.key == newStream?.key) return;

    _stopListeningToStream();
    //if (_isListeningToStream) _imageStream.removeListener(_handleImageChanged);

    _imageStream = newStream;
    //if (_isListeningToStream) _imageStream.addListener(_handleImageChanged);
    _listenToStream();
  }

  void _listenToStream() {
    if (_isListeningToStream) return;
    _imageStream.addListener(_handleImageChanged);
    _isListeningToStream = true;
  }

  void _stopListeningToStream() {
    if (!_isListeningToStream) return;
    _imageStream.removeListener(_handleImageChanged);
    _isListeningToStream = false;
  }

  void dispose() {
    assert(_imageStream != null);
    _stopListeningToStream();
    //super.dispose();
  }

  bool paint(Canvas canvas, Offset offset) {
    Offset imageOffset = offset;
    if (margin != null) {
      imageOffset = imageOffset + Offset(margin.left, margin.top);
    }
    final Rect imageRect = imageOffset & Size(imageWidth, imageHeight);

    bool handle = beforePaintImage?.call(canvas, imageRect, this) ?? false;
    if (handle) return true;

    if (_imageInfo?.image == null) return false;

    paintImage(
        canvas: canvas,
        rect: imageRect,
        image: _imageInfo?.image,
        fit: fit,
        alignment: Alignment.center);

    afterPaintImage?.call(canvas, imageRect, this);
    return true;
  }
}

///[rect] rect is not margin
///if you have handle placeholder or paint image(clip) you can return true,  it will not paint original image,
///you will have the channce to draw your placeholder before paint image
typedef BeforePaintImage = bool Function(
    Canvas canvas, Rect rect, ImageSpan imageSpan);

///[rect] rect is not include margin
///you can paint border,shadow etc at this moment
typedef AfterPaintImage = void Function(
    Canvas canvas, Rect rect, ImageSpan imageSpan);
