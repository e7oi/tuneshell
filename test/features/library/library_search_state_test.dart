import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';
import 'package:tuneshell/features/library/library_search_state.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_library.dart';
import '../../fakes/fake_storage.dart';

void main() {
  late ProviderContainer container;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 60));

  setUp(() async {
    final repository = FakeLibraryRepository();
    await repository.ensureDisk(Disk.internal);
    await repository.applyIndex(internalDisk, [
      info('Music/a.mp3', title: 'Alpha'),
      info('Music/b.mp3', title: 'Beta'),
      info('Music/c.mp3', title: 'Gamma'),
    ]);
    container = ProviderContainer(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(repository),
        audioEngineProvider.overrideWithValue(FakeAudioEngine()),
        trackSourceOpenerProvider.overrideWithValue(FakeTrackSourceOpener()),
        volumeEventsProvider.overrideWithValue(
          FakeVolumeEvents({internalDisk}),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(searchedListModelProvider, (_, _) {}, fireImmediately: true)
      ..listen(searchedAlbumsProvider, (_, _) {}, fireImmediately: true)
      ..listen(searchedArtistsProvider, (_, _) {}, fireImmediately: true);
    await settle();
  });

  SearchText notifier(SearchView view) =>
      container.read(searchTextProvider(view).notifier);

  group('FR-027 one search per view', () {
    /// @verifies FR-027
    test('no search is open at first', () {
      for (final view in SearchView.values) {
        expect(container.read(searchTextProvider(view)), isNull);
      }
      expect(container.read(searchedListModelProvider), isNull);
    });

    /// @verifies FR-027
    test('opening starts with an empty text, closing forgets it', () {
      notifier(SearchView.tracks)
        ..open()
        ..update('alp');
      expect(container.read(searchTextProvider(SearchView.tracks)), 'alp');

      notifier(SearchView.tracks).close();
      expect(container.read(searchTextProvider(SearchView.tracks)), isNull);
    });

    /// @verifies FR-027
    test('the views do not share their text', () {
      notifier(SearchView.tracks)
        ..open()
        ..update('alp');
      notifier(SearchView.albums).open();

      expect(container.read(searchTextProvider(SearchView.albums)), '');
      expect(container.read(searchTextProvider(SearchView.artists)), isNull);
    });

    /// @verifies BR-011
    test('the tracks shown are those that match, in the usual order', () async {
      notifier(SearchView.tracks)
        ..open()
        ..update('a');
      await settle();

      expect(
        container
            .read(searchedListModelProvider)!
            .entries
            .map((e) => e.track.displayTitle),
        ['Alpha', 'Beta', 'Gamma'],
      );

      notifier(SearchView.tracks).update('ALP');
      await settle();

      expect(
        container
            .read(searchedListModelProvider)!
            .entries
            .map((e) => e.track.displayTitle),
        ['Alpha'],
      );
    });

    /// @verifies BR-011
    test('a text of spaces only shows everything', () async {
      notifier(SearchView.tracks)
        ..open()
        ..update('   ');
      await settle();

      expect(container.read(searchedListModelProvider)!.total, 3);
    });

    /// @verifies FR-027
    test('closing the search leaves the full list alone', () async {
      notifier(SearchView.tracks)
        ..open()
        ..update('alp');
      await settle();
      expect(container.read(libraryListModelProvider)!.total, 3);

      notifier(SearchView.tracks).close();
      await settle();

      expect(container.read(searchedListModelProvider), isNull);
    });

    /// @verifies BR-011
    test('albums and artists are filtered by their own fields', () async {
      notifier(SearchView.albums)
        ..open()
        ..update('zzz');
      notifier(SearchView.artists)
        ..open()
        ..update('zzz');
      await settle();

      expect(container.read(searchedAlbumsProvider), isEmpty);
      expect(container.read(searchedArtistsProvider), isEmpty);
    });
  });
}
