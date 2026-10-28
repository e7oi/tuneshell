import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/playback_notice.dart';
import 'package:tuneshell/domain/playback/model/playback_session.dart';
import 'package:tuneshell/domain/playback/model/player_state.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/domain/storage/model/media_source.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_storage.dart';

const internal = DiskId('internal');
const ssd = DiskId('ssd');

Track t(String name, [DiskId disk = internal]) =>
    Track(disk: disk, relativePath: '$name.flac');

void main() {
  late FakeAudioEngine engine;
  late PlayerController controller;
  late List<PlaybackNotice> notices;

  final a = t('a');
  final b = t('b');
  final c = t('c');
  final d = t('d');

  Future<void> settle() => pumpEventQueue();

  String? loadedPath() {
    final source = engine.loadedSource;
    return source is FileMediaSource ? source.path : null;
  }

  Future<void> createController({
    Set<DiskId> available = const {internal, ssd},
  }) async {
    engine = FakeAudioEngine();
    controller = PlayerController(
      engine: engine,
      opener: FakeTrackSourceOpener(),
      volumes: FakeVolumeEvents(available),
      random: Random(7),
    );
    notices = [];
    controller.notices.listen(notices.add);
    await controller.start();
  }

  setUp(createController);

  tearDown(() => controller.dispose());

  PlaybackSession saved({
    List<Track>? queue,
    int current = 1,
    Duration position = const Duration(seconds: 80),
    RepeatMode repeat = RepeatMode.off,
    List<int>? origin,
  }) => PlaybackSession(
    queue: queue ?? [a, b, c, d],
    currentIndex: current,
    position: position,
    shuffle: origin != null,
    repeat: repeat,
    origin: origin,
  );

  /// @verifies BR-012
  group('BR-012 the session of the controller', () {
    test('there is none without a queue', () {
      expect(controller.session, isNull);
    });

    test('rule 1: queue, current track, position and modes', () async {
      await controller.setQueue([a, b, c, d], startIndex: 2);
      await controller.setRepeat(RepeatMode.all);
      await controller.play();
      engine.emitPosition(const Duration(seconds: 42));
      await settle();

      final session = controller.session!;

      expect(session.queue, [a, b, c, d]);
      expect(session.currentIndex, 2);
      expect(session.position, const Duration(seconds: 42));
      expect(session.repeat, RepeatMode.all);
      expect(session.shuffle, isFalse);
      expect(session.origin, isNull);
      expect(session.isValid, isTrue);
    });

    test('rule 1: the original order of the shuffle', () async {
      final tracks = [for (var i = 0; i < 12; i++) t('t$i')];
      await controller.setQueue(tracks, startIndex: 3);
      await controller.setShuffle(enabled: true);

      final session = controller.session!;

      expect(session.shuffle, isTrue);
      expect([for (final i in session.origin!) session.queue[i]], tracks);
      expect(session.isValid, isTrue);
    });

    test(
      'the session of a restored controller is the one it was given',
      () async {
        final tracks = [for (var i = 0; i < 12; i++) t('t$i')];
        final session = saved(
          queue: tracks.reversed.toList(),
          current: 5,
          repeat: RepeatMode.one,
          origin: [for (var i = 11; i >= 0; i--) i],
        );

        await controller.restore(session);
        final again = controller.session!;

        expect(again.queue, session.queue);
        expect(again.currentIndex, 5);
        expect(again.position, session.position);
        expect(again.repeat, RepeatMode.one);
        expect(again.origin, session.origin);
      },
    );
  });

  /// @verifies BR-012
  group('BR-012 rule 6: restored in pause, nothing loaded', () {
    test('the state shows the track, the position and the modes', () async {
      final restored = await controller.restore(
        saved(repeat: RepeatMode.all, origin: [3, 2, 1, 0]),
      );

      expect(restored, isTrue);
      final state = controller.state;
      expect(state.queue, [a, b, c, d]);
      expect(state.currentIndex, 1);
      expect(state.position, const Duration(seconds: 80));
      expect(state.status, PlayerStatus.stopped);
      expect(state.playing, isFalse);
      expect(state.repeat, RepeatMode.all);
      expect(state.shuffle, isTrue);
      expect(state.entryIds, hasLength(4));
    });

    test('the engine is not touched and nothing is said', () async {
      await controller.restore(saved());
      await settle();

      expect(engine.calls, isEmpty);
      expect(notices, isEmpty);
    });

    test(
      'the original order comes back when the shuffle is turned off',
      () async {
        // Queue d c b a, original order a b c d.
        await controller.restore(
          saved(queue: [d, c, b, a], current: 0, origin: [3, 2, 1, 0]),
        );

        await controller.setShuffle(enabled: false);

        expect(controller.state.queue, [a, b, c, d]);
        expect(controller.state.currentTrack, d);
      },
    );

    test('a session that cannot be used is refused', () async {
      final restored = await controller.restore(saved(current: 9));

      expect(restored, isFalse);
      expect(controller.state.queue, isEmpty);
    });
  });

  /// @verifies BR-012
  group('BR-012 rule 5: only when nothing is queued yet', () {
    test('a queue already in place is kept', () async {
      await controller.setQueue([c, d]);

      final restored = await controller.restore(saved());

      expect(restored, isFalse);
      expect(controller.state.queue, [c, d]);
    });

    test('a second restore is refused', () async {
      await controller.restore(saved());

      expect(await controller.restore(saved(queue: [c])), isFalse);
    });
  });

  /// @verifies BR-012
  group('BR-012 rule 7: the first play', () {
    test(
      'loads the track, waits for it, goes to the position, plays',
      () async {
        await controller.restore(saved());

        await controller.play();
        await settle();

        expect(loadedPath(), 'internal/b.flac');
        expect(engine.calls, ['open']);
        expect(controller.state.playing, isTrue);

        engine.emitDuration(const Duration(minutes: 5));
        await settle();

        expect(engine.calls, ['open', 'seek', 'play']);
        expect(controller.state.position, const Duration(seconds: 80));
      },
    );

    test(
      'a pause before the track is loaded goes there and stays paused',
      () async {
        await controller.restore(saved());
        await controller.play();
        await controller.pause();

        engine.emitDuration(const Duration(minutes: 5));
        await settle();

        expect(engine.calls, ['open', 'pause', 'seek']);
        expect(controller.state.position, const Duration(seconds: 80));
      },
    );

    test('a duration that never comes does not block the play', () async {
      await controller.dispose();
      engine = FakeAudioEngine();
      controller = PlayerController(
        engine: engine,
        opener: FakeTrackSourceOpener(),
        volumes: FakeVolumeEvents({internal}),
        resumeWait: const Duration(milliseconds: 30),
      );
      await controller.start();
      await controller.restore(saved());

      await controller.play();
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(engine.calls, ['open', 'seek', 'play']);
    });

    test('a position of zero asks for no seek', () async {
      await controller.restore(saved(position: Duration.zero));

      await controller.play();

      expect(engine.calls, ['open', 'play']);
    });

    test('a position beyond the duration starts the track again', () async {
      await controller.restore(saved());
      await controller.play();
      await settle();

      engine.emitDuration(const Duration(seconds: 30));
      await settle();

      expect(engine.calls, ['open', 'play']);
      expect(controller.state.position, Duration.zero);
    });

    test('a position inside the duration stays', () async {
      await controller.restore(saved());
      await controller.play();
      await settle();

      engine.emitDuration(const Duration(minutes: 5));
      await settle();

      expect(controller.state.position, const Duration(seconds: 80));
      expect(engine.calls.where((c) => c == 'seek'), hasLength(1));
    });

    test('is used once: the track played again starts at zero', () async {
      await controller.restore(saved());
      await controller.play();
      engine.emitDuration(const Duration(minutes: 5));
      await settle();
      await controller.stop();
      await settle();
      engine.calls.clear();

      await controller.play();
      await settle();

      expect(engine.calls, ['open', 'play']);
    });

    test('next before the first play starts the next track at zero', () async {
      await controller.restore(saved());

      await controller.next();
      await settle();

      expect(loadedPath(), 'internal/c.flac');
      expect(engine.calls, ['open']);
      expect(controller.state.position, Duration.zero);
    });

    test('previous on the first track also forgets the position', () async {
      await controller.restore(saved(current: 0));

      await controller.previous();
      await controller.play();
      await settle();

      expect(engine.calls, ['open', 'play']);
      expect(controller.state.position, Duration.zero);
    });

    test('a new queue forgets the position', () async {
      await controller.restore(saved());
      await controller.setQueue([a, b], startIndex: 1);

      await controller.play();
      await settle();

      expect(engine.calls, ['open', 'play']);
    });

    test('is not given to another track when its disk is absent', () async {
      await controller.dispose();
      await createController(available: {internal});
      await controller.restore(saved(queue: [a, t('s', ssd), c]));

      await controller.play();
      await settle();

      expect(loadedPath(), 'internal/c.flac');
      expect(engine.calls, ['open', 'play']);
      expect(controller.state.position, Duration.zero);
      expect(notices.single, isA<TracksSkipped>());
    });

    test('a track of an absent disk stays in the queue, not opened', () async {
      await controller.dispose();
      await createController(available: {internal});

      await controller.restore(saved(queue: [t('s', ssd)], current: 0));

      expect(controller.state.queue, [t('s', ssd)]);
      expect(engine.calls, isEmpty);
    });
  });
}
