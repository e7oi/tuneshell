import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/playback_session.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';

/// Where the playback session is kept between two launches (ADR-019).
///
/// The queue and the progress are written apart: the queue is long and
/// changes seldom, the progress is small and changes every few seconds.
/// Two implementations: the database and, in the tests, a value in memory.
///
/// @implements BR-012
abstract interface class PlaybackSessionStore {
  /// The stored session, or null when there is none or it cannot be used
  /// (BR-012, rule 11). Throws when the storage cannot be read.
  Future<PlaybackSession?> read();

  /// Replaces the stored queue. [origin] is as in [PlaybackSession.origin].
  Future<void> writeQueue(List<Track> queue, List<int>? origin);

  /// Replaces the rest of the session. Meaningful once a queue is stored.
  Future<void> writeProgress({
    required int currentIndex,
    required Duration position,
    required bool shuffle,
    required RepeatMode repeat,
  });

  /// Forgets the session.
  Future<void> clear();
}
