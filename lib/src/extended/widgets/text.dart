import 'dart:math';
import 'dart:ui' as ui;
import 'package:extended_text/src/extended/gradient/gradient_config.dart';
import 'package:extended_text/src/extended/rendering/paragraph.dart';
import 'package:extended_text/src/extended/widgets/rich_text.dart';
import 'package:extended_text/src/extended/widgets/text_overflow_widget.dart';
import 'package:extended_text_library/extended_text_library.dart';
import 'package:flutter/foundation.dart';
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
    this.gradientConfig,
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
    this.gradientConfig,
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

  /// Configuration for applying gradients to text.
  ///
  /// [gradient] is the gradient that will be applied to the text.
  ///
  /// [ignoreWidgetSpan] determines whether `WidgetSpan` elements should be
  /// included in the gradient application. By default, widget spans are ignored.
  ///
  /// [mode] specifies how the gradient should be applied to the text. The default
  /// is [GradientRenderMode.fullText], meaning the gradient will apply to the entire text.
  ///
  /// [ignoreRegex] is a regular expression used to exclude certain parts of the text
  /// from the gradient effect. For example, it can be used to exclude specific characters
  /// or words (like emojis or special symbols) from the gradient application.
  final GradientConfig? gradientConfig;

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

    late Widget result;
    if (registrar != null) {
      result = MouseRegion(
        cursor: DefaultSelectionStyle.of(context).mouseCursor ??
            SystemMouseCursors.text,
        child: ExtendedSelectableTextContainer(
          textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
          textDirection:
              textDirection, // RichText uses Directionality.of to obtain a default if this is null.
          locale:
              locale, // RichText uses Localizations.localeOf to obtain a default if this is null
          softWrap: softWrap ?? defaultTextStyle.softWrap,
          overflow: overflow ??
              effectiveTextStyle?.overflow ??
              defaultTextStyle.overflow,
          textScaler: textScaler ?? MediaQuery.textScalerOf(context),
          maxLines: maxLines ?? defaultTextStyle.maxLines,
          strutStyle: strutStyle,
          textWidthBasis: textWidthBasis ?? defaultTextStyle.textWidthBasis,
          textHeightBehavior: textHeightBehavior ??
              defaultTextStyle.textHeightBehavior ??
              DefaultTextHeightBehavior.maybeOf(context),
          selectionColor: selectionColor ??
              DefaultSelectionStyle.of(context).selectionColor ??
              DefaultSelectionStyle.defaultColor,
          // zmtzawqlp
          text: _buildTextSpan(effectiveTextStyle),
          // zmtzawqlp
          overflowWidget: overflowWidget,
          // zmtzawqlp
          canSelectPlaceholderSpan: canSelectPlaceholderSpan,

          // zmtzawqlp
          gradientConfig: gradientConfig,
        ),
      );
    } else {
      result = ExtendedRichText(
        textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
        textDirection:
            textDirection, // RichText uses Directionality.of to obtain a default if this is null.
        locale:
            locale, // RichText uses Localizations.localeOf to obtain a default if this is null
        softWrap: softWrap ?? defaultTextStyle.softWrap,
        overflow: overflow ??
            effectiveTextStyle?.overflow ??
            defaultTextStyle.overflow,
        textScaler: textScaler ?? MediaQuery.textScalerOf(context),
        maxLines: maxLines ?? defaultTextStyle.maxLines,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis ?? defaultTextStyle.textWidthBasis,
        textHeightBehavior: textHeightBehavior ??
            defaultTextStyle.textHeightBehavior ??
            DefaultTextHeightBehavior.maybeOf(context),
        selectionColor: selectionColor ??
            DefaultSelectionStyle.of(context).selectionColor ??
            DefaultSelectionStyle.defaultColor,
        // zmtzawqlp
        text: _buildTextSpan(effectiveTextStyle),
        // zmtzawqlp
        overflowWidget: overflowWidget,
        // zmtzawqlp
        canSelectPlaceholderSpan: canSelectPlaceholderSpan,
        // zmtzawqlp
        gradientConfig: gradientConfig,
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

class ExtendedSelectableTextContainer extends _SelectableTextContainer {
  const ExtendedSelectableTextContainer({
    required super.text,
    required super.textAlign,
    super.textDirection,
    required super.softWrap,
    required super.overflow,
    required super.textScaler,
    super.maxLines,
    super.locale,
    super.strutStyle,
    required super.textWidthBasis,
    super.textHeightBehavior,
    required super.selectionColor,
    this.overflowWidget,
    this.canSelectPlaceholderSpan = true,
    this.gradientConfig,
  });
  final TextOverflowWidget? overflowWidget;

  /// if false, it will skip PlaceholderSpan
  final bool canSelectPlaceholderSpan;

  /// Configuration for applying gradients to text.
  ///
  /// [gradient] is the gradient that will be applied to the text.
  /// [ignoreWidgetSpan] determines whether `WidgetSpan` elements should be
  /// included in the gradient application. By default, widget spans are ignored.
  /// [mode] specifies how the gradient should be applied to the text. The default
  /// is [GradientRenderMode.fullText], meaning the gradient will apply to the entire text.
  /// [ignoreRegex] is a regular expression used to exclude certain parts of the text
  /// from the gradient effect. For example, it can be used to exclude specific characters
  /// or words (like emojis or special symbols) from the gradient application.
  final GradientConfig? gradientConfig;
  @override
  State<_SelectableTextContainer> createState() =>
      ExtendedSelectableTextContainerState();
}

class ExtendedSelectableTextContainerState
    extends _SelectableTextContainerState {
  @override
  Widget build(BuildContext context) {
    return SelectionContainer(
      delegate: _selectionDelegate,
      // Use [_RichText] wrapper so the underlying [RenderParagraph] can register
      // its [Selectable]s to the [SelectionContainer] created by this widget.
      child: ExtendedRichTextWidget(
        textKey: _textKey,
        textAlign: widget.textAlign,
        textDirection: widget.textDirection,
        locale: widget.locale,
        softWrap: widget.softWrap,
        overflow: widget.overflow,
        textScaler: widget.textScaler,
        maxLines: widget.maxLines,
        strutStyle: widget.strutStyle,
        textWidthBasis: widget.textWidthBasis,
        textHeightBehavior: widget.textHeightBehavior,
        selectionColor: widget.selectionColor,
        text: widget.text,
        // zmtzawqlp
        overflowWidget:
            (widget as ExtendedSelectableTextContainer).overflowWidget,
        canSelectPlaceholderSpan: (widget as ExtendedSelectableTextContainer)
            .canSelectPlaceholderSpan,
        gradientConfig:
            (widget as ExtendedSelectableTextContainer).gradientConfig,
      ),
    );
  }
}

class ExtendedRichTextWidget extends _RichTextWidget {
  const ExtendedRichTextWidget({
    super.textKey,
    required super.text,
    required super.textAlign,
    super.textDirection,
    required super.softWrap,
    required super.overflow,
    required super.textScaler,
    super.maxLines,
    super.locale,
    super.strutStyle,
    required super.textWidthBasis,
    super.textHeightBehavior,
    required super.selectionColor,
    this.overflowWidget,
    this.canSelectPlaceholderSpan = true,
    this.gradientConfig,
  });
  final TextOverflowWidget? overflowWidget;

  /// if false, it will skip PlaceholderSpan
  final bool canSelectPlaceholderSpan;

  /// Configuration for applying gradients to text.
  ///
  /// [gradient] is the gradient that will be applied to the text.
  /// [ignoreWidgetSpan] determines whether `WidgetSpan` elements should be
  /// included in the gradient application. By default, widget spans are ignored.
  /// [mode] specifies how the gradient should be applied to the text. The default
  /// is [GradientRenderMode.fullText], meaning the gradient will apply to the entire text.
  /// [ignoreRegex] is a regular expression used to exclude certain parts of the text
  /// from the gradient effect. For example, it can be used to exclude specific characters
  /// or words (like emojis or special symbols) from the gradient application.
  final GradientConfig? gradientConfig;
  @override
  Widget build(BuildContext context) {
    final SelectionRegistrar? registrar = SelectionContainer.maybeOf(context);
    return ExtendedRichText(
      key: textKey,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionRegistrar: registrar,
      selectionColor: selectionColor,
      text: text,
      // zmtzawqlp
      overflowWidget: overflowWidget,
      // zmtzawqlp
      canSelectPlaceholderSpan: canSelectPlaceholderSpan,
      // zmtzawqlp
      gradientConfig: gradientConfig,
    );
  }
}
