import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/services/rediscovery.dart';

const internal = DiskId('internal');
const ssd = DiskId('3C2B-77A1');

Track t(String name, [DiskId disk = internal]) =>
    Track(disk: disk, relativePath: '$name.flac');

RediscoveryItem item(
  String name, {
  String? album,
  DiskId disk = internal,
  bool available = true,
}) => RediscoveryItem(
  track: t(name, disk),
  albumKey: album,
  available: available,
);

/// @verifies BR-016
void main() {
  final now = DateTime(2026, 11, 14, 12);
  final old = now.subtract(const Duration(days: 40));
  final recent = now.subtract(const Duration(days: 5));
  const rediscovery = Rediscovery();

  RediscoverySelection pick(
    List<RediscoveryItem> items, {
    Map<Track, DateTime> lastPlayed = const {},
    Set<Track> favorites = const {},
    Track? current,
    Set<Track> avoidTracks = const {},
    Set<String> avoidAlbums = const {},
    int seed = 1,
  }) => rediscovery.pick(
    items: items,
    lastPlayed: lastPlayed,
    favorites: favorites,
    now: now,
    random: Random(seed),
    current: current,
    avoidTracks: avoidTracks,
    avoidAlbums: avoidAlbums,
  );

  /// Six albums of two tracks, `a0` to `a5`.
  List<RediscoveryItem> library() => [
    for (var a = 0; a < 6; a++)
      for (var n = 1; n <= 2; n++) item('a$a-$n', album: 'a$a'),
  ];

  group('how many', () {
    test('proposes three tracks and two albums', () {
      final selection = pick(library());

      expect(selection.tracks, hasLength(3));
      expect(selection.albumKeys, hasLength(2));
    });

    test('proposes no duplicate', () {
      final selection = pick(library());

      expect(selection.tracks.toSet(), hasLength(3));
      expect(selection.albumKeys.toSet(), hasLength(2));
    });

    test('proposes what exists in a small library', () {
      final selection = pick([
        item('x-1', album: 'x'),
        item('y-1', album: 'y'),
      ]);

      expect(selection.albumKeys.toSet(), {'x', 'y'});
      expect(selection.tracks, isEmpty); // both tracks belong to drawn albums
    });

    test('proposes nothing from an empty library', () {
      final selection = pick(const []);

      expect(selection.isEmpty, isTrue);
    });

    test('does not propose a track whose album is drawn', () {
      final selection = pick(library());
      final drawnTracks = [
        for (final key in selection.albumKeys) ...[t('$key-1'), t('$key-2')],
      ];

      expect(
        selection.tracks.toSet().intersection(drawnTracks.toSet()),
        isEmpty,
      );
    });

    test('may draw a track that has no album', () {
      final selection = pick([item('single'), item('other')]);

      expect(selection.albumKeys, isEmpty);
      expect(selection.tracks.toSet(), {t('single'), t('other')});
    });
  });

  group('eligibility', () {
    test('skips what was played in the last 30 days', () {
      final items = [item('fresh', album: 'f'), item('stale', album: 's')];

      final selection = pick(
        items,
        lastPlayed: {t('fresh'): recent, t('stale'): old},
      );

      expect(selection.albumKeys, ['s']);
      expect(selection.tracks, isEmpty);
    });

    test('an album with one recently played track is not drawn', () {
      final items = [
        item('a-1', album: 'a'),
        item('a-2', album: 'a'),
        item('b-1', album: 'b'),
      ];

      final selection = pick(items, lastPlayed: {t('a-2'): recent});

      expect(selection.albumKeys, ['b']);
    });

    test('never draws the current track or its album', () {
      final items = library();

      for (var seed = 0; seed < 20; seed++) {
        final selection = pick(items, current: t('a0-1'), seed: seed);

        expect(selection.albumKeys, isNot(contains('a0')));
        expect(selection.tracks, isNot(contains(t('a0-1'))));
        expect(selection.tracks, isNot(contains(t('a0-2'))));
      }
    });

    test('a future listen counts as recent', () {
      final future = now.add(const Duration(days: 2));

      final selection = pick(
        [item('a-1', album: 'a'), item('b-1', album: 'b')],
        lastPlayed: {t('a-1'): future},
      );

      expect(selection.albumKeys, ['b']);
    });

    test('draws nothing at 29 days, and eligible at 31', () {
      final items = [item('a-1', album: 'a')];

      final at29 = pick(
        items,
        lastPlayed: {t('a-1'): now.subtract(const Duration(days: 29))},
      );
      final at31 = pick(
        items,
        lastPlayed: {t('a-1'): now.subtract(const Duration(days: 31))},
      );

      expect(at29.isEmpty, isTrue);
      expect(at31.albumKeys, ['a']);
    });
  });

  group('availability', () {
    test('never draws a track of a missing disk', () {
      final items = [item('gone', disk: ssd, available: false), item('here')];

      for (var seed = 0; seed < 10; seed++) {
        expect(pick(items, seed: seed).tracks, [t('here')]);
      }
    });

    test('never draws an album whose tracks are all on a missing disk', () {
      final items = [
        item('a-1', album: 'a', disk: ssd, available: false),
        item('a-2', album: 'a', disk: ssd, available: false),
        item('b-1', album: 'b'),
      ];

      expect(pick(items).albumKeys, ['b']);
    });

    test('draws an album with at least one available track', () {
      final items = [
        item('a-1', album: 'a', disk: ssd, available: false),
        item('a-2', album: 'a'),
      ];

      expect(pick(items).albumKeys, ['a']);
    });
  });

  group('priority', () {
    test('draws the already played, or favorite, before the never played', () {
      final items = library();
      final lastPlayed = {t('a0-1'): old, t('a1-1'): old};
      final favorites = {t('a2-2')};

      for (var seed = 0; seed < 20; seed++) {
        final selection = pick(
          items,
          lastPlayed: lastPlayed,
          favorites: favorites,
          seed: seed,
        );

        expect(
          selection.albumKeys.toSet().difference({'a0', 'a1', 'a2'}),
          isEmpty,
        );
      }
    });

    test('completes with never played when the first level is short', () {
      final items = library();

      final selection = pick(items, lastPlayed: {t('a0-1'): old});

      expect(selection.albumKeys, contains('a0'));
      expect(selection.albumKeys, hasLength(2));
    });

    test('tracks follow the same levels', () {
      final items = library();
      final favorites = {t('a3-1'), t('a4-2'), t('a5-1')};

      final selection = pick(items, favorites: favorites);

      // The albums drawn are two of 0 to 5, the tracks avoid their albums; the
      // favorites that are still free come first.
      final free = favorites.where(
        (f) =>
            !selection.albumKeys.any((k) => f.relativePath.startsWith('$k-')),
      );
      expect(selection.tracks.take(free.length).toSet(), free.toSet());
    });
  });

  group('drawing again', () {
    test('is reproducible with the same seed', () {
      expect(pick(library(), seed: 7).tracks, pick(library(), seed: 7).tracks);
    });

    test('avoids what was shown while others remain', () {
      final items = library();
      final first = pick(items);

      final second = pick(
        items,
        avoidTracks: first.tracks.toSet(),
        avoidAlbums: first.albumKeys.toSet(),
      );

      expect(
        second.albumKeys.toSet().intersection(first.albumKeys.toSet()),
        isEmpty,
      );
      expect(second.tracks.toSet().intersection(first.tracks.toSet()), isEmpty);
    });

    test('shows the same again when nothing else is eligible', () {
      final items = [item('a-1', album: 'a')];
      final first = pick(items);

      final second = pick(items, avoidAlbums: first.albumKeys.toSet());

      expect(second.albumKeys, ['a']);
    });
  });
}
