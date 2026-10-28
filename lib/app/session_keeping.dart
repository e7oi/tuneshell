import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/app/session_restore.dart';
import 'package:tuneshell/domain/playback/services/session_keeper.dart';

/// Starts keeping the playback session (BR-012): the stored one is restored
/// in the background, without delaying the first screen, and from then on
/// the controller is followed. The setting is followed too (FR-028.3), and
/// the session is written once more when the application goes to the
/// background.
///
/// @implements BR-012
/// @implements FR-028
SessionKeeper startSessionKeeping(ProviderContainer container) {
  final keeper = container.read(sessionKeeperProvider)..start();
  final enabled = container.read(appSettingsProvider).resumePlayback;
  unawaited(
    restorePlaybackSession(
      controller: container.read(playerControllerProvider),
      store: container.read(playbackSessionStoreProvider),
      keeper: keeper,
      libraryTracks: () async => {
        for (final track
            in await container
                .read(libraryRepositoryProvider)
                .watchTracks()
                .first)
          track.track,
      },
      enabled: enabled,
    ),
  );
  container.listen(
    appSettingsProvider.select((s) => s.resumePlayback),
    (_, on) => unawaited(keeper.setEnabled(enabled: on)),
  );
  // The application may be stopped by Android from there on.
  AppLifecycleListener(onPause: () => unawaited(keeper.flush()));
  return keeper;
}
