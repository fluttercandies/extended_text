# 9.0.0

* Migrate to 2.10.0.
* Add shouldShowSelectionHandles and textSelectionGestureDetectorBuilder call back to define the behavior of handles and toolbar.
* Shortcut support for web and desktop.

# 8.0.2

* Fix selectionWidthStyle and selectionHeightStyle are not working.

## 8.0.1

* Support copy on desktop

## 8.0.0

* Migrate to 2.8

## 7.0.1

* Stop hittest if overflowWidget is not hit but overflowRect contains hit pointer.

## 7.0.0

* Add [SpecialTextSpan.mouseCursor], [SpecialTextSpan.onEnter] and [SpecialTextSpan.onExit].
* merge code from 2.2.0

## 6.0.6

* Fix overflow rect is not right if overflowSelection has no selection(may be empty text).

## 6.0.5

* Remove unnecessary assert (assert(textPainter.width >= lastChild!.size.width))
* Initialize _offset with Offset.zero.

## 6.0.4

* Fix find no overflow endless loop. #105
* Store raw text to reduce layout.
  
## 6.0.3

* Fix hitTest is failed when set TextOverflowWidget and selectionEnabled false.
* Fix text is cut off when set TextOverflowPosition.end.
  
## 6.0.2

* Remove unnecessary canvas.save() when clear _overflowRect

## 6.0.1

* Improve performance when find no overflow.

## 6.0.0

* Add [TextOverflowWidget.position] to support show overflow at start, middle or end.
  https://github.com/flutter/flutter/issues/45336
* Add [ExtendedText.joinZeroWidthSpace] to make line breaking and overflow style better.
  https://github.com/flutter/flutter/issues/18761
* Fix strutStyle not work.
* Breaking change: remove [TextOverflowWidget.fixedOffset]
* Breaking change: [SpecialText.getContent] is not include endflag now.(please check if you call getContent and your endflag length is more than 1)

## 5.0.5

* Fix issue that childIndex == children.length assert false in assembleSemanticsNode when use overflowWidget and text is not overflow.

## 5.0.4

* Fix issue that the overflowWidget is not layout #97

## 5.0.3

* Fix null-safety error #96

## 5.0.2

* Fix null-safety error

## 5.0.1

* Add add SemanticsInformation for overflowWidget
* Improve performance for overflowWidget
* Do not paint Selection in the region of overFlowWidget

## 5.0.0

* Support null-safety

## 4.1.0

* Support keyboard copy on web/desktop
* Fix wrong position of caret

## 4.0.1

* Change handleSpecialText to hasSpecialInlineSpanBase(extended_text_library)
* Add hasPlaceholderSpan(extended_text_library)
* Fix wrong offset of WidgetSpan #86

## 4.0.0

* Merge from Flutter v1.20

## 3.0.1

* Fix throw exception when set OverflowWidget and has no visual overflow.

## 3.0.0

* Breaking change: fix typos OverflowWidget.

## 2.0.0

* Support OverflowWidget ExtendedText.
* Breaking change: remove overflowTextSpan.

## 1.0.1

* Fix wrong calculation about selection handles.

## 1.0.0

* Merge code from 1.17.0
* Fix analysis_options

## 0.7.1

* Fix error about TargetPlatform.macOS

## 0.7.0

* Fix issue that Index out of range for overflow WidgetSpan

## 0.6.9

* Fix issue that TextPainter was not layout

## 0.6.8

* extract method for TextSelection

## 0.6.7

* codes base on 1.12.13+hotfix.5
* set limitation of flutter sdk >=1.12.13 <1.12.16

## 0.6.6

* Fix kMinInteractiveSize is missing in high version of flutter
* Fix text overflow about WidgetSpan

## 0.6.4

* Improve codes about selection
* Select all SpecialTextSpan which deleteAll is true when double tap or long tap

## 0.6.3

* Fix issue ImageSpan is not TextSpan(https://github.com/fluttercandies/extended_text/issues/24)

## 0.6.2

* Fix wrong selection offset
* Fix wrong text clip due to overflowspan

## 0.6.1

* Fix issue type 'List<InlineSpan>' is not a subtype of type 'List<TextSpan>'(https://github.com/fluttercandies/extended_text/issues/20)

## 0.6.0

* Improve codes base on v1.7.8
* Support WidgetSpan (ExtendedWidgetSpan)

## 0.5.8

* Breaking change:
  Remove background parameter of OverFlowTextSpan

## 0.5.7

* Issue:
  Fix textEditingValue and textSelectionControls are not update when didUpdateWidget

## 0.5.4

* Feature:
  Support text selection
* Issue:
   Fix issue about rect of overFlowTextSpan

## 0.5.3

* Update extended_text_library

## 0.5.2

* Update path_provider 1.1.0

## 0.5.0

* Update extended_text_library
  Remove caretIn parameter(SpecialTextSpan)
  DeleteAll parameter has the same effect as caretIn parameter(SpecialTextSpan)

## 0.4.9

* Fix wrong background rect of OverFlowTextSpan when over flow area has image span

## 0.4.8

* Fix wrong background rect of OverFlowTextSpan(issue 6)

## 0.4.7

* Disabled informationCollector to keep backwards compatibility for now (ExtendedNetworkImageProvider)

## 0.4.5

* Add GestureRecognizer for ImageSpan
* Add demo to show image in photo view

## 0.4.3

* Handle image span load failed

## 0.4.2

* Update extended_text_library for cache folder is changed

## 0.4.0

* Update extended_text_library for BackgroundTextSpan

## 0.3.9

* Override compareTo method in BackgroundTextSpan and OverFlowTextSpan to
  Fix issue that it was error rendering

## 0.3.8

* Import extended_text_library

## 0.3.4

* Fix issue that tap exception throw when use OverFlowTextSpan

## 0.3.1

* Add clearFailedCache parameter for CachedNetworkImage
  Add clearLoadFailedImageMemoryCache method
  Both them are used to clear image load failed memory cache, so that image will be reloaded

## 0.2.9

* Update path_provider version from 0.4.1 to 0.5.0+1

## 0.2.8

* Change SpecialTextGestureTapCallback input from string to dynamic

## 0.2.7

* Change BeforePaintImage function to BeforePaintTextImage
  Change AfterPaintImage function to AfterPaintTextImage

## 0.2.5

* Fix issue that BackgroundTextSpan has error clip.

## 0.2.4

* Add TextPainter wholeTextPainter for BackgroundTextSpan's paintBackground call back,so that you can get info for
  whole text painter.

## 0.2.2

* Fix issue that find TextPosition near overflow is not accurate.

## 0.2.1

* Use ExtendedTextOverflow to replace TextOverflow(new flutter sdk TextOverflow has new value TextOverflow.visible)

## 0.1.8

* Suport inline image, custom background ,custom over flow.
