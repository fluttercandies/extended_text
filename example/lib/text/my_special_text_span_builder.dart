import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AtText extends SpecialText {
  AtText(TextStyle? textStyle, SpecialTextGestureTapCallback? onTap,
      {required this.start})
      : super(flag, ' ', textStyle, onTap: onTap);
  static const String flag = '@';
  final int start;

  @override
  InlineSpan finishText() {
    final TextStyle? textStyle = (this.textStyle ?? const TextStyle())
        .copyWith(color: Colors.blue, fontSize: 16.0);

    final String atText = toString();

    return SpecialTextSpan(
      text: atText,
      actualText: atText,
      start: start,
      style: textStyle,
      recognizer: (TapGestureRecognizer()
        ..onTap = () {
          if (onTap != null) {
            onTap!(atText);
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

List<String> atList = <String>[
  '@Nevermore ',
  '@Dota2 ',
  '@Biglao ',
  '@艾莉亚·史塔克 ',
  '@丹妮莉丝 ',
  '@HandPulledNoodles ',
  '@Zmtzawqlp ',
  '@FaDeKongJian ',
  '@CaiJingLongDaLao ',
];

class DollarText extends SpecialText {
  DollarText(TextStyle? textStyle, SpecialTextGestureTapCallback? onTap,
      {this.start})
      : super(flag, flag, textStyle, onTap: onTap);
  static const String flag = '\$';
  final int? start;
  @override
  InlineSpan finishText() {
    final String text = getContent();

    return _SpecialTextSpan(
        text: text,
        actualText: toString(),
        start: start!,
        deleteAll: false,
        style: (textStyle ?? const TextStyle())
            .copyWith(color: Colors.orange, fontSize: 16),
        mouseCursor: SystemMouseCursors.text,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (onTap != null) {
              onTap!(toString());
            }
          });
  }
}

class _SpecialTextSpan extends SpecialTextSpan with IgnoreGradientSpan {
  _SpecialTextSpan({
    super.style,
    required super.text,
    super.actualText,
    super.start = 0,
    super.deleteAll = true,
    super.recognizer,
    super.children,
    super.semanticsLabel,
    super.mouseCursor,
    super.onEnter,
    super.onExit,
  });

  @override
  String getSelectedContent(String showText) {
    return '${DollarText.flag}$showText${DollarText.flag}';
  }
}

List<String> dollarList = <String>[
  '\$Dota2\$',
  '\$Dota2 Ti9\$',
  '\$CN dota best dota\$',
  '\$Flutter\$',
  '\$CN dev best dev\$',
  '\$UWP\$',
  '\$Nevermore\$',
  '\$FlutterCandies\$',
  '\$ExtendedImage\$',
  '\$ExtendedText\$',
];

class EmojiText extends SpecialText {
  EmojiText(TextStyle? textStyle, {this.start})
      : super(EmojiText.flag, ']', textStyle);
  static const String flag = '[';
  final int? start;
  @override
  InlineSpan finishText() {
    final String key = toString();

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
        start: start!,
        fit: BoxFit.fill,
        margin: const EdgeInsets.only(left: 2.0, top: 2.0, right: 2.0),
        alignment: PlaceholderAlignment.middle,
      );
    }

    return TextSpan(text: toString(), style: textStyle);
  }
}

class EmojiUitl {
  EmojiUitl._() {
    _emojiMap['[love]'] = '$_emojiFilePath/love.png';
    _emojiMap['[sun_glasses]'] = '$_emojiFilePath/sun_glasses.png';
  }

  final Map<String, String> _emojiMap = <String, String>{};

  Map<String, String> get emojiMap => _emojiMap;

  final String _emojiFilePath = 'assets';

  static EmojiUitl? _instance;
  static EmojiUitl get instance => _instance ??= EmojiUitl._();
}

class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  MySpecialTextSpanBuilder();

  @override
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle,
      SpecialTextGestureTapCallback? onTap,
      int? index}) {
    if (flag == '') {
      return null;
    }

    // index is end index of start flag, so text start index should be index-(flag.length-1)
    if (isStart(flag, AtText.flag)) {
      return AtText(
        textStyle,
        onTap,
        start: index! - (AtText.flag.length - 1),
      );
    } else if (isStart(flag, EmojiText.flag)) {
      return EmojiText(textStyle, start: index! - (EmojiText.flag.length - 1));
    } else if (isStart(flag, DollarText.flag)) {
      return DollarText(textStyle, onTap,
          start: index! - (DollarText.flag.length - 1));
    }
    return null;
  }
}
