import 'package:drift/drift.dart';
import 'package:tuneshell/data/db/library_database.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/playback_session.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';
import 'package:tuneshell/domain/playback/ports/playback_session_store.dart';

/// The playback session in the `playback_session` and `playback_queue`
/// tables of the library database (ADR-019).
///
/// @implements BR-012
class DriftPlaybackSessionStore implements PlaybackSessionStore {
  new(this._db);

  final LibraryDatabase _db;

  /// The only row of `playback_session`.
  static const _rowId = 1;

  /// Rows of the queue inserted by one statement batch.
  static const _chunk = 500;

  @override
  Future<PlaybackSession?> read() async {
    final row = await (_db.select(
      _db.playbackSessions,
    )..where((t) => t.id.equals(_rowId))).getSingleOrNull();
    if (row == null) return null;
    final entries = await (_db.select(
      _db.playbackQueueEntries,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    final repeat = RepeatMode.values
        .where((mode) => mode.name == row.repeat)
        .firstOrNull;
    if (repeat == null || entries.isEmpty) return null;
    // The positions must be 0..n-1 without a gap; anything else is damage.
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].position != i) return null;
    }
    final origins = [for (final e in entries) e.originPosition];
    final shuffle = row.shuffle;
    List<int>? origin;
    if (shuffle) {
      if (origins.any((o) => o == null)) return null;
      // originPosition[i] is the place of entry i in the original order;
      // the session wants, for each place, the entry that was there.
      final byPlace = List<int?>.filled(entries.length, null);
      for (var i = 0; i < entries.length; i++) {
        final place = origins[i]!;
        if (place < 0 || place >= byPlace.length || byPlace[place] != null) {
          return null;
        }
        byPlace[place] = i;
      }
      origin = byPlace.cast<int>();
    }
    final session = PlaybackSession(
      queue: [
        for (final e in entries)
          Track(disk: DiskId(e.diskId), relativePath: e.relativePath),
      ],
      currentIndex: row.currentIndex,
      position: Duration(milliseconds: row.positionMs),
      shuffle: shuffle,
      repeat: repeat,
      origin: origin,
    );
    return session.isValid ? session : null;
  }

  @override
  Future<void> writeQueue(List<Track> queue, List<int>? origin) =>
      _db.transaction(() async {
        await _db.delete(_db.playbackQueueEntries).go();
        final place = <int, int>{};
        if (origin != null) {
          for (var k = 0; k < origin.length; k++) {
            place[origin[k]] = k;
          }
        }
        for (var start = 0; start < queue.length; start += _chunk) {
          final end = start + _chunk < queue.length
              ? start + _chunk
              : queue.length;
          await _db.batch((batch) {
            batch.insertAll(_db.playbackQueueEntries, [
              for (var i = start; i < end; i++)
                PlaybackQueueEntriesCompanion.insert(
                  position: Value(i),
                  diskId: queue[i].disk.value,
                  relativePath: queue[i].relativePath,
                  originPosition: Value(origin == null ? null : place[i]),
                ),
            ]);
          });
        }
      });

  @override
  Future<void> writeProgress({
    required int currentIndex,
    required Duration position,
    required bool shuffle,
    required RepeatMode repeat,
  }) => _db
      .into(_db.playbackSessions)
      .insertOnConflictUpdate(
        PlaybackSessionsCompanion.insert(
          id: const Value(_rowId),
          currentIndex: currentIndex,
          positionMs: position.inMilliseconds,
          shuffle: shuffle,
          repeat: repeat.name,
        ),
      );

  @override
  Future<void> clear() => _db.transaction(() async {
    await _db.delete(_db.playbackQueueEntries).go();
    await _db.delete(_db.playbackSessions).go();
  });
}
