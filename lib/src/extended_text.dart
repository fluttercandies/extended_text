import 'package:extended_text/extended_text.dart';
import 'package:extended_text/src/extended_render_paragraph.dart';
import 'package:extended_text/src/extended_rich_text.dart';
import 'package:extended_text/src/extended_text_utils.dart';
import 'package:extended_text/src/over_flow_text_span.dart';
import 'package:extended_text/src/special_text_span_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ExtendedText extends StatelessWidget {
  /// Creates a text widget.
  ///
  /// If the [style] argument is null, the text will use the style from the
  /// closest enclosing [DefaultTextStyle].
  const ExtendedText(this.data,
      {Key key,
      this.style,
      this.textAlign,
      this.textDirection,
      this.locale,
      this.softWrap,
      this.overflow,
      this.textScaleFactor,
      this.maxLines,
      this.semanticsLabel,
      this.specialTextSpanBuilder,
      this.onSpecialTextTap,
      this.overFlowTextSpan})
      : assert(data != null),
        textSpan = null,
        super(key: key);

  /// Creates a text widget with a [TextSpan].
  const ExtendedText.rich(
    this.textSpan, {
    Key key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.onSpecialTextTap,
    this.overFlowTextSpan,
  })  : assert(textSpan != null),
        data = null,
        specialTextSpanBuilder = null,
        super(key: key);

  /// the custom text over flow TextSpan
  final OverFlowTextSpan overFlowTextSpan;

  /// The text to display.
  ///
  /// This will be null if a [textSpan] is provided instead.
  final String data;

  ///build your ccustom text span
  final SpecialTextSpanBuilder specialTextSpanBuilder;

  ///call back of SpecialText tap
  final SpecialTextGestureTapCallback onSpecialTextTap;

  /// The text to display as a [TextSpan].
  ///
  /// This will be null if [data] is provided instead.
  final TextSpan textSpan;

  /// If non-null, the style to use for this text.
  ///
  /// If the style's "inherit" property is true, the style will be merged with
  /// the closest enclosing [DefaultTextStyle]. Otherwise, the style will
  /// replace the closest enclosing [DefaultTextStyle].
  final TextStyle style;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [data] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient [Directionality], if any.
  final TextDirection textDirection;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale locale;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final ExtendedTextOverflow overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  ///
  /// The value given to the constructor as textScaleFactor. If null, will
  /// use the [MediaQueryData.textScaleFactor] obtained from the ambient
  /// [MediaQuery], or 1.0 if there is no [MediaQuery] in scope.
  final double textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  ///
  /// If this is null, but there is an ambient [DefaultTextStyle] that specifies
  /// an explicit number for its [DefaultTextStyle.maxLines], then the
  /// [DefaultTextStyle] value will take precedence. You can use a [RichText]
  /// widget directly to entirely override the [DefaultTextStyle].
  final int maxLines;

  /// An alternative semantics label for this text.
  ///
  /// If present, the semantics of this widget will contain this value instead
  /// of the actual text.
  ///
  /// This is useful for replacing abbreviations or shorthands with the full
  /// text value:
  ///
  /// ```dart
  /// Text(r'$$', semanticsLabel: 'Double dollars')
  ///
  /// ```
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle effectiveTextStyle = style;
    if (style == null || style.inherit)
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    if (MediaQuery.boldTextOverride(context))
      effectiveTextStyle = effectiveTextStyle
          .merge(const TextStyle(fontWeight: FontWeight.bold));

    TextSpan innerTextSpan = specialTextSpanBuilder?.build(data,
        textStyle: effectiveTextStyle, onTap: onSpecialTextTap);

    if (innerTextSpan == null)
      innerTextSpan = TextSpan(
        style: effectiveTextStyle,
        text: data,
        children: textSpan != null ? <TextSpan>[textSpan] : null,
      );

    _createImageConfiguration(<TextSpan>[innerTextSpan], context);

    OverFlowTextSpan effectiveOverFlowTextSpan;
    if (overFlowTextSpan != null) {
      effectiveOverFlowTextSpan = OverFlowTextSpan(
        recognizer: overFlowTextSpan.recognizer,
        background:
            overFlowTextSpan.background ?? Theme.of(context).canvasColor,
        text: overFlowTextSpan.text,
        style: overFlowTextSpan.style ?? effectiveTextStyle,
        children: overFlowTextSpan.children,
      );
    }

    ExtendedTextOverflow extendedTextOverflow = overflow;
    if (extendedTextOverflow == null) {
      if (defaultTextStyle.overflow == TextOverflow.ellipsis) {
        extendedTextOverflow = ExtendedTextOverflow.ellipsis;
      } else if (defaultTextStyle.overflow == TextOverflow.clip) {
        extendedTextOverflow = ExtendedTextOverflow.clip;
      } else if (defaultTextStyle.overflow == TextOverflow.fade) {
        extendedTextOverflow = ExtendedTextOverflow.fade;
      }
    }

    Widget result = ExtendedRichText(
      textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
      textDirection:
          textDirection, // RichText uses Directionality.of to obtain a default if this is null.
      locale:
          locale, // RichText uses Localizations.localeOf to obtain a default if this is null
      softWrap: softWrap ?? defaultTextStyle.softWrap,
      overflow: extendedTextOverflow,
      textScaleFactor: textScaleFactor ?? MediaQuery.textScaleFactorOf(context),
      maxLines: maxLines ?? defaultTextStyle.maxLines,
      text: innerTextSpan,
      overFlowTextSpan: effectiveOverFlowTextSpan,
    );
    if (semanticsLabel != null) {
      result = Semantics(
          textDirection: textDirection,
          label: semanticsLabel,
          child: ExcludeSemantics(
            child: result,
          ));
    }
    return result;
  }

  void _createImageConfiguration(
      List<TextSpan> textSpan, BuildContext context) {
    textSpan.forEach((ts) {
      if (ts is ImageSpan) {
        ts.createImageConfiguration(context);
      } else if (ts.children != null) {
        _createImageConfiguration(ts.children, context);
      }
    });
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('data', data, showName: false));
    if (textSpan != null) {
      properties.add(textSpan.toDiagnosticsNode(
          name: 'textSpan', style: DiagnosticsTreeStyle.transition));
    }
    style?.debugFillProperties(properties);
    properties.add(
        EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(FlagProperty('softWrap',
        value: softWrap,
        ifTrue: 'wrapping at box width',
        ifFalse: 'no wrapping except at line break characters',
        showName: true));
    properties.add(EnumProperty<ExtendedTextOverflow>('overflow', overflow,
        defaultValue: null));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: null));
    if (semanticsLabel != null) {
      properties.add(StringProperty('semanticsLabel', semanticsLabel));
    }
  }
}
