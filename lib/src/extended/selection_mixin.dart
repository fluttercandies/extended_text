part of 'package:extended_text/src/extended/rendering/paragraph.dart';

mixin SelectionMixin on TextOverflowMixin {
  bool _canSelectPlaceholderSpan = true;
  bool get canSelectPlaceholderSpan => _canSelectPlaceholderSpan;
  set canSelectPlaceholderSpan(bool value) {
    if (_canSelectPlaceholderSpan != value) {
      _canSelectPlaceholderSpan = value;
    }
  }

  @override
  List<_SelectableFragment> _getSelectableFragments() {
    final List<_SelectableFragment> result = <_SelectableFragment>[];
    int start = 0;
    final String plainText = text.toPlainText(includeSemanticsLabels: false);

    text.visitChildren((InlineSpan span) {
      final int length = ExtendedTextLibraryUtils.getInlineOffset(span);

      if (length == 0) {
        return true;
      } else if (span is PlaceholderSpan && !canSelectPlaceholderSpan) {
        start += length;
        return true;
      } else {
        // overflow widget should not be select
        if (_overflowSelection != null) {
          final List<int> range =
              List<int>.generate(length, (int index) => start + index);
          for (int i = _overflowSelection!.start;
              i < _overflowSelection!.end;
              i++) {
            range.remove(i);
          }

          if (range.isEmpty) {
            start += length;
            return true;
          }
          final List<int> temp = <int>[
            range[0],
          ];

          void _add() {
            result.add(_ExtendedSelectableFragment(
              paragraph: this,
              range:
                  TextRange(start: temp.first, end: temp.first + temp.length),
              fullText: plainText,
              specialInlineSpanBase: span is SpecialInlineSpanBase
                  ? span as SpecialInlineSpanBase
                  : null,
            ));
            temp.clear();
          }

          for (int i = 1; i < range.length; i++) {
            if (temp.last + 1 != range[i]) {
              _add();
            }
            temp.add(range[i]);
          }

          if (temp.isNotEmpty) {
            _add();
          }
        } else {
          result.add(
            _ExtendedSelectableFragment(
              paragraph: this,
              range: TextRange(start: start, end: start + length),
              fullText: plainText,
              specialInlineSpanBase: span is SpecialInlineSpanBase
                  ? span as SpecialInlineSpanBase
                  : null,
            ),
          );
        }
      }
      start += length;

      return true;
    });
    return result;
  }
}

class _ExtendedSelectableFragment extends _SelectableFragment {
  _ExtendedSelectableFragment({
    required super.paragraph,
    required super.fullText,
    required super.range,
    this.specialInlineSpanBase,
  });

  final SpecialInlineSpanBase? specialInlineSpanBase;

  bool get _deleteAll => specialInlineSpanBase?.deleteAll ?? false;

  @override
  SelectedContent? getSelectedContent() {
    if (_textSelectionStart == null || _textSelectionEnd == null) {
      return null;
    }

    if (specialInlineSpanBase != null) {
      final int start =
          math.min(_textSelectionStart!.offset, _textSelectionEnd!.offset);
      final int end =
          math.max(_textSelectionStart!.offset, _textSelectionEnd!.offset);

      if (start == end) {
        return null;
      }
      if (range.start <= start && end <= range.end) {
        return SelectedContent(
            plainText:
                specialInlineSpanBase!.getSelectedContent(fullText.substring(
          start,
          end,
        )));
      } else {
        return null;
      }
    }
    return super.getSelectedContent();
  }

  @override
  void _setSelectionPosition(TextPosition? position, {required bool isEnd}) {
    if (_deleteAll && position != null) {
      // zmtzawqlp
      // move
      if (range.start < position.offset && position.offset < range.end) {
        final double half = (range.end - range.start) / 2;
        if (position.offset < range.start + half) {
          position =
              TextPosition(offset: range.start, affinity: position.affinity);
        } else {
          position =
              TextPosition(offset: range.end, affinity: position.affinity);
        }
      }
    }

    super._setSelectionPosition(position, isEnd: isEnd);
  }
}
