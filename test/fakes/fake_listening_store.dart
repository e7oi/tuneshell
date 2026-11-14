import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/listening_store.dart';

/// In-memory [ListeningStore].
class FakeListeningStore implements ListeningStore {
  /// What is marked.
  final Set<Track> marked = {};

  /// Every listen, oldest first.
  final List<({Track track, DateTime at})> plays = [];

  /// Every call throws while this is set.
  Exception? failure;

  void _check() {
    final problem = failure;
    if (problem != null) throw problem;
  }

  @override
  Future<Set<Track>> favorites() async {
    _check();
    return {...marked};
  }

  @override
  Future<void> setFavorite(Track track, {required bool favorite}) async {
    _check();
    if (favorite) {
      marked.add(track);
    } else {
      marked.remove(track);
    }
  }

  @override
  Future<void> recordPlay(Track track, DateTime at) async {
    _check();
    plays.add((track: track, at: at));
    if (plays.length > maxHistory) plays.removeAt(0);
  }

  @override
  Future<List<Track>> recent() async {
    _check();
    final seen = <Track>{};
    return [
      for (final play in plays.reversed)
        if (seen.add(play.track)) play.track,
    ];
  }

  @override
  Future<Map<Track, DateTime>> lastPlayedAt() async {
    _check();
    final last = <Track, DateTime>{};
    for (final play in plays) {
      final known = last[play.track];
      if (known == null || play.at.isAfter(known)) last[play.track] = play.at;
    }
    return last;
  }

  @override
  Future<void> clearHistory() async {
    _check();
    plays.clear();
  }
}
