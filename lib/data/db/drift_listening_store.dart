import 'package:drift/drift.dart';
import 'package:tuneshell/data/db/library_database.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/listening_store.dart';

/// The favorites and the listening history in the `favorites` and
/// `play_events` tables of the library database (ADR-021).
///
/// @implements BR-014
class DriftListeningStore implements ListeningStore {
  new(this._db);

  final LibraryDatabase _db;

  @override
  Future<Set<Track>> favorites() async {
    final rows = await _db.select(_db.favorites).get();
    return {
      for (final r in rows)
        Track(disk: DiskId(r.diskId), relativePath: r.relativePath),
    };
  }

  @override
  Future<void> setFavorite(Track track, {required bool favorite}) async {
    if (favorite) {
      await _db
          .into(_db.favorites)
          .insert(
            FavoritesCompanion.insert(
              diskId: track.disk.value,
              relativePath: track.relativePath,
              addedAt: DateTime.now().millisecondsSinceEpoch,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    } else {
      await (_db.delete(_db.favorites)..where(
            (t) =>
                t.diskId.equals(track.disk.value) &
                t.relativePath.equals(track.relativePath),
          ))
          .go();
    }
  }

  @override
  Future<void> recordPlay(Track track, DateTime at) =>
      _db.transaction(() async {
        await _db
            .into(_db.playEvents)
            .insert(
              PlayEventsCompanion.insert(
                diskId: track.disk.value,
                relativePath: track.relativePath,
                playedAt: at.millisecondsSinceEpoch,
              ),
            );
        // Ids grow with the inserts, so the oldest listens have the lowest ids.
        await _db.customUpdate(
          'DELETE FROM play_events WHERE id <= '
          '(SELECT MAX(id) FROM play_events) - $maxHistory',
          updates: {_db.playEvents},
          updateKind: UpdateKind.delete,
        );
      });

  @override
  Future<List<Track>> recent() async {
    final rows = await _db
        .customSelect(
          'SELECT disk_id, relative_path FROM play_events '
          'GROUP BY disk_id, relative_path '
          'ORDER BY MAX(played_at) DESC, MAX(id) DESC',
          readsFrom: {_db.playEvents},
        )
        .get();
    return [
      for (final r in rows)
        Track(
          disk: DiskId(r.read<String>('disk_id')),
          relativePath: r.read<String>('relative_path'),
        ),
    ];
  }

  @override
  Future<void> clearHistory() => _db.delete(_db.playEvents).go();
}
