import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/playback/model/playback_session.dart';
import 'package:tuneshell/domain/playback/ports/media_tree.dart';
import 'package:tuneshell/domain/playback/services/library_media_tree.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/platform/media_session/player_audio_handler.dart';

import '../fakes/fake_audio_engine.dart';
import '../fakes/fake_library.dart';
import '../fakes/fake_storage.dart';

void main() {
  late FakeAudioEngine engine;
  late PlayerController controller;
  late PlayerAudioHandler handler;
  late DateTime now;

  final a = LibraryTrack(
    id: 1,
    disk: internalDisk,
    info: TrackInfo(
      relativePath: 'Music/a.flac',
      size: 1000,
      modifiedAt: DateTime(2026),
      title: 'A',
      artist: 'Artist',
      album: 'Album',
      duration: const Duration(minutes: 3),
    ),
  );
  final b = LibraryTrack(id: 2, disk: internalDisk, info: info('Music/b.mp3'));
  final known = {
    for (final t in [a, b]) t.track: t,
  };

  Future<void> settle() => pumpEventQueue();

  /// Past the grace period of a stop.
  Future<void> stopped() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await settle();
  }

  PlaybackState playback() => handler.playbackState.value;

  setUp(() async {
    engine = FakeAudioEngine();
    controller = PlayerController(
      engine: engine,
      opener: FakeTrackSourceOpener(),
      volumes: FakeVolumeEvents({internalDisk}),
    );
    await controller.start();
    now = DateTime(2026, 10, 21, 12);
    handler = PlayerAudioHandler(
      controller,
      describe: (track) => known[track],
      clock: () => now,
      stopGrace: const Duration(milliseconds: 20),
    );
    await controller.setQueue([a.track, b.track]);
  });

  tearDown(() async {
    await handler.dispose();
    await controller.dispose();
  });

  group('FR-005 state shown by the system', () {
    /// @verifies FR-005
    test('shows the current track with its information', () async {
      await controller.play();
      await settle();

      final item = handler.mediaItem.value!;
      expect(item.title, 'A');
      expect(item.artist, 'Artist');
      expect(item.album, 'Album');
      expect(item.duration, const Duration(minutes: 3));
      expect(playback().playing, isTrue);
      expect(playback().processingState, AudioProcessingState.ready);
      expect(playback().queueIndex, 0);
    });

    /// @verifies FR-005
    test('falls back to the file name without a title', () async {
      await controller.next();
      await settle();

      expect(handler.mediaItem.value!.title, 'b.mp3');
    });

    /// @verifies FR-005
    test('offers previous, play or pause, stop, next and seek', () async {
      await controller.play();
      await settle();

      expect(playback().controls, [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.stop,
        MediaControl.skipToNext,
      ]);
      expect(playback().systemActions, contains(MediaAction.seek));

      await controller.pause();
      await settle();
      expect(playback().controls[1], MediaControl.play);
    });

    /// @verifies FR-005
    test('the duration found by the engine replaces the stored one', () async {
      await controller.play();
      await settle();

      engine.emitDuration(const Duration(minutes: 2));
      await settle();

      expect(handler.mediaItem.value!.duration, const Duration(minutes: 2));
    });

    /// @verifies FR-005
    test('a stopped player releases the system controls', () async {
      await controller.play();
      await settle();

      await controller.stop();
      await stopped();

      expect(playback().processingState, AudioProcessingState.idle);
    });

    /// @verifies FR-005
    test('choosing another track keeps the session', () async {
      await handler.dispose();
      handler = PlayerAudioHandler(
        controller,
        describe: (track) => known[track],
        clock: () => now,
        stopGrace: const Duration(hours: 1),
      );
      await controller.play();
      await settle();
      final states = <AudioProcessingState>[];
      handler.playbackState.listen((s) => states.add(s.processingState));

      await controller.setQueue([b.track, a.track]);
      await controller.play();
      await settle();

      expect(states, isNot(contains(AudioProcessingState.idle)));
      expect(handler.mediaItem.value!.title, 'b.mp3');
    });

    /// @verifies FR-005
    test('a seek is shown, regular progress is extrapolated', () async {
      await controller.play();
      await settle();
      final shown = playback();

      now = now.add(const Duration(seconds: 1));
      engine.emitPosition(const Duration(seconds: 1));
      await settle();
      expect(playback(), same(shown));

      engine.emitPosition(const Duration(seconds: 40));
      await settle();
      expect(playback().updatePosition, const Duration(seconds: 40));
    });
  });

  group('FR-005 what the library knows', () {
    final tagged = LibraryTrack(
      id: 3,
      disk: internalDisk,
      info: TrackInfo(
        relativePath: 'Music/c.flac',
        size: 1000,
        modifiedAt: DateTime(2026),
        title: 'C',
        artist: 'Singer',
        album: 'Record',
      ),
      artwork: 'cover1',
    );

    Future<void> playing(
      TrackDescriber describe, {
      ArtworkLocator? artworkOf,
    }) async {
      await handler.dispose();
      handler = PlayerAudioHandler(
        controller,
        describe: describe,
        artworkOf: artworkOf ?? (_) => null,
        clock: () => now,
        stopGrace: const Duration(milliseconds: 20),
      );
      await controller.setQueue([tagged.track]);
      await controller.play();
      await settle();
    }

    /// @verifies FR-005
    test(
      'the tags that arrive after the track replace the file name',
      () async {
        LibraryTrack? library;
        await playing((_) => library);
        expect(handler.mediaItem.value!.title, 'c.flac');
        expect(handler.mediaItem.value!.artist, isNull);

        library = tagged;
        handler.refreshItem();

        expect(handler.mediaItem.value!.title, 'C');
        expect(handler.mediaItem.value!.artist, 'Singer');
        expect(handler.mediaItem.value!.album, 'Record');
      },
    );

    /// @verifies FR-005
    test('showing the same information again changes nothing', () async {
      await playing((_) => tagged);
      final shown = handler.mediaItem.value;
      final changes = <Object?>[];
      handler.mediaItem.listen(changes.add);

      handler.refreshItem();
      await settle();

      expect(handler.mediaItem.value, same(shown));
      expect(changes, hasLength(1));
    });

    /// @verifies FR-005
    test('without a track, there is nothing to show again', () async {
      await handler.dispose();
      final empty = PlayerController(
        engine: FakeAudioEngine(),
        opener: FakeTrackSourceOpener(),
        volumes: FakeVolumeEvents({internalDisk}),
      );
      await empty.start();
      handler = PlayerAudioHandler(empty, describe: (_) => null)..refreshItem();

      expect(handler.mediaItem.value, isNull);
      await empty.dispose();
    });

    /// @verifies FR-005
    test('the artwork of the track is shown', () async {
      await playing((_) => tagged, artworkOf: (id) => Uri.file('/art/$id.jpg'));

      expect(handler.mediaItem.value!.artUri, Uri.file('/art/cover1.jpg'));
    });

    /// @verifies FR-005
    test('a track without artwork shows none', () async {
      var asked = 0;
      await playing(
        (_) => LibraryTrack(id: 4, disk: internalDisk, info: tagged.info),
        artworkOf: (_) {
          asked++;
          return Uri.file('/art/none.jpg');
        },
      );

      expect(handler.mediaItem.value!.artUri, isNull);
      expect(asked, 0);
    });

    /// @verifies FR-005
    test('an artwork folder not known yet shows none', () async {
      await playing((_) => tagged, artworkOf: (_) => null);

      expect(handler.mediaItem.value!.artUri, isNull);
    });
  });

  group('FR-005 a restored session', () {
    /// @verifies FR-005
    /// @verifies BR-012
    test('stays idle for the system until the first play', () async {
      await handler.dispose();
      final fresh = PlayerController(
        engine: FakeAudioEngine(),
        opener: FakeTrackSourceOpener(),
        volumes: FakeVolumeEvents({internalDisk}),
      );
      await fresh.start();
      handler = PlayerAudioHandler(
        fresh,
        describe: (track) => known[track],
        stopGrace: const Duration(milliseconds: 20),
      );

      await fresh.restore(
        PlaybackSession(
          queue: [a.track, b.track],
          currentIndex: 1,
          position: const Duration(seconds: 30),
        ),
      );
      await stopped();

      // Idle, as after any new queue: Android shows no notification and starts
      // no service until the first play.
      expect(playback().processingState, AudioProcessingState.idle);
      expect(playback().playing, isFalse);
      await fresh.dispose();
    });
  });

  group('FR-005 system commands', () {
    /// @verifies FR-005
    test('commands go through the controller', () async {
      await handler.play();
      await settle();
      expect(controller.state.playing, isTrue);

      await handler.skipToNext();
      await settle();
      expect(controller.state.currentIndex, 1);

      await handler.skipToPrevious();
      await settle();
      expect(controller.state.currentIndex, 0);

      await handler.pause();
      await settle();
      expect(controller.state.playing, isFalse);

      await handler.seek(const Duration(seconds: 12));
      await settle();
      expect(controller.state.position, const Duration(seconds: 12));
    });

    /// @verifies FR-005
    test('stop stops the controller', () async {
      await handler.play();
      await settle();

      await handler.stop();
      await stopped();

      expect(controller.state.playing, isFalse);
      expect(playback().processingState, AudioProcessingState.idle);
    });

    /// @verifies FR-005
    test('removing the task keeps playback going', () async {
      await handler.play();
      await settle();

      await handler.onTaskRemoved();
      await settle();

      expect(controller.state.playing, isTrue);
    });

    /// @verifies FR-005
    test('removing the task while paused stops', () async {
      await handler.play();
      await settle();
      await handler.pause();
      await settle();

      await handler.onTaskRemoved();
      await stopped();

      expect(playback().processingState, AudioProcessingState.idle);
    });
  });

  /// @verifies FR-029
  group('FR-029 browsing from a car', () {
    late LibraryMediaTree tree;
    var chosen = 0;

    Future<void> browsable() async {
      await handler.dispose();
      tree = LibraryMediaTree(
        albums: [
          MediaAlbum(
            key: 'k',
            title: 'Album',
            artist: 'Artist',
            tracks: [a, b],
          ),
        ],
        artists: const [],
        tracks: [a, b],
        labels: const MediaTreeLabels(
          albums: 'Albums',
          artists: 'Artists',
          tracks: 'Tracks',
          unknownAlbum: '?',
          unknownArtist: '?',
          empty: 'Empty',
        ),
        fold: (text) => text.toLowerCase(),
        current: a,
      );
      chosen = 0;
      handler = PlayerAudioHandler(
        controller,
        describe: (track) => known[track],
        mediaTree: () async => tree,
        onQueueChosen: () => chosen++,
        clock: () => now,
        stopGrace: const Duration(milliseconds: 20),
      );
    }

    test('the roots of the tree are the ones audio_service asks for', () {
      expect(MediaTree.rootId, AudioService.browsableRootId);
      expect(MediaTree.recentId, AudioService.recentRootId);
    });

    test('lists the children of a folder, folders not playable', () async {
      await browsable();

      final root = await handler.getChildren(AudioService.browsableRootId);

      expect(root.map((i) => i.title), ['A', 'Albums', 'Artists', 'Tracks']);
      expect(root.map((i) => i.playable), [true, false, false, false]);
      final tracks = await handler.getChildren('tracks');
      expect(tracks.map((i) => i.title), ['A', 'b.mp3']);
      expect(tracks.first.artist, 'Artist');
    });

    test('gives one item back by identifier', () async {
      await browsable();
      final id = (await handler.getChildren('tracks')).first.id;

      expect((await handler.getMediaItem(id))!.title, 'A');
      expect(await handler.getMediaItem('garbage'), isNull);
    });

    test('a session that cannot be browsed has no children', () async {
      expect(await handler.getChildren('root'), isEmpty);
      expect(await handler.getMediaItem('root'), isNull);
      await handler.playFromMediaId('anything');
      expect(engine.state.playing, isFalse);
    });

    test('choosing a track queues its list from there and plays', () async {
      await browsable();
      final second = (await handler.getChildren('tracks')).last;

      await handler.playFromMediaId(second.id);
      await settle();

      expect(chosen, 1);
      expect(controller.state.queue, [a.track, b.track]);
      expect(controller.state.currentTrack, b.track);
      expect(controller.state.playing, isTrue);
    });

    test(
      '"Reprendre" plays the queue already held, without replacing it',
      () async {
        await browsable();

        await handler.playFromMediaId('resume');
        await settle();

        expect(chosen, 0);
        expect(controller.state.currentTrack, a.track);
        expect(controller.state.playing, isTrue);
      },
    );

    test('an unknown identifier changes nothing', () async {
      await browsable();

      await handler.playFromMediaId('t|tracks|x|y');

      expect(chosen, 0);
      expect(controller.state.playing, isFalse);
    });
  });
}
