import 'package:tuneshell/domain/library/model/track.dart';

/// The most listens the history keeps; the oldest go first (BR-014, rule 6).
const maxHistory = 20000;

/// Where the favorites and the listening history are kept (ADR-021).
///
/// Everything is about a track's identity (BR-004), never about a row of the
/// library: it outlives the track. Two implementations: the database and, in
/// the tests, a value in memory.
///
/// @implements BR-014
abstract interface class ListeningStore {
  /// Every favorite, including those whose track is not in the library now
  /// (BR-014, rule 2).
  Future<Set<Track>> favorites();

  /// Marks or unmarks [track]; marking twice changes nothing (BR-014, rule 3).
  Future<void> setFavorite(Track track, {required bool favorite});

  /// Records one listen at [at], then drops the oldest ones beyond
  /// [maxHistory] (BR-014, rule 6).
  Future<void> recordPlay(Track track, DateTime at);

  /// The tracks listened to, the latest listen first, each track once
  /// (BR-014, rules 6 and 8).
  Future<List<Track>> recent();

  /// The latest listen of each track that has one, for the rediscoveries of
  /// the home tab (BR-016, ADR-024). Tracks never listened to are absent.
  Future<Map<Track, DateTime>> lastPlayedAt();

  /// Forgets every listen; the favorites stay (BR-014, rule 7).
  Future<void> clearHistory();
}
