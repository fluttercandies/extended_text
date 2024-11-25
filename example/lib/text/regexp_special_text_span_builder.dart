import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'my_special_text_span_builder.dart';

class MyRegExpSpecialTextSpanBuilder extends RegExpSpecialTextSpanBuilder {
  @override
  List<RegExpSpecialText> get regExps => <RegExpSpecialText>[
        RegExpMailText(),
        RegExpDollarText(),
        RegExpAtText(),
        RegExpEmojiText(),
      ];
}

class RegExpDollarText extends RegExpSpecialText {
  @override
  RegExp get regExp => RegExp(r'\$(.+)\$');

  @override
  InlineSpan finishText(int start, Match match,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap}) {
    textStyle = textStyle?.copyWith(color: Colors.orange, fontSize: 16.0);

    final String value = '${match[0]}';

    return SpecialTextSpan(
      text: value.replaceAll('\$', ''),
      actualText: value,
      start: start,
      style: textStyle,
      recognizer: (TapGestureRecognizer()
        ..onTap = () {
          if (onTap != null) {
            onTap(value);
          }
        }),
      mouseCursor: SystemMouseCursors.text,
      onEnter: (PointerEnterEvent event) {
        print(event);
      },
      onExit: (PointerExitEvent event) {
        print(event);
      },
    );
  }
}

class RegExpAtText extends RegExpSpecialText {
  @override
  RegExp get regExp => RegExp('@[^@ ]+');

  @override
  InlineSpan finishText(int start, Match match,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap}) {
    textStyle = textStyle?.copyWith(color: Colors.blue, fontSize: 16.0);

    final String value = '${match[0]}';

    return SpecialTextSpan(
      text: value,
      actualText: value,
      start: start,
      style: textStyle,
      recognizer: (TapGestureRecognizer()
        ..onTap = () {
          if (onTap != null) {
            onTap(value);
          }
        }),
      mouseCursor: SystemMouseCursors.text,
      onEnter: (PointerEnterEvent event) {
        print(event);
      },
      onExit: (PointerExitEvent event) {
        print(event);
      },
    );
  }
}

class RegExpEmojiText extends RegExpSpecialText {
  @override
  RegExp get regExp => RegExp(r'\[[^[]+\]');

  @override
  InlineSpan finishText(
    int start,
    Match match, {
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  }) {
    final String key = match.input.substring(match.start, match.end);

    /// widget span is not working on web
    if (EmojiUitl.instance.emojiMap.containsKey(key)) {
      //fontsize id define image height
      //size = 30.0/26.0 * fontSize
      const double size = 20.0;

      ///fontSize 26 and text height =30.0
      //final double fontSize = 26.0;
      return ImageSpan(
        AssetImage(
          EmojiUitl.instance.emojiMap[key]!,
        ),
        actualText: key,
        imageWidth: size,
        imageHeight: size,
        start: start,
        fit: BoxFit.fill,
        margin: const EdgeInsets.only(left: 2.0, top: 2.0, right: 2.0),
        alignment: PlaceholderAlignment.middle,
      );
    }

    return TextSpan(text: toString(), style: textStyle);
  }
}

class RegExpMailText extends RegExpSpecialText {
  @override
  RegExp get regExp => RegExp(r'mailto:[^ ]+');
  @override
  InlineSpan finishText(int start, Match match,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap}) {
    textStyle = textStyle?.copyWith(color: Colors.lightBlue, fontSize: 16.0);

    final String value = '${match[0]}';

    return ExtendedWidgetSpan(
      child: GestureDetector(
          child: const Icon(
            Icons.email,
            size: 16,
          ),
          onTap: () {
            if (onTap != null) {
              onTap(value);
            }
          }),
      actualText: value,
      start: start,
      style: textStyle,
    );
  }
}
