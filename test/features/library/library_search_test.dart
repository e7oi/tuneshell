import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/features/library/library_search.dart';
import 'package:tuneshell/ui/widgets/alphabet_index.dart';

int _id = 0;

LibraryTrack track(
  String path, {
  String? title,
  String? artist,
  String? albumArtist,
  String? album,
}) => LibraryTrack(
  id: ++_id,
  disk: internalDisk,
  info: TrackInfo(
    relativePath: path,
    size: 1000,
    modifiedAt: DateTime(2026),
    title: title,
    artist: artist,
    albumArtist: albumArtist,
    album: album,
  ),
);

List<String> titles(List<LibraryTrack> tracks) => [
  for (final t in tracks) t.displayTitle,
];

void main() {
  group('folding', () {
    /// @verifies BR-011
    test('ignores case and accents', () {
      expect(foldText('Écris-moi'), 'ecris-moi');
      expect(foldText('ÉCRIS-MOI'), foldText('écris-moi'));
    });

    /// @verifies BR-011
    test('is what the sort key is made of', () {
      expect(sortKey('Écris'), endsWith(foldText('Écris')));
    });
  });

  group('the query', () {
    /// @verifies BR-011
    test('splits into folded words and ignores extra spaces', () {
      final query = SearchQuery.of('  Écris   MOI ');

      expect(query.terms, ['ecris', 'moi']);
      expect(query.isEmpty, isFalse);
    });

    /// @verifies BR-011
    test('an empty or blank query filters nothing', () {
      expect(SearchQuery.of('').isEmpty, isTrue);
      expect(SearchQuery.of('   ').isEmpty, isTrue);
    });
  });

  group('searching tracks', () {
    final all = [
      track('Music/a.mp3', title: 'Écris-moi', artist: 'Camille'),
      track(
        'Music/b.mp3',
        title: 'Loure',
        artist: 'Hilary Hahn',
        album: 'Plays Bach',
      ),
      track('Music/c.mp3', title: 'Ma Chanson', albumArtist: 'Various'),
      track('Music/d.mp3'),
      track('Music/e.mp3', title: 'Bachelor', artist: 'Someone'),
    ];
    late SearchIndex<LibraryTrack> index;

    setUp(() => index = SearchIndex(all, trackTexts));

    /// @verifies BR-011
    test('finds without regard to case or accents', () {
      expect(titles(index.filter(SearchQuery.of('ECRIS'))), ['Écris-moi']);
      expect(titles(index.filter(SearchQuery.of('écris'))), ['Écris-moi']);
    });

    /// @verifies BR-011
    test('finds a part of a word, not only its beginning', () {
      expect(titles(index.filter(SearchQuery.of('hanson'))), ['Ma Chanson']);
    });

    /// @verifies BR-011
    test('every word must be found, in any order and in any field', () {
      expect(titles(index.filter(SearchQuery.of('bach hahn'))), ['Loure']);
      expect(titles(index.filter(SearchQuery.of('hahn bach'))), ['Loure']);
      expect(index.filter(SearchQuery.of('hahn camille')), isEmpty);
    });

    /// @verifies BR-011
    test('looks at the title, the artist, the album artist and the album', () {
      expect(titles(index.filter(SearchQuery.of('camille'))), ['Écris-moi']);
      expect(titles(index.filter(SearchQuery.of('various'))), ['Ma Chanson']);
      expect(titles(index.filter(SearchQuery.of('plays'))), ['Loure']);
    });

    /// @verifies BR-011
    test('a file without a title is found by its file name', () {
      expect(titles(index.filter(SearchQuery.of('d.mp3'))), ['d.mp3']);
    });

    /// @verifies BR-011
    test('the display text of a missing artist is not searched', () {
      expect(index.filter(SearchQuery.of('inconnu')), isEmpty);
      expect(index.filter(SearchQuery.of('unknown')), isEmpty);
    });

    /// @verifies BR-011
    test('keeps the order of the list', () {
      expect(titles(index.filter(SearchQuery.of('bach'))), [
        'Loure',
        'Bachelor',
      ]);
    });

    /// @verifies BR-011
    test('an empty query gives the whole list back', () {
      expect(index.filter(SearchQuery.of('')), same(all));
      expect(index.filter(SearchQuery.of('  ')), same(all));
    });

    /// @verifies BR-011
    test('nothing matches: nothing is shown', () {
      expect(index.filter(SearchQuery.of('zzz')), isEmpty);
    });

    /// @verifies BR-011
    test('one letter is enough', () {
      expect(titles(index.filter(SearchQuery.of('w'))), isEmpty);
      expect(titles(index.filter(SearchQuery.of('v'))), ['Ma Chanson']);
    });
  });

  group('searching albums and artists', () {
    final groups = LibraryGroups.build(
      tracks: [
        track(
          'Music/1.mp3',
          title: 'One',
          artist: 'Hilary Hahn',
          album: 'Plays Bach',
        ),
        track(
          'Music/2.mp3',
          title: 'Two',
          artist: 'Camille',
          album: 'Le sac des filles',
        ),
        track('Music/3.mp3', title: 'Three'),
      ],
      unavailableDisks: const {},
    );

    /// @verifies BR-011
    test('an album is found by its title or its artist', () {
      final index = SearchIndex(groups.albums, albumTexts);

      expect(
        [for (final a in index.filter(SearchQuery.of('bach'))) a.title],
        ['Plays Bach'],
      );
      expect(
        [for (final a in index.filter(SearchQuery.of('camille'))) a.title],
        ['Le sac des filles'],
      );
    });

    /// @verifies BR-011
    test('the unknown album and artist are not searched', () {
      final index = SearchIndex(groups.albums, albumTexts);

      expect(index.filter(SearchQuery.of('inconnu')), isEmpty);
      expect(index.filter(SearchQuery.of('unknown')), isEmpty);
    });

    /// @verifies BR-011
    test('an artist is found by its name', () {
      final index = SearchIndex(groups.artists, artistTexts);

      expect(
        [for (final a in index.filter(SearchQuery.of('HAHN'))) a.name],
        ['Hilary Hahn'],
      );
      expect(index.filter(SearchQuery.of('inconnu')), isEmpty);
    });
  });
}
