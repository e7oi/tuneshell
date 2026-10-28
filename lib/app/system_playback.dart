import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/playback/services/interruption_policy.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/platform/audio_session_interruptions.dart';
import 'package:tuneshell/platform/media_session/player_audio_handler.dart';

/// Hands the player controller of [container] to Android: audio focus
/// (BR-005) and the media session with its notification (FR-005). Runs once
/// per process: the Flutter engine outlives the activity, and the process
/// ends with it (MainActivity, ADR-006).
Future<void> startSystemPlayback(ProviderContainer container) async {
  final controller = container.read(playerControllerProvider);
  InterruptionPolicy(
    controller: controller,
    interruptions: await AudioSessionInterruptions.create(),
    pauseOnUnplug: () => container.read(appSettingsProvider).pauseOnUnplug,
  ).start();

  final l10n = lookupAppLocalizations(
    basicLocaleListResolution(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    ),
  );
  // The images are known by their identifier; without the folder, none is
  // shown (FR-005).
  final artworkFolder = await container
      .read(artworkDirectoryProvider.future)
      .then<String?>((folder) => folder, onError: (Object _) => null);
  final handler = await AudioService.init(
    builder: () => PlayerAudioHandler(
      controller,
      describe: (track) => container.read(trackIndexProvider)[track],
      artworkOf: (artwork) => artworkFolder == null
          ? null
          : Uri.file('$artworkFolder/$artwork.jpg'),
    ),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'net.trtl3.tuneshell.playback',
      androidNotificationChannelName: l10n.notificationChannelName,
      androidNotificationChannelDescription:
          l10n.notificationChannelDescription,
      // The stored images can be large: the system shows a small one.
      artDownscaleWidth: 512,
      artDownscaleHeight: 512,
    ),
  );

  keepSessionInformed(container, handler);
}

/// Shows the current track again whenever the library changes: the tags and
/// the artwork are read after the track may already be playing, and nothing
/// else listens to the index, which without this would stay empty.
///
/// @implements FR-005
void keepSessionInformed(
  ProviderContainer container,
  PlayerAudioHandler handler,
) {
  container.listen(trackIndexProvider, (_, _) => handler.refreshItem());
}
