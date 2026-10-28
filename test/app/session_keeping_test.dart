import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/app/session_keeping.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/playback_session.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/domain/settings/app_settings.dart';

import '../fakes/fake_audio_engine.dart';
import '../fakes/fake_library.dart';
import '../fakes/fake_playback_session_store.dart';
import '../fakes/fake_settings_store.dart';
import '../fakes/fake_storage.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late FakeLibraryRepository library;
  late FakePlaybackSessionStore store;
  late FakeSettingsStore settings;

  const a = Track(disk: internalDisk, relativePath: 'Music/a.flac');
  const b = Track(disk: internalDisk, relativePath: 'Music/b.flac');

  setUp(() async {
    library = FakeLibraryRepository();
    await library.ensureDisk(Disk.internal);
    await library.applyIndex(internalDisk, [
      info('Music/a.flac'),
      info('Music/b.flac'),
    ]);
    store = FakePlaybackSessionStore(
      const PlaybackSession(
        queue: [a, b],
        currentIndex: 1,
        position: Duration(seconds: 30),
      ),
    );
    settings = FakeSettingsStore();
  });

  Future<ProviderContainer> start() async {
    final container = ProviderContainer(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(library),
        playbackSessionStoreProvider.overrideWithValue(store),
        settingsStoreProvider.overrideWithValue(settings),
        playerControllerProvider.overrideWith((ref) {
          final controller = PlayerController(
            engine: FakeAudioEngine(),
            opener: FakeTrackSourceOpener(),
            volumes: FakeVolumeEvents({internalDisk}),
          );
          ref.onDispose(controller.dispose);
          unawaited(controller.start());
          return controller;
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(appSettingsProvider.notifier).load();
    startSessionKeeping(container);
    await pumpEventQueue();
    return container;
  }

  /// @verifies BR-012
  /// @verifies FR-028
  group('BR-012 session keeping at launch', () {
    test('the stored session is restored in the controller', () async {
      final container = await start();

      final state = container.read(playerControllerProvider).state;
      expect(state.queue, [a, b]);
      expect(state.currentIndex, 1);
      expect(state.position, const Duration(seconds: 30));
      expect(state.playing, isFalse);
    });

    test('rule 12: with the setting off, nothing is restored', () async {
      settings.entries[SettingKey.resumePlayback] = 'false';

      final container = await start();

      expect(container.read(playerControllerProvider).state.queue, isEmpty);
      expect(store.session, isNull);
    });

    test('FR-028.3: turning the setting off forgets the session, turning it '
        'on writes the queue of the moment', () async {
      final container = await start();
      final controller = container.read(playerControllerProvider);
      container
          .read(appSettingsProvider.notifier)
          .setResumePlayback(enabled: false);
      await pumpEventQueue();
      expect(store.session, isNull);

      await controller.skipTo(0);
      container
          .read(appSettingsProvider.notifier)
          .setResumePlayback(enabled: true);
      await pumpEventQueue();

      expect(store.session!.queue, [a, b]);
      expect(store.session!.currentIndex, 0);
    });

    test('a change of the queue is written', () async {
      final container = await start();
      final controller = container.read(playerControllerProvider);

      await controller.enqueue([a]);
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      expect(store.session!.queue, [a, b, a]);
    });

    test('rule 2: going to the background writes the position', () async {
      final container = await start();
      final controller = container.read(playerControllerProvider);
      await controller.seek(const Duration(seconds: 55));
      await controller.play();
      await pumpEventQueue();
      store.calls.clear();

      binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await pumpEventQueue();

      expect(store.calls, contains('progress'));
    });
  });
}
