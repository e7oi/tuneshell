import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/session_restore.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/playback_session.dart';
import 'package:tuneshell/domain/playback/model/player_state.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/domain/playback/services/session_keeper.dart';

import '../fakes/fake_audio_engine.dart';
import '../fakes/fake_playback_session_store.dart';
import '../fakes/fake_storage.dart';

const internal = DiskId('internal');

Track t(String name) => Track(disk: internal, relativePath: '$name.flac');

void main() {
  late FakeAudioEngine engine;
  late PlayerController controller;
  late FakePlaybackSessionStore store;
  late SessionKeeper keeper;

  final a = t('a');
  final b = t('b');
  final c = t('c');
  final d = t('d');

  const stored = Duration(seconds: 80);

  setUp(() async {
    engine = FakeAudioEngine();
    controller = PlayerController(
      engine: engine,
      opener: FakeTrackSourceOpener(),
      volumes: FakeVolumeEvents({internal}),
    );
    await controller.start();
    store = FakePlaybackSessionStore(
      PlaybackSession(queue: [a, b, c, d], currentIndex: 1, position: stored),
    );
    keeper = SessionKeeper(
      controller: controller,
      store: store,
      queueDelay: const Duration(milliseconds: 10),
    )..start();
  });

  tearDown(() async {
    await keeper.dispose();
    await controller.dispose();
  });

  Future<void> restore({Set<Track>? library, bool enabled = true}) =>
      restorePlaybackSession(
        controller: controller,
        store: store,
        keeper: keeper,
        libraryTracks: () async => library ?? {a, b, c, d},
        enabled: enabled,
      );

  Future<void> grouped() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await pumpEventQueue();
  }

  /// @verifies BR-012
  group('BR-012 restoring at launch', () {
    test('rule 6: the queue comes back paused, nothing loaded', () async {
      await restore();

      final state = controller.state;
      expect(state.queue, [a, b, c, d]);
      expect(state.currentIndex, 1);
      expect(state.position, stored);
      expect(state.status, PlayerStatus.stopped);
      expect(state.playing, isFalse);
      expect(engine.calls, isEmpty);
    });

    test('rule 5: what was restored is not written again', () async {
      await restore();
      store.calls.clear();

      await grouped();

      expect(store.calls, isEmpty);
    });

    test(
      'rule 8: tracks that are gone leave the queue, which is stored',
      () async {
        await restore(library: {a, b, d});

        expect(controller.state.queue, [a, b, d]);
        await grouped();
        expect(store.session!.queue, [a, b, d]);
      },
    );

    test(
      'rule 9: a current track that is gone, the next one at zero',
      () async {
        await restore(library: {a, c, d});

        expect(controller.state.currentTrack, c);
        expect(controller.state.position, Duration.zero);
      },
    );

    test(
      'rule 9: nothing left in the library, the session is forgotten',
      () async {
        await restore(library: {t('other')});

        expect(controller.state.queue, isEmpty);
        expect(store.session, isNull);
      },
    );

    test('a library not read yet keeps the session as it is', () async {
      await restore(library: const {});

      expect(controller.state.queue, isEmpty);
      expect(store.session, isNotNull);
    });

    test(
      'rule 5: a queue already in place wins and replaces the session',
      () async {
        await controller.setQueue([c]);

        await restore();
        await grouped();

        expect(controller.state.queue, [c]);
        expect(store.session!.queue, [c]);
      },
    );

    test('rule 12: with the setting off, nothing is restored and the '
        'session is forgotten', () async {
      await restore(enabled: false);

      expect(controller.state.queue, isEmpty);
      expect(store.session, isNull);
    });

    test('no stored session, nothing happens', () async {
      store.session = null;

      await restore();

      expect(controller.state.queue, isEmpty);
    });

    test(
      'rule 11: a storage that cannot be read starts empty, no error',
      () async {
        store.failure = Exception('unreadable');

        await restore();

        expect(controller.state.queue, isEmpty);
      },
    );

    test('the first play goes to the stored position', () async {
      await restore();

      await controller.play();
      engine.emitDuration(const Duration(minutes: 5));
      await pumpEventQueue();

      expect(engine.calls, ['open', 'seek', 'play']);
      expect(controller.state.position, stored);
    });
  });
}
