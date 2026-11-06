import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/listening_providers.dart';
import 'package:tuneshell/domain/library/model/track.dart';

import '../fakes/fake_listening_store.dart';

void main() {
  const a = Track(disk: DiskId('internal'), relativePath: 'a.flac');
  const b = Track(disk: DiskId('internal'), relativePath: 'b.flac');
  late FakeListeningStore store;

  ProviderContainer start() {
    final container = ProviderContainer(
      overrides: [listeningStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => store = FakeListeningStore());

  /// @verifies BR-014
  group('favorites', () {
    test('toggle marks and unmarks, and writes behind', () async {
      final container = start()..listen(favoriteTracksProvider, (_, _) {});
      final notifier = container.read(favoriteTracksProvider.notifier);

      await notifier.toggle(a);
      expect(container.read(favoriteTracksProvider), {a});
      expect(await store.favorites(), {a});

      await notifier.toggle(a);
      expect(container.read(favoriteTracksProvider), isEmpty);
      expect(await store.favorites(), isEmpty);
    });

    test('are read from the store at start', () async {
      await store.setFavorite(b, favorite: true);
      final container = start()..listen(favoriteTracksProvider, (_, _) {});
      await pumpEventQueue();

      expect(container.read(favoriteTracksProvider), {b});
    });

    test('a failed write puts the mark back', () async {
      final container = start()..listen(favoriteTracksProvider, (_, _) {});
      await pumpEventQueue();
      store.failure = Exception('disk full');

      await container.read(favoriteTracksProvider.notifier).toggle(a);

      expect(container.read(favoriteTracksProvider), isEmpty);
    });
  });

  /// @verifies BR-014
  group('recent tracks', () {
    test('refresh reads the history, clear empties it', () async {
      await store.recordPlay(a, DateTime.utc(2026));
      await store.recordPlay(b, DateTime.utc(2026, 1, 2));
      final container = start()..listen(recentTracksProvider, (_, _) {});
      await pumpEventQueue();

      expect(container.read(recentTracksProvider), [b, a]);

      await container.read(recentTracksProvider.notifier).clear();

      expect(container.read(recentTracksProvider), isEmpty);
    });
  });
}
