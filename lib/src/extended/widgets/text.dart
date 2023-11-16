import 'dart:ui' as ui;
import 'package:extended_text/src/extended/widgets/rich_text.dart';
import 'package:extended_text/src/extended/widgets/text_overflow_widget.dart';
import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

part 'package:extended_text/src/official/widgets/text.dart';

class ExtendedText extends Text {
  /// Creates a text widget.
  ///
  /// If the [style] argument is null, the text will use the style from the
  /// closest enclosing [DefaultTextStyle].
  ///
  /// The [data] parameter must not be null.
  ///
  /// The [overflow] property's behavior is affected by the [softWrap] argument.
  /// If the [softWrap] is true or null, the glyph causing overflow, and those
  /// that follow, will not be rendered. Otherwise, it will be shown with the
  /// given overflow option.
  const ExtendedText(
    super.data, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
    this.joinZeroWidthSpace = false,
    this.onSpecialTextTap,
    this.overflowWidget,
    this.specialTextSpanBuilder,
    this.canSelectPlaceholderSpan = true,
  });

  /// Creates a text widget with a [InlineSpan].
  ///
  /// The following subclasses of [InlineSpan] may be used to build rich text:
  ///
  /// * [TextSpan]s define text and children [InlineSpan]s.
  /// * [WidgetSpan]s define embedded inline widgets.
  ///
  /// The [textSpan] parameter must not be null.
  ///
  /// See [RichText] which provides a lower-level way to draw text.
  const ExtendedText.rich(
    InlineSpan textSpan, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
    this.joinZeroWidthSpace = false,
    this.onSpecialTextTap,
    this.overflowWidget,
    this.specialTextSpanBuilder,
    this.canSelectPlaceholderSpan = true,
  }) : super.rich(textSpan);

  /// maxheight is equal to textPainter.preferredLineHeight
  /// maxWidth is equal to textPainter.width
  final TextOverflowWidget? overflowWidget;

  /// Whether join '\u{200B}' into text
  /// https://github.com/flutter/flutter/issues/18761#issuecomment-812390920
  ///
  /// Characters(text).join('\u{200B}')
  ///
  final bool joinZeroWidthSpace;

  /// build your ccustom text span
  final SpecialTextSpanBuilder? specialTextSpanBuilder;

  /// call back of SpecialText tap
  final SpecialTextGestureTapCallback? onSpecialTextTap;

  /// if false, it will skip PlaceholderSpan
  final bool canSelectPlaceholderSpan;

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle? effectiveTextStyle = style;
    if (style == null || style!.inherit) {
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    }
    if (MediaQuery.boldTextOf(context)) {
      effectiveTextStyle = effectiveTextStyle!
          .merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    final SelectionRegistrar? registrar = SelectionContainer.maybeOf(context);
    Widget result = ExtendedRichText(
      textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
      textDirection:
          textDirection, // RichText uses Directionality.of to obtain a default if this is null.
      locale:
          locale, // RichText uses Localizations.localeOf to obtain a default if this is null
      softWrap: softWrap ?? defaultTextStyle.softWrap,
      overflow:
          overflow ?? effectiveTextStyle?.overflow ?? defaultTextStyle.overflow,
      textScaler: textScaler ?? MediaQuery.textScalerOf(context),
      maxLines: maxLines ?? defaultTextStyle.maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis ?? defaultTextStyle.textWidthBasis,
      textHeightBehavior: textHeightBehavior ??
          defaultTextStyle.textHeightBehavior ??
          DefaultTextHeightBehavior.maybeOf(context),
      selectionRegistrar: registrar,
      selectionColor: selectionColor ??
          DefaultSelectionStyle.of(context).selectionColor ??
          DefaultSelectionStyle.defaultColor,
      // zmtzawqlp
      text: _buildTextSpan(effectiveTextStyle),
      // zmtzawqlp
      overflowWidget: overflowWidget,
      // zmtzawqlp
      canSelectPlaceholderSpan: canSelectPlaceholderSpan,
    );
    if (registrar != null) {
      result = MouseRegion(
        cursor: DefaultSelectionStyle.of(context).mouseCursor ??
            SystemMouseCursors.text,
        child: result,
      );
    }
    if (semanticsLabel != null) {
      result = Semantics(
        textDirection: textDirection,
        label: semanticsLabel,
        child: ExcludeSemantics(
          child: result,
        ),
      );
    }
    return result;
  }

  InlineSpan _buildTextSpan(TextStyle? effectiveTextStyle) {
    InlineSpan? innerTextSpan = specialTextSpanBuilder?.build(
      data!,
      textStyle: effectiveTextStyle,
      onTap: onSpecialTextTap,
    );

    innerTextSpan ??= TextSpan(
      style: effectiveTextStyle,
      text: data,
      children: textSpan != null ? <InlineSpan>[textSpan!] : null,
    );

    if (joinZeroWidthSpace) {
      innerTextSpan = ExtendedTextLibraryUtils.joinChar(
        innerTextSpan,
        Accumulator(),
        ExtendedTextLibraryUtils.zeroWidthSpace,
      );
    }

    return innerTextSpan;
  }
}
