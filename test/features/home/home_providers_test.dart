import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/listening_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/player_state.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/home/home_providers.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';

import '../../fakes/fake_listening_store.dart';

const ssd = DiskId('ssd');
var _id = 0;

LibraryTrack lt(String title, String album, {DiskId disk = internalDisk}) =>
    LibraryTrack(
      id: ++_id,
      disk: disk,
      info: TrackInfo(
        relativePath: 'Music/$title.mp3',
        size: 1,
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
        title: title,
        artist: 'Ann',
        album: album,
      ),
    );

/// @verifies BR-016
/// @verifies FR-033
void main() {
  late FakeListeningStore store;
  late StreamController<List<LibraryTrack>> library;
  late Set<DiskId> unavailable;

  ProviderContainer start({PlayerState? player}) {
    final container = ProviderContainer(
      overrides: [
        listeningStoreProvider.overrideWithValue(store),
        listedTracksProvider.overrideWith((ref) => library.stream),
        unavailableDiskIdsProvider.overrideWith((ref) => unavailable),
        playerStateProvider.overrideWith(
          (ref) => Stream.value(player ?? const PlayerState()),
        ),
        homeNowProvider.overrideWithValue(() => DateTime(2026, 11, 14)),
        homeRandomProvider.overrideWithValue(Random(3)),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(homeDrawProvider, (_, _) {})
      ..listen(homeContentProvider, (_, _) {});
    return container;
  }

  List<LibraryTrack> albums(int count) => [
    for (var a = 0; a < count; a++)
      for (var n = 1; n <= 2; n++) lt('t$a-$n', 'album$a'),
  ];

  setUp(() {
    store = FakeListeningStore();
    library = StreamController<List<LibraryTrack>>();
    unavailable = {};
  });

  tearDown(() => library.close());

  test('is not ready until the library is read', () async {
    final container = start();
    await pumpEventQueue();

    expect(container.read(homeContentProvider), isNull);
  });

  test('draws once the library is known: three tracks, two albums', () async {
    final container = start();
    library.add(albums(6));
    await pumpEventQueue();

    final content = container.read(homeContentProvider)!;
    expect(content.tracks, hasLength(3));
    expect(content.albums, hasLength(2));
  });

  test('an empty library gives an empty content', () async {
    final container = start();
    library.add(const []);
    await pumpEventQueue();

    expect(container.read(homeContentProvider)!.isEmpty, isTrue);
  });

  test('keeps its draw when the library changes', () async {
    final container = start();
    library.add(albums(6));
    await pumpEventQueue();
    final first = container.read(homeDrawProvider);

    library.add([...albums(6), lt('new', 'brand new')]);
    await pumpEventQueue();

    expect(container.read(homeDrawProvider), same(first));
  });

  test('draws again when the first scan gave nothing', () async {
    final container = start();
    library.add(const []);
    await pumpEventQueue();
    expect(container.read(homeContentProvider)!.isEmpty, isTrue);

    library.add(albums(6));
    await pumpEventQueue();

    expect(container.read(homeContentProvider)!.isEmpty, isFalse);
  });

  test('never draws what was listened to in the last 30 days', () async {
    final all = albums(3);
    await store.recordPlay(all[0].track, DateTime(2026, 11, 10));
    await store.recordPlay(all[2].track, DateTime(2026, 11, 12));
    final container = start();
    library.add(all);
    await pumpEventQueue();

    final content = container.read(homeContentProvider)!;
    expect([for (final a in content.albums) a.title], ['album2']);
  });

  test('never draws an unavailable disk', () async {
    unavailable = {ssd};
    final container = start();
    library.add([
      lt('gone-1', 'gone', disk: ssd),
      lt('gone-2', 'gone', disk: ssd),
      ...albums(1),
    ]);
    await pumpEventQueue();

    final content = container.read(homeContentProvider)!;
    expect([for (final a in content.albums) a.title], ['album0']);
    expect([
      for (final t in content.tracks) t.disk,
    ], everyElement(internalDisk));
  });

  test(
    'an album leaves the content when its disk goes, not the draw',
    () async {
      var gone = false;
      final all = [
        lt('x-1', 'x', disk: ssd),
        lt('x-2', 'x', disk: ssd),
        lt('y-1', 'y'),
        lt('y-2', 'y'),
      ];
      final container = ProviderContainer(
        overrides: [
          listeningStoreProvider.overrideWithValue(store),
          listedTracksProvider.overrideWith((ref) => library.stream),
          unavailableDiskIdsProvider.overrideWith(
            (ref) => gone ? {ssd} : const {},
          ),
          playerStateProvider.overrideWith(
            (ref) => Stream.value(const PlayerState()),
          ),
          homeNowProvider.overrideWithValue(() => DateTime(2026, 11, 14)),
        ],
      );
      addTearDown(container.dispose);
      container
        ..listen(homeDrawProvider, (_, _) {})
        ..listen(homeContentProvider, (_, _) {});
      library.add(all);
      await pumpEventQueue();
      expect(container.read(homeContentProvider)!.albums, hasLength(2));
      final drawn = container.read(homeDrawProvider);

      gone = true;
      container.invalidate(unavailableDiskIdsProvider);
      await pumpEventQueue();

      expect(container.read(homeDrawProvider), same(drawn));
      expect(
        [for (final a in container.read(homeContentProvider)!.albums) a.title],
        ['y'],
      );
    },
  );

  test('a session restored after the draw takes its track out of it', () async {
    final all = albums(6);
    final player = StreamController<PlayerState>();
    addTearDown(player.close);
    final container = ProviderContainer(
      overrides: [
        listeningStoreProvider.overrideWithValue(store),
        listedTracksProvider.overrideWith((ref) => library.stream),
        unavailableDiskIdsProvider.overrideWith((ref) => unavailable),
        playerStateProvider.overrideWith((ref) => player.stream),
        homeNowProvider.overrideWithValue(() => DateTime(2026, 11, 14)),
        homeRandomProvider.overrideWithValue(Random(3)),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(homeDrawProvider, (_, _) {})
      ..listen(playerStateProvider, (_, _) {});
    player.add(const PlayerState());
    library.add(all);
    await pumpEventQueue();
    // The restored track is one that was drawn.
    final drawn = container.read(homeDrawProvider)!.tracks.first;

    player.add(PlayerState(queue: [drawn], currentIndex: 0));
    await pumpEventQueue();

    expect(container.read(homeDrawProvider)!.tracks, isNot(contains(drawn)));
  });

  test('never proposes the current track', () async {
    final all = albums(6);
    final container = start(
      player: PlayerState(queue: [all[0].track], currentIndex: 0),
    );
    library.add(all);
    await pumpEventQueue();

    final content = container.read(homeContentProvider)!;
    expect(content.tracks, isNot(contains(all[0])));
    expect([
      for (final a in content.albums) a.title,
    ], isNot(contains('album0')));
  });

  test('"more suggestions" draws other tracks and albums', () async {
    final container = start();
    library.add(albums(10));
    await pumpEventQueue();
    final first = container.read(homeDrawProvider)!;

    await container.read(homeDrawProvider.notifier).reshuffle();

    final second = container.read(homeDrawProvider)!;
    expect(
      second.albumKeys.toSet().intersection(first.albumKeys.toSet()),
      isEmpty,
    );
    expect(second.tracks.toSet().intersection(first.tracks.toSet()), isEmpty);
  });

  test('a history that cannot be read does not stop the draw', () async {
    store.failure = Exception('locked');
    final container = start();
    library.add(albums(6));
    await pumpEventQueue();

    expect(container.read(homeContentProvider)!.albums, hasLength(2));
  });
}
