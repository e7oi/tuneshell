import 'package:flutter/foundation.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/ui/widgets/alphabet_index.dart';

final _spaces = RegExp(r'\s+');

/// What the user typed, as folded words (BR-011, rules 3 and 4).
///
/// @implements BR-011
@immutable
final class SearchQuery {
  /// Folds and splits [text]; blank text gives an empty query.
  factory of(String text) => SearchQuery._([
    for (final word in text.trim().split(_spaces))
      if (word.isNotEmpty) foldText(word),
  ]);

  const new _(this.terms);

  final List<String> terms;

  /// An empty query filters nothing.
  bool get isEmpty => terms.isEmpty;
}

/// Lines to search, with the text of each folded once: the search runs at
/// each keystroke, the texts change only when the library does (ADR-018).
///
/// @implements BR-011
class SearchIndex<T> {
  /// [textsOf] gives the fields of a line that count; absent ones are left
  /// out (BR-011, rules 1 and 2).
  new(this._items, Iterable<String?> Function(T item) textsOf)
    : _haystacks = [
        for (final item in _items)
          foldText(
            [
              for (final text in textsOf(item))
                if (text != null && text.trim().isNotEmpty) text,
            ].join(' '),
          ),
      ];

  final List<T> _items;
  final List<String> _haystacks;

  /// The lines where every word of [query] is found, in the order of the
  /// list (BR-011, rules 4 and 5); the list itself for an empty query.
  List<T> filter(SearchQuery query) {
    if (query.isEmpty) return _items;
    return [
      for (var i = 0; i < _items.length; i++)
        if (query.terms.every(_haystacks[i].contains)) _items[i],
    ];
  }
}

/// BR-011, rule 1: the title (the file name without one), the artist, the
/// album artist and the album.
Iterable<String?> trackTexts(LibraryTrack track) => [
  track.displayTitle,
  track.info.artist,
  track.info.albumArtist,
  track.info.album,
];

/// BR-011, rule 1: the title and the artist, empty when unknown (rule 2).
Iterable<String?> albumTexts(AlbumGroup album) => [album.title, album.artist];

/// BR-011, rule 1: the name, empty when unknown (rule 2).
Iterable<String?> artistTexts(ArtistGroup artist) => [artist.name];
