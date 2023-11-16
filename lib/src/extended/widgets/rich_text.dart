import 'dart:ui' as ui;
import 'package:extended_text/src/extended/rendering/paragraph.dart';
import 'package:extended_text/src/extended/widgets/text_overflow_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

part 'package:extended_text/src/official/widgets/rich_text.dart';

class ExtendedRichText extends _RichText {
  ExtendedRichText({
    super.key,
    required super.text,
    super.textAlign = TextAlign.start,
    super.textDirection,
    super.softWrap = true,
    super.overflow = TextOverflow.clip,
    super.textScaler = TextScaler.noScaling,
    super.maxLines,
    super.locale,
    super.strutStyle,
    super.textWidthBasis = TextWidthBasis.parent,
    super.textHeightBehavior,
    super.selectionRegistrar,
    super.selectionColor,
    this.overflowWidget,
    this.canSelectPlaceholderSpan = true,
  }) : super(
          children: _extractChildren(text, overflowWidget, textScaler),
        );

  final TextOverflowWidget? overflowWidget;

  /// if false, it will skip PlaceholderSpan
  final bool canSelectPlaceholderSpan;

  @override
  ExtendedRenderParagraph createRenderObject(BuildContext context) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    return ExtendedRenderParagraph(
      text,
      textAlign: textAlign,
      textDirection: textDirection ?? Directionality.of(context),
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      locale: locale ?? Localizations.maybeLocaleOf(context),
      registrar: selectionRegistrar,
      selectionColor: selectionColor,
      overflowWidget: overflowWidget,
      canSelectPlaceholderSpan: canSelectPlaceholderSpan,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, ExtendedRenderParagraph renderObject) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    renderObject
      ..text = text
      ..textAlign = textAlign
      ..textDirection = textDirection ?? Directionality.of(context)
      ..softWrap = softWrap
      ..overflow = overflow
      ..textScaler = textScaler
      ..maxLines = maxLines
      ..strutStyle = strutStyle
      ..textWidthBasis = textWidthBasis
      ..textHeightBehavior = textHeightBehavior
      ..locale = locale ?? Localizations.maybeLocaleOf(context)
      ..registrar = selectionRegistrar
      ..selectionColor = selectionColor
      ..overflowWidget = overflowWidget
      ..canSelectPlaceholderSpan = canSelectPlaceholderSpan;
  }

  /// Traverses the InlineSpan tree and depth-first collects the list of
  /// child widgets that are created in WidgetSpans.
  // TODO(zmtzawqlp): _extractChildren has replace with WidgetSpan.extractFromInlineSpan
  static List<Widget> _extractChildren(
    InlineSpan span,
    TextOverflowWidget? overflowWidget,
    TextScaler textScaler,
  ) {
    final List<Widget> result = <Widget>[
      ...WidgetSpan.extractFromInlineSpan(span, textScaler)
    ];

    if (overflowWidget != null) {
      result.add(Semantics(
        tagForChildren: PlaceholderSpanIndexSemanticsTag(result.length),
        child: overflowWidget,
      ));
    }
    return result;
  }
}
