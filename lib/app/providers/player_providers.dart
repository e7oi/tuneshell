import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/app/providers/throttle.dart';
import 'package:tuneshell/data/audio/media_kit_audio_engine.dart';
import 'package:tuneshell/data/db/drift_playback_session_store.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/playback/model/playback_notice.dart';
import 'package:tuneshell/domain/playback/model/player_state.dart';
import 'package:tuneshell/domain/playback/ports/audio_engine.dart';
import 'package:tuneshell/domain/playback/ports/playback_session_store.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/domain/playback/services/session_keeper.dart';
import 'package:tuneshell/domain/storage/ports/track_source_opener.dart';
import 'package:tuneshell/domain/storage/ports/volume_events.dart';
import 'package:tuneshell/platform/internal_storage.dart';
import 'package:tuneshell/platform/removable_storage_channel.dart';

final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = MediaKitAudioEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

final trackSourceOpenerProvider = Provider<TrackSourceOpener>((ref) {
  final mediaStore = ref.watch(mediaStoreProvider);
  return RoutingTrackSourceOpener(
    internal: InternalTrackSourceOpener(mediaStore.internalStorageRoot),
    removable: RemovableTrackSourceOpener(ref.watch(removableStorageProvider)),
    internalDisk: internalDisk,
  );
});

final volumeEventsProvider = Provider<VolumeEvents>(
  (ref) =>
      RemovableVolumeEvents(ref.watch(removableStorageProvider), internalDisk),
);

/// The controller owns no engine (ADR-002): this provider disposes the
/// controller, [audioEngineProvider] the engine.
final playerControllerProvider = Provider<PlayerController>((ref) {
  final controller = PlayerController(
    engine: ref.watch(audioEngineProvider),
    opener: ref.watch(trackSourceOpenerProvider),
    volumes: ref.watch(volumeEventsProvider),
  );
  ref.onDispose(controller.dispose);
  // The controller queues every command behind its start.
  unawaited(controller.start());
  return controller;
});

final playerStateProvider = StreamProvider<PlayerState>((ref) async* {
  final controller = ref.watch(playerControllerProvider);
  // Subscribe before reading the current state: a state emitted in between
  // (the available disks arriving) would otherwise be lost for good.
  final updates = StreamController<PlayerState>();
  final subscription = controller.states.listen(updates.add);
  ref.onDispose(() {
    unawaited(subscription.cancel());
    unawaited(updates.close());
  });
  yield controller.state;
  yield* updates.stream;
});

final playbackNoticesProvider = StreamProvider<PlaybackNotice>(
  (ref) => ref.watch(playerControllerProvider).notices,
);

/// The playback position alone, at most four times a second (ADR-015): the
/// parts of the player that do not move are not rebuilt at each tick.
final playerPositionProvider = StreamProvider<Duration>((ref) async* {
  final controller = ref.watch(playerControllerProvider);
  yield controller.state.position;
  yield* throttleLatest(
    controller.states.map((s) => s.position).distinct(),
    const Duration(milliseconds: 250),
  );
});

final playbackSessionStoreProvider = Provider<PlaybackSessionStore>(
  (ref) => DriftPlaybackSessionStore(ref.watch(libraryDatabaseProvider)),
);

/// Keeps the stored session up to date with the controller (BR-012). Started
/// by `startSessionKeeping`; whether it writes follows the setting
/// (FR-028.3).
final sessionKeeperProvider = Provider<SessionKeeper>((ref) {
  final keeper = SessionKeeper(
    controller: ref.watch(playerControllerProvider),
    store: ref.watch(playbackSessionStoreProvider),
    enabled: ref.read(appSettingsProvider).resumePlayback,
    onError: (error) =>
        debugPrint('session: cannot write: ${error.runtimeType}'),
  );
  ref.onDispose(keeper.dispose);
  return keeper;
});
