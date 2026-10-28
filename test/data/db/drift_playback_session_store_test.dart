import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/data/db/drift_playback_session_store.dart';
import 'package:tuneshell/data/db/library_database.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/playback_session.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';

const internal = DiskId('internal');
const ssd = DiskId('3C2B-77A1');

Track t(String name, [DiskId disk = internal]) =>
    Track(disk: disk, relativePath: '$name.flac');

void main() {
  late LibraryDatabase db;
  late DriftPlaybackSessionStore store;

  setUp(() {
    db = LibraryDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    store = DriftPlaybackSessionStore(db);
  });

  tearDown(() => db.close());

  Future<void> save(PlaybackSession s) async {
    await store.writeQueue(s.queue, s.origin);
    await store.writeProgress(
      currentIndex: s.currentIndex,
      position: s.position,
      shuffle: s.shuffle,
      repeat: s.repeat,
    );
  }

  /// @verifies BR-012
  group('DriftPlaybackSessionStore', () {
    test('a new database holds no session', () async {
      expect(await store.read(), isNull);
    });

    test('writes and reads back a session', () async {
      final queue = [t('a'), t('b', ssd), t('a')];

      await save(
        PlaybackSession(
          queue: queue,
          currentIndex: 2,
          position: const Duration(seconds: 80, milliseconds: 250),
          repeat: RepeatMode.all,
        ),
      );
      final session = (await store.read())!;

      expect(session.queue, queue);
      expect(session.currentIndex, 2);
      expect(session.position, const Duration(seconds: 80, milliseconds: 250));
      expect(session.repeat, RepeatMode.all);
      expect(session.shuffle, isFalse);
      expect(session.origin, isNull);
    });

    test('keeps the original order of the shuffle', () async {
      final queue = [t('a'), t('b'), t('c'), t('d')];

      await save(
        PlaybackSession(
          queue: queue,
          currentIndex: 0,
          shuffle: true,
          origin: const [2, 0, 3, 1],
        ),
      );
      final session = (await store.read())!;

      expect(session.shuffle, isTrue);
      expect(session.origin, [2, 0, 3, 1]);
    });

    test('a progress write leaves the queue alone', () async {
      await save(PlaybackSession(queue: [t('a'), t('b')], currentIndex: 0));

      await store.writeProgress(
        currentIndex: 1,
        position: const Duration(seconds: 5),
        shuffle: false,
        repeat: RepeatMode.one,
      );
      final session = (await store.read())!;

      expect(session.queue, [t('a'), t('b')]);
      expect(session.currentIndex, 1);
      expect(session.position, const Duration(seconds: 5));
      expect(session.repeat, RepeatMode.one);
    });

    test('a new queue replaces the old one', () async {
      await save(PlaybackSession(queue: [t('a'), t('b')], currentIndex: 1));

      await save(PlaybackSession(queue: [t('c')], currentIndex: 0));

      expect((await store.read())!.queue, [t('c')]);
    });

    test('a long queue goes through and comes back in order', () async {
      final queue = [for (var i = 0; i < 7600; i++) t('track$i')];

      await save(PlaybackSession(queue: queue, currentIndex: 7000));
      final session = (await store.read())!;

      expect(session.queue, queue);
      expect(session.currentIndex, 7000);
    });

    test('clear forgets everything', () async {
      await save(PlaybackSession(queue: [t('a')], currentIndex: 0));

      await store.clear();

      expect(await store.read(), isNull);
      expect(await db.select(db.playbackQueueEntries).get(), isEmpty);
    });

    test('rule 11: an unknown repetition gives no session', () async {
      await save(PlaybackSession(queue: [t('a')], currentIndex: 0));
      await db.customStatement("UPDATE playback_session SET repeat = 'bogus'");

      expect(await store.read(), isNull);
    });

    test('rule 11: an index outside the queue gives no session', () async {
      await save(PlaybackSession(queue: [t('a')], currentIndex: 0));
      await db.customStatement('UPDATE playback_session SET current_index = 4');

      expect(await store.read(), isNull);
    });

    test('rule 11: a hole in the queue gives no session', () async {
      await save(
        PlaybackSession(queue: [t('a'), t('b'), t('c')], currentIndex: 0),
      );
      await db.customStatement('DELETE FROM playback_queue WHERE position = 1');

      expect(await store.read(), isNull);
    });

    test('rule 11: a queue without its progress gives no session', () async {
      await store.writeQueue([t('a')], null);

      expect(await store.read(), isNull);
    });

    test(
      'rule 11: an original order with a repeated place gives none',
      () async {
        await save(
          PlaybackSession(
            queue: [t('a'), t('b')],
            currentIndex: 0,
            shuffle: true,
            origin: const [1, 0],
          ),
        );
        await db.customStatement(
          'UPDATE playback_queue SET origin_position = 0',
        );

        expect(await store.read(), isNull);
      },
    );
  });
}
