import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/data/db/drift_listening_store.dart';
import 'package:tuneshell/data/db/library_database.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/listening_store.dart';

const internal = DiskId('internal');
const ssd = DiskId('3C2B-77A1');

Track t(String name, [DiskId disk = internal]) =>
    Track(disk: disk, relativePath: '$name.flac');

/// @verifies BR-014
void main() {
  late LibraryDatabase db;
  late DriftListeningStore store;
  final t0 = DateTime.utc(2026, 11);

  setUp(() {
    db = LibraryDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    store = DriftListeningStore(db);
  });

  tearDown(() => db.close());

  group('favorites', () {
    test('start empty', () async {
      expect(await store.favorites(), isEmpty);
    });

    test('are marked, kept per disk, and unmarked', () async {
      await store.setFavorite(t('a'), favorite: true);
      await store.setFavorite(t('a', ssd), favorite: true);
      await store.setFavorite(t('a'), favorite: true);

      expect(await store.favorites(), {t('a'), t('a', ssd)});

      await store.setFavorite(t('a'), favorite: false);

      expect(await store.favorites(), {t('a', ssd)});
    });

    test('unmarking a track that is not a favorite changes nothing', () async {
      await store.setFavorite(t('a'), favorite: false);

      expect(await store.favorites(), isEmpty);
    });
  });

  group('history', () {
    test('lists each track once, the latest listen first', () async {
      await store.recordPlay(t('a'), t0);
      await store.recordPlay(t('b'), t0.add(const Duration(minutes: 1)));
      await store.recordPlay(t('a'), t0.add(const Duration(minutes: 2)));

      expect(await store.recent(), [t('a'), t('b')]);
    });

    test('keeps only the latest listens', () async {
      for (var i = 0; i < maxHistory + 3; i++) {
        await db.customStatement(
          'INSERT INTO play_events (disk_id, relative_path, played_at) '
          "VALUES ('internal', 'old$i.flac', $i)",
        );
      }

      await store.recordPlay(t('new'), t0);

      final rows = await db
          .customSelect('SELECT COUNT(*) c FROM play_events')
          .getSingle();
      expect(rows.read<int>('c'), maxHistory);
      final recent = await store.recent();
      expect(recent.first, t('new'));
      expect(recent, isNot(contains(t('old0'))));
    });

    test('is cleared without touching the favorites', () async {
      await store.setFavorite(t('a'), favorite: true);
      await store.recordPlay(t('a'), t0);

      await store.clearHistory();

      expect(await store.recent(), isEmpty);
      expect(await store.favorites(), {t('a')});
    });
  });
}
