import 'package:tuneshell/ui/widgets/alphabet_index.dart';

/// The text an album key is made of: case, accents and every kind of space,
/// apostrophe, quote, dash and ellipsis are ignored, and so are the invisible
/// characters that tag editors leave in titles. The search (BR-011) and the
/// letters of the index (FR-013) keep their own, narrower folding.
///
/// @implements BR-017
String albumKeyText(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    if (_ignored(rune)) continue;
    final char = String.fromCharCode(rune);
    out.write(_replaced[char] ?? (_isSpace(rune) ? ' ' : char));
  }
  return sortKey(out.toString().replaceAll(_spaces, ' ').trim());
}

final _spaces = RegExp(' {2,}');

/// Combining accents and invisible format characters.
bool _ignored(int rune) =>
    (rune >= 0x0300 && rune <= 0x036f) ||
    (rune >= 0x200b && rune <= 0x200f) ||
    (rune >= 0x202a && rune <= 0x202e) ||
    (rune >= 0x2060 && rune <= 0x2064) ||
    (rune >= 0x2066 && rune <= 0x2069) ||
    rune == 0x00ad ||
    rune == 0xfeff;

bool _isSpace(int rune) =>
    rune == 0x20 ||
    (rune >= 0x09 && rune <= 0x0d) ||
    rune == 0x85 ||
    rune == 0xa0 ||
    rune == 0x1680 ||
    (rune >= 0x2000 && rune <= 0x200a) ||
    rune == 0x2028 ||
    rune == 0x2029 ||
    rune == 0x202f ||
    rune == 0x205f ||
    rune == 0x3000;

const _replaced = {
  '’': "'",
  '‘': "'",
  '‛': "'",
  'ʼ': "'",
  '′': "'",
  '`': "'",
  '´': "'",
  '“': '"',
  '”': '"',
  '„': '"',
  '‟': '"',
  '«': '"',
  '»': '"',
  '‐': '-',
  '‑': '-',
  '‒': '-',
  '–': '-',
  '—': '-',
  '―': '-',
  '−': '-',
  '…': '...',
  'œ': 'oe',
  'Œ': 'oe',
  'æ': 'ae',
  'Æ': 'ae',
  'ß': 'ss',
  'ø': 'o',
  'Ø': 'o',
  'ł': 'l',
  'Ł': 'l',
  'đ': 'd',
  'Đ': 'd',
};
