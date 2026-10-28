import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/playback_session.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/domain/playback/services/session_keeper.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_playback_session_store.dart';
import '../../fakes/fake_storage.dart';

const internal = DiskId('internal');

Track t(String name) => Track(disk: internal, relativePath: '$name.flac');

void main() {
  late FakeAudioEngine engine;
  late PlayerController controller;
  late FakePlaybackSessionStore store;
  late SessionKeeper keeper;
  late List<Object> errors;

  final a = t('a');
  final b = t('b');
  final c = t('c');

  const delay = Duration(milliseconds: 20);
  const interval = Duration(milliseconds: 400);

  /// Past the delay that groups the writes.
  Future<void> grouped() async {
    await Future<void>.delayed(delay * 3);
    await pumpEventQueue();
  }

  int count(String call) => store.calls.where((x) => x == call).length;

  setUp(() async {
    engine = FakeAudioEngine();
    controller = PlayerController(
      engine: engine,
      opener: FakeTrackSourceOpener(),
      volumes: FakeVolumeEvents({internal}),
      random: Random(7),
    );
    await controller.start();
    store = FakePlaybackSessionStore();
    errors = [];
    keeper = SessionKeeper(
      controller: controller,
      store: store,
      queueDelay: delay,
      progressInterval: interval,
      onError: errors.add,
    )..start();
  });

  tearDown(() async {
    await keeper.dispose();
    await controller.dispose();
  });

  /// @verifies BR-012
  group('BR-012 rule 2: when the session is written', () {
    test(
      'a new queue is written after a short delay, with its progress',
      () async {
        await controller.setQueue([a, b, c], startIndex: 1);
        expect(store.session, isNull);

        await grouped();

        final session = store.session!;
        expect(session.queue, [a, b, c]);
        expect(session.currentIndex, 1);
        expect(session.position, Duration.zero);
      },
    );

    test('nothing is written for an empty controller', () async {
      await grouped();

      expect(store.calls, isEmpty);
    });

    test('a burst of changes makes one write of the queue', () async {
      await controller.setQueue([a, b, c]);
      await controller.enqueue([t('d')]);
      await controller.playNext([t('e')]);
      await controller.setShuffle(enabled: true);

      await grouped();

      expect(count('queue'), 1);
      expect(store.session!.queue, controller.state.queue);
      expect(store.session!.origin, controller.session!.origin);
    });

    test('a change of track writes the progress, not the queue', () async {
      await controller.setQueue([a, b, c]);
      await grouped();
      store.calls.clear();

      await controller.skipTo(2);
      await grouped();

      expect(store.calls, ['progress']);
      expect(store.session!.currentIndex, 2);
    });

    test('a change of repetition is written', () async {
      await controller.setQueue([a, b]);
      await grouped();

      await controller.setRepeat(RepeatMode.one);
      await grouped();

      expect(store.session!.repeat, RepeatMode.one);
    });

    test('pausing writes the position at once', () async {
      await controller.setQueue([a, b]);
      await controller.play();
      await grouped();
      engine.emitPosition(const Duration(seconds: 5));
      await pumpEventQueue();

      await controller.pause();
      await pumpEventQueue();

      expect(store.session!.position, const Duration(seconds: 5));
    });

    test('stopping writes the position at once', () async {
      await controller.setQueue([a, b]);
      await controller.play();
      engine.emitPosition(const Duration(seconds: 7));
      await pumpEventQueue();
      await grouped();

      engine.emitPosition(const Duration(seconds: 9));
      await pumpEventQueue();
      await controller.stop();
      await pumpEventQueue();

      expect(store.session!.queue, [a, b]);
    });

    test('while playing, the position is written once per interval', () async {
      await controller.setQueue([a, b]);
      await controller.play();
      await grouped();
      store.calls.clear();

      // About 20 position events in 60 ms: less than one interval.
      for (var i = 1; i <= 20; i++) {
        engine.emitPosition(Duration(seconds: i));
        await Future<void>.delayed(const Duration(milliseconds: 3));
      }
      await pumpEventQueue();
      expect(count('progress'), 0);

      await Future<void>.delayed(interval);
      engine.emitPosition(const Duration(seconds: 30));
      await pumpEventQueue();

      expect(count('progress'), 1);
      expect(store.session!.position, const Duration(seconds: 30));
      expect(count('queue'), 0);
    });

    test('a change made while playing is written despite the ticks', () async {
      await controller.setQueue([a, b, c]);
      await controller.play();
      await grouped();
      store.calls.clear();

      await controller.skipTo(2);
      for (var i = 1; i <= 25; i++) {
        engine.emitPosition(Duration(milliseconds: i));
        await Future<void>.delayed(const Duration(milliseconds: 4));
      }
      await pumpEventQueue();

      expect(store.session!.currentIndex, 2);
    });

    test('flush writes what is pending now', () async {
      await controller.setQueue([a, b]);

      await keeper.flush();

      expect(store.session!.queue, [a, b]);
    });
  });

  /// @verifies BR-012
  group('BR-012 rule 4: an empty queue', () {
    test('forgets the stored session', () async {
      await controller.setQueue([a, b]);
      await grouped();

      await controller.setQueue(const []);
      await pumpEventQueue();

      expect(store.session, isNull);
      expect(store.calls.last, 'clear');
    });
  });

  /// @verifies BR-012
  group('BR-012 rule 5: a restored session is not written again', () {
    test('adopting it avoids rewriting the queue', () async {
      await controller.restore(
        PlaybackSession(queue: [a, b, c], currentIndex: 1),
      );
      keeper.adopt();

      await grouped();

      expect(store.calls, isEmpty);
    });

    test('a later change is written', () async {
      await controller.restore(
        PlaybackSession(queue: [a, b, c], currentIndex: 1),
      );
      keeper.adopt();

      await controller.enqueue([t('d')]);
      await grouped();

      expect(count('queue'), 1);
    });
  });

  /// @verifies BR-012
  group('BR-012 rule 12: the setting', () {
    test(
      'turned off, the session is forgotten and no longer written',
      () async {
        await controller.setQueue([a, b]);
        await grouped();

        await keeper.setEnabled(enabled: false);
        await controller.enqueue([c]);
        await controller.pause();
        await grouped();

        expect(store.session, isNull);
        expect(count('queue'), 1);
      },
    );

    test('turned on again, the queue of the moment is written', () async {
      await keeper.setEnabled(enabled: false);
      await controller.setQueue([a, b, c], startIndex: 2);
      await grouped();
      expect(store.session, isNull);

      await keeper.setEnabled(enabled: true);

      expect(store.session!.queue, [a, b, c]);
      expect(store.session!.currentIndex, 2);
    });

    test('turned on with nothing queued, nothing is written', () async {
      await keeper.setEnabled(enabled: false);
      store.calls.clear();

      await keeper.setEnabled(enabled: true);

      expect(store.calls, isEmpty);
    });

    test('a keeper that starts turned off writes nothing', () async {
      await keeper.dispose();
      keeper = SessionKeeper(
        controller: controller,
        store: store,
        queueDelay: delay,
        enabled: false,
      )..start();

      await controller.setQueue([a]);
      await grouped();

      expect(store.calls, isEmpty);
    });
  });

  /// @verifies BR-012
  group('BR-012 the storage that fails', () {
    test('is reported and does not stop playback or later writes', () async {
      store.failure = Exception('disk full');
      await controller.setQueue([a, b]);
      await grouped();
      expect(errors, isNotEmpty);

      store.failure = null;
      await controller.enqueue([c]);
      await grouped();

      expect(store.session!.queue, [a, b, c]);
    });
  });
}
