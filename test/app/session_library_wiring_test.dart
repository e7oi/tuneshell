import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/system_playback.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/platform/media_session/player_audio_handler.dart';

import '../fakes/fake_audio_engine.dart';
import '../fakes/fake_library.dart';
import '../fakes/fake_storage.dart';

void main() {
  /// @verifies FR-005
  test('the tags read after the track started reach the session', () async {
    final repository = FakeLibraryRepository();
    final container = ProviderContainer(
      overrides: [libraryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = PlayerController(
      engine: FakeAudioEngine(),
      opener: FakeTrackSourceOpener(),
      volumes: FakeVolumeEvents({internalDisk}),
    );
    await controller.start();
    addTearDown(controller.dispose);
    final handler = PlayerAudioHandler(
      controller,
      describe: (track) => container.read(trackIndexProvider)[track],
    );
    addTearDown(handler.dispose);
    keepSessionInformed(container, handler);
    const track = Track(disk: internalDisk, relativePath: 'Music/a.mp3');
    await controller.setQueue([track]);
    await controller.play();
    await pumpEventQueue();
    expect(handler.mediaItem.value!.title, 'a.mp3');

    await repository.applyIndex(internalDisk, [
      info('Music/a.mp3', title: 'A'),
    ]);
    // The list is handed over at most twice a second (FR-011.11).
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await pumpEventQueue();

    expect(
      handler.mediaItem.value,
      isA<MediaItem>().having((i) => i.title, 'title', 'A'),
    );
  });
}
