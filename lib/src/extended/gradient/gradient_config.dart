import 'package:flutter/material.dart';

/// Enum to represent different modes of gradient applications on text.
enum GradientRenderMode {
  fullText, // Apply gradient to the entire text.
  line, // Apply gradient to each line of the text.
  selection, // Apply gradient to specific text selections.
  word, // Apply gradient to specific text word.
  character, // Apply gradient to specific text character.
}

/// The span will always ignore the gradient
mixin IgnoreGradientSpan on InlineSpan {}

/// Configuration for applying gradients to text.
class GradientConfig {
  /// Creates an instance of [GradientConfig].
  ///
  /// [gradient] is the gradient that will be applied to the text.
  ///
  /// [ignoreWidgetSpan] determines whether `WidgetSpan` elements should be
  /// included in the gradient application. By default, widget spans are ignored.
  ///
  /// [renderMode] specifies how the gradient should be applied to the text. The default
  /// is [GradientRenderMode.fullText], meaning the gradient will apply to the entire text.
  ///
  /// [ignoreRegex] is a regular expression used to exclude certain parts of the text
  /// from the gradient effect. For example, it can be used to exclude specific characters
  /// or words (like emojis or special symbols) from the gradient application.
  ///
  /// [beforeDrawGradient] A callback function that is called before the gradient is drawn on the text.

  /// [blendMode] The blend mode to be used when applying the gradient.
  /// default: [BlendMode.srcIn] (i.e., the gradient will be applied to the text).
  /// It's better to use [BlendMode.srcIn] or [BlendMode.srcATop].

  GradientConfig({
    required this.gradient,
    this.ignoreWidgetSpan = true,
    this.renderMode = GradientRenderMode.fullText,
    this.ignoreRegex,
    this.beforeDrawGradient,
    this.blendMode = BlendMode.srcIn,
  });

  ///  The gradient to be applied for [ExtendedText]
  final Gradient gradient;

  ///  Whether the gradient should include `WidgetSpan` elements.
  final bool ignoreWidgetSpan;

  /// The mode of gradient application (e.g., full text, per line, or per selection).
  final GradientRenderMode renderMode;

  /// It is a regular expression used to match
  /// specific parts of the text where the gradient should not be applied.
  /// For example, it can be used to exclude certain characters or words
  /// (like emoji or special symbols) from the gradient effect.
  /// default: [GradientMixin.ignoreRegex]
  final RegExp? ignoreRegex;

  /// A callback function that is called before the gradient is drawn on the text.
  final void Function(
    PaintingContext context,
    TextPainter textPainter,
    Offset offset,
  )? beforeDrawGradient;

  /// The blend mode to be used when applying the gradient.
  /// default: [BlendMode.srcIn] (i.e., the gradient will be applied to the text).
  /// It's better to use [BlendMode.srcIn] or [BlendMode.srcATop].
  final BlendMode blendMode;

  static RegExp ignoreEmojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}]|' // Emoticons
    r'[\u{1F300}-\u{1F5FF}]|' // Miscellaneous Symbols and Pictographs
    r'[\u{1F680}-\u{1F6FF}]|' // Transport and Map Symbols
    r'[\u{1F700}-\u{1F77F}]|' // Alchemical Symbols
    r'[\u{1F780}-\u{1F7FF}]|' // Geometric Shapes Extended
    r'[\u{1F800}-\u{1F8FF}]|' // Supplemental Arrows-C
    r'[\u{1F900}-\u{1F9FF}]|' // Supplemental Symbols and Pictographs
    r'[\u{1FA00}-\u{1FA6F}]|' // Chess Symbols
    r'[\u{1FA70}-\u{1FAFF}]|' // Symbols and Pictographs Extended-A
    r'[\u{2600}-\u{26FF}]|' // Miscellaneous Symbols
    r'[\u{2700}-\u{27BF}]|' // Dingbats
    r'[\u{1F1E6}-\u{1F1FF}]', // Flags (iOS)
    unicode: true,
  );

  /// Creates a copy of this [GradientConfig] with the given values.
  ///
  /// If a parameter is not provided, it retains its current value.
  GradientConfig copyWith({
    Gradient? gradient,
    bool? ignoreWidgetSpan,
    GradientRenderMode? renderMode,
    void Function(
      PaintingContext context,
      TextPainter textPainter,
      Offset offset,
    )? beforeDrawGradient,
    BlendMode? blendMode,
  }) {
    return GradientConfig(
      gradient: gradient ?? this.gradient,
      ignoreWidgetSpan: ignoreWidgetSpan ?? this.ignoreWidgetSpan,
      renderMode: renderMode ?? this.renderMode,
      ignoreRegex: ignoreRegex,
      beforeDrawGradient: beforeDrawGradient ?? this.beforeDrawGradient,
      blendMode: blendMode ?? this.blendMode,
    );
  }

  /// Creates a copy of this [GradientConfig] with the given [ignoreRegex].
  GradientConfig copyWithIgnoreRegex(RegExp? ignoreRegex) {
    return GradientConfig(
      gradient: gradient,
      ignoreWidgetSpan: ignoreWidgetSpan,
      renderMode: renderMode,
      ignoreRegex: ignoreRegex,
      beforeDrawGradient: beforeDrawGradient,
      blendMode: blendMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradientConfig &&
          runtimeType == other.runtimeType &&
          gradient == other.gradient &&
          ignoreWidgetSpan == other.ignoreWidgetSpan &&
          renderMode == other.renderMode &&
          ignoreRegex == other.ignoreRegex &&
          beforeDrawGradient == other.beforeDrawGradient;

  @override
  int get hashCode =>
      gradient.hashCode ^
      ignoreWidgetSpan.hashCode ^
      renderMode.hashCode ^
      ignoreRegex.hashCode ^
      beforeDrawGradient.hashCode;
}
