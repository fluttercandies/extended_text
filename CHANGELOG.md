## [0.3.6]

* import extended_text_library

## [0.3.4]

* fix issue that tap exception throw when use OverFlowTextSpan

## [0.3.1]

* add clearFailedCache parameter for CachedNetworkImage
  add clearLoadFailedImageMemoryCache method
  both them are used to clear image load failed memory cache, so that image will be reloaded

## [0.2.9]

* update path_provider version from 0.4.1 to 0.5.0+1

## [0.2.8]

* change SpecialTextGestureTapCallback input from string to dynamic
 
## [0.2.7]

* change BeforePaintImage function to BeforePaintTextImage 
  change AfterPaintImage function to AfterPaintTextImage 

## [0.2.5]

* fix issue that BackgroundTextSpan has error clip.

## [0.2.4]

* add TextPainter wholeTextPainter for BackgroundTextSpan's paintBackground call back,so that you can get info for
whole text painter. 

## [0.2.2]

* fix issue that find TextPosition near overflow is not accurate.

## [0.2.1]

* use ExtendedTextOverflow to replace TextOverflow(new flutter sdk TextOverflow has new value TextOverflow.visible)

## [0.1.8]

* suport inline image, custom background ,custom over flow.
