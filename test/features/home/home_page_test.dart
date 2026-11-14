import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/browse_request_providers.dart';
import 'package:tuneshell/app/providers/listening_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/home/home_page.dart';
import 'package:tuneshell/features/home/home_providers.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/album_card.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_listening_store.dart';
import '../../fakes/fake_settings_store.dart';
import '../../fakes/fake_storage.dart';

const ssd = DiskId('ssd');
var _id = 0;

LibraryTrack lt(
  String title,
  String album,
  int number, {
  DiskId disk = internalDisk,
  String artist = 'Ann',
}) => LibraryTrack(
  id: ++_id,
  disk: disk,
  info: TrackInfo(
    relativePath: 'Music/$title.mp3',
    size: 1,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
    title: title,
    artist: artist,
    albumArtist: artist,
    album: album,
    trackNumber: number,
    duration: const Duration(seconds: 90),
  ),
);

/// @verifies FR-033
/// @verifies UC-014
/// @verifies BR-016
void main() {
  late FakeAudioEngine engine;
  late PlayerController player;
  late FakeListeningStore store;
  late ProviderContainer container;

  // Five albums of two tracks: three tracks and two albums fit the draw.
  final library = [
    for (final album in ['E', 'D', 'C', 'B', 'A'])
      for (var n = 1; n <= 2; n++) lt('$album$n', album, n),
  ];

  Future<void> pump(
    WidgetTester tester, {
    List<LibraryTrack>? tracks,
    Set<DiskId> available = const {internalDisk, ssd},
    Size size = const Size(412, 915),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final all = tracks ?? library;
    engine = FakeAudioEngine();
    player = PlayerController(
      engine: engine,
      opener: FakeTrackSourceOpener(),
      volumes: FakeVolumeEvents(available),
    );
    await player.start();
    addTearDown(player.dispose);
    store = FakeListeningStore();
    container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWithValue(player),
        settingsStoreProvider.overrideWithValue(FakeSettingsStore()),
        listeningStoreProvider.overrideWithValue(store),
        listedTracksProvider.overrideWith((ref) => Stream.value(all)),
        libraryDisksProvider.overrideWith(
          (ref) => Stream.value(const [Disk.internal]),
        ),
        unavailableDiskIdsProvider.overrideWithValue({
          for (final id in {internalDisk, ssd})
            if (!available.contains(id)) id,
        }),
        trackIndexProvider.overrideWithValue({for (final x in all) x.track: x}),
        playerDisksProvider.overrideWithValue(const [Disk.internal]),
        artworkDirectoryProvider.overrideWith((ref) => '/artwork'),
        homeNowProvider.overrideWithValue(() => DateTime(2026, 11, 14)),
        homeRandomProvider.overrideWithValue(Random(5)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: TsTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HomePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> end(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('shows three tracks and two albums', (tester) async {
    await pump(tester);

    expect(find.text('Forgotten tracks'), findsOneWidget);
    expect(find.text('Forgotten albums'), findsOneWidget);
    expect(find.byType(AlbumCard), findsNWidgets(2));
    final draw = container.read(homeDrawProvider)!;
    expect(draw.tracks, hasLength(3));
    for (final track in draw.tracks) {
      expect(
        find.textContaining(track.relativePath.substring(6, 8)),
        findsWidgets,
      );
    }
    await end(tester);
  });

  testWidgets('touching a track plays the whole library from it', (
    tester,
  ) async {
    await pump(tester);
    final chosen = container.read(homeDrawProvider)!.tracks.first;
    final title = library.firstWhere((t) => t.track == chosen).displayTitle;

    await tester.tap(find.text(title).first);
    await tester.pumpAndSettle();

    final state = container.read(playerControllerProvider).state;
    expect(state.queue, hasLength(library.length));
    expect(state.currentTrack, chosen);
    // Ordered by artist, album, then number: albums A to E.
    expect(state.queue.first.relativePath, 'Music/A1.mp3');
    expect(state.queue.last.relativePath, 'Music/E2.mp3');
    expect(container.read(queueOriginProvider), isA<HomeOrigin>());
    expect(engine.state.playing, isTrue);
    await end(tester);
  });

  testWidgets('touching an album asks the Albums tab to open it', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(AlbumCard).first);
    await tester.pump();

    expect(container.read(browseRequestProvider), isNotNull);
    await end(tester);
  });

  testWidgets('"More suggestions" draws again, away from what is shown', (
    tester,
  ) async {
    await pump(tester);
    final before = container.read(homeDrawProvider)!;

    await tester.tap(find.text('More suggestions'));
    await tester.pumpAndSettle();

    final after = container.read(homeDrawProvider)!;
    expect(after.tracks, hasLength(3));
    expect(after.tracks.toSet().intersection(before.tracks.toSet()), isEmpty);
    expect(
      after.albumKeys.toSet().intersection(before.albumKeys.toSet()),
      isEmpty,
    );
    await end(tester);
  });

  testWidgets('an absent disk is neither drawn nor shown', (tester) async {
    final mixed = [
      ...library.take(4),
      lt('Off1', 'Far', 1, disk: ssd),
      lt('Off2', 'Far', 2, disk: ssd),
    ];
    await pump(tester, tracks: mixed, available: {internalDisk});

    expect(find.textContaining('Off'), findsNothing);
    expect(find.text('Far'), findsNothing);
    await end(tester);
  });

  testWidgets('an empty library shows the empty state, without the button', (
    tester,
  ) async {
    await pump(tester, tracks: const []);

    expect(find.text('Nothing to show yet'), findsOneWidget);
    expect(find.text('More suggestions'), findsNothing);
    await end(tester);
  });

  testWidgets('a wide tab puts the tracks and the albums side by side', (
    tester,
  ) async {
    await pump(tester, size: const Size(915, 412));

    final tracks = tester.getTopLeft(find.text('Forgotten tracks'));
    final albums = tester.getTopLeft(find.text('Forgotten albums'));
    expect(albums.dx, greaterThan(tracks.dx));
    expect(albums.dy, tracks.dy);
    await end(tester);
  });
}
