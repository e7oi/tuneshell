import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';
import 'package:tuneshell/domain/playback/services/play_counter.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_listening_store.dart';
import '../../fakes/fake_storage.dart';

const internal = DiskId('internal');

Track t(String name) => Track(disk: internal, relativePath: '$name.flac');

/// @verifies BR-014
void main() {
  late FakeAudioEngine engine;
  late PlayerController controller;
  late FakeListeningStore store;
  late PlayCounter counter;
  late List<Object> errors;
  late int recorded;
  var now = DateTime(2026, 11, 5, 20);

  final a = t('a');
  final b = t('b');

  /// Time passes while the player keeps playing: the engine reports its
  /// position, as it does every moment.
  Future<void> listen(Duration time) async {
    var left = time;
    while (left > Duration.zero) {
      final step = left > const Duration(seconds: 2)
          ? const Duration(seconds: 2)
          : left;
      now = now.add(step);
      left -= step;
      engine.emitPosition(Duration(milliseconds: now.millisecond));
      await pumpEventQueue();
    }
  }

  setUp(() async {
    now = DateTime(2026, 11, 5, 20);
    engine = FakeAudioEngine();
    controller = PlayerController(
      engine: engine,
      opener: FakeTrackSourceOpener(),
      volumes: FakeVolumeEvents({internal}),
      random: Random(7),
    );
    await controller.start();
    store = FakeListeningStore();
    errors = [];
    recorded = 0;
    counter = PlayCounter(
      controller: controller,
      store: store,
      clock: () => now,
      onRecorded: () => recorded++,
      onError: errors.add,
    )..start();
  });

  tearDown(() async {
    await counter.dispose();
    await controller.dispose();
  });

  Future<void> play(List<Track> queue, {int at = 0}) async {
    await controller.setQueue(queue, startIndex: at);
    await controller.play();
    await pumpEventQueue();
  }

  /// @verifies BR-014
  group('BR-014 rule 4: when a listen is counted', () {
    test('a track played 31 seconds is recorded once, with the time', () async {
      await play([a, b]);

      await listen(const Duration(seconds: 31));

      expect(store.plays.length, 1);
      expect(store.plays.single.track, a);
      expect(store.plays.single.at, isNot(DateTime(2026, 11, 5, 20)));
      expect(recorded, 1);
    });

    test('a skip after 5 seconds is not recorded', () async {
      await play([a, b]);

      await listen(const Duration(seconds: 5));
      await controller.next();
      await pumpEventQueue();
      await listen(const Duration(seconds: 5));

      expect(store.plays, isEmpty);
    });

    test('a track kept playing is counted once, not at every tick', () async {
      await play([a]);

      await listen(const Duration(seconds: 100));

      expect(store.plays.length, 1);
    });

    test('a pause stops the time, which adds up when playing again', () async {
      await play([a]);

      await listen(const Duration(seconds: 20));
      await controller.pause();
      await pumpEventQueue();
      now = now.add(const Duration(minutes: 10));
      engine.emitPosition(Duration.zero);
      await pumpEventQueue();
      expect(store.plays, isEmpty);
      await controller.play();
      await pumpEventQueue();
      await listen(const Duration(seconds: 15));

      expect(store.plays.length, 1);
    });

    test('a short track counts at half of its length', () async {
      engine.emitDuration(const Duration(seconds: 40));
      await play([a]);
      engine.emitDuration(const Duration(seconds: 40));
      await pumpEventQueue();

      await listen(const Duration(seconds: 21));

      expect(store.plays.length, 1);
    });

    test(
      'a long gap between two reports counts for at most 5 seconds',
      () async {
        await play([a]);

        now = now.add(const Duration(minutes: 5));
        engine.emitPosition(const Duration(seconds: 1));
        await pumpEventQueue();

        expect(store.plays, isEmpty);
      },
    );

    test('the same track counts again at each turn of the repeat', () async {
      await controller.setRepeat(RepeatMode.one);
      await play([a]);

      await listen(const Duration(seconds: 31));
      engine.completeTrack();
      await pumpEventQueue();
      await listen(const Duration(seconds: 31));

      expect(store.plays.length, 2);
    });

    test('a track that comes back later counts again', () async {
      await play([a, b]);

      await listen(const Duration(seconds: 31));
      await controller.next();
      await pumpEventQueue();
      await listen(const Duration(seconds: 31));
      await controller.previous();
      await pumpEventQueue();
      await listen(const Duration(seconds: 31));

      expect(store.plays.map((p) => p.track), [a, b, a]);
    });

    test('a track that is not playing is not counted', () async {
      await controller.setQueue([a]);
      await pumpEventQueue();

      now = now.add(const Duration(seconds: 90));
      engine.emitPosition(const Duration(seconds: 1));
      await pumpEventQueue();

      expect(store.plays, isEmpty);
    });
  });

  /// @verifies BR-014
  group('BR-014 rule 7: the setting', () {
    test('turned off, nothing is recorded; turned on, it is again', () async {
      counter.setEnabled(enabled: false);
      await play([a]);
      await listen(const Duration(seconds: 40));
      expect(store.plays, isEmpty);

      counter.setEnabled(enabled: true);
      await controller.skipTo(0);
      await pumpEventQueue();
      await listen(const Duration(seconds: 31));

      expect(store.plays.length, 1);
    });
  });

  /// @verifies BR-014
  group('BR-014 rule 9: a failing storage', () {
    test('is reported and does not stop playback or later listens', () async {
      store.failure = Exception('disk full');
      await play([a, b]);
      await listen(const Duration(seconds: 31));
      expect(errors.length, 1);
      expect(controller.state.playing, isTrue);

      store.failure = null;
      await controller.next();
      await pumpEventQueue();
      await listen(const Duration(seconds: 31));

      expect(store.plays.map((p) => p.track), [b]);
    });
  });
}
