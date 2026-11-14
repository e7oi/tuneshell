import 'dart:math';

import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/track.dart';

/// A track as the rediscoveries see it: its identity, the key of its album
/// (null when the album is unknown) and whether it can play now.
@immutable
final class RediscoveryItem {
  const new({
    required this.track,
    required this.albumKey,
    required this.available,
  });

  final Track track;
  final String? albumKey;

  /// Its disk can be read (BR-001, BR-008).
  final bool available;
}

/// The tracks and the albums the home tab proposes.
@immutable
final class RediscoverySelection {
  const new({required this.tracks, required this.albumKeys});

  static const empty = RediscoverySelection(tracks: [], albumKeys: []);

  final List<Track> tracks;

  /// The keys of the albums (BR-010), in the order drawn.
  final List<String> albumKeys;

  bool get isEmpty => tracks.isEmpty && albumKeys.isEmpty;
}

/// Draws the tracks and the albums to rediscover: not listened to for a
/// while, available, favorites and already known ones first (BR-016).
///
/// Pure: the clock and the random source are given, so that a draw can be
/// reproduced in a test (BR-016, rule 8).
///
/// @implements BR-016
/// @decision ADR-024
class Rediscovery {
  const new({
    this.trackCount = 3,
    this.albumCount = 2,
    this.quiet = const Duration(days: 30),
  });

  final int trackCount;
  final int albumCount;

  /// How long a track must not have been listened to (BR-016, rule 3).
  final Duration quiet;

  /// [items] is the whole library. [lastPlayed] and [favorites] come from the
  /// listening store; [current] is the track in the player, never proposed.
  /// [avoidTracks] and [avoidAlbums] are what a previous draw showed: they are
  /// left out while other elements remain (BR-016, rule 6).
  RediscoverySelection pick({
    required List<RediscoveryItem> items,
    required Map<Track, DateTime> lastPlayed,
    required Set<Track> favorites,
    required DateTime now,
    required Random random,
    Track? current,
    Set<Track> avoidTracks = const {},
    Set<String> avoidAlbums = const {},
  }) {
    bool isRecent(Track track) {
      final last = lastPlayed[track];
      // A listen dated in the future (clock set back) counts as recent.
      return last != null && now.difference(last) < quiet;
    }

    bool isKnown(Track track) =>
        lastPlayed.containsKey(track) || favorites.contains(track);

    String? currentAlbum;
    final byAlbum = <String, List<RediscoveryItem>>{};
    for (final item in items) {
      if (item.track == current) currentAlbum = item.albumKey;
      final key = item.albumKey;
      if (key != null) (byAlbum[key] ??= []).add(item);
    }

    final albums = <_Candidate<String>>[];
    for (final MapEntry(:key, value: members) in byAlbum.entries) {
      if (key == currentAlbum) continue;
      if (!members.any((m) => m.available)) continue;
      if (members.any((m) => isRecent(m.track))) continue;
      albums.add(
        _Candidate(
          key,
          known: members.any((m) => isKnown(m.track)),
          avoided: avoidAlbums.contains(key),
        ),
      );
    }
    final albumKeys = _choose(albums, albumCount, random);

    final drawn = albumKeys.toSet();
    final tracks = <_Candidate<Track>>[];
    for (final item in items) {
      final track = item.track;
      if (!item.available || track == current || isRecent(track)) continue;
      final album = item.albumKey;
      if (album != null && (album == currentAlbum || drawn.contains(album))) {
        continue;
      }
      tracks.add(
        _Candidate(
          track,
          known: isKnown(track),
          avoided: avoidTracks.contains(track),
        ),
      );
    }
    return RediscoverySelection(
      tracks: _choose(tracks, trackCount, random),
      albumKeys: albumKeys,
    );
  }
}

class _Candidate<T> {
  const new(this.value, {required this.known, required this.avoided});

  final T value;
  final bool known;
  final bool avoided;
}

/// Level one before level two, what was not shown before what was, each group
/// shuffled: the first [count] of that order.
List<T> _choose<T>(List<_Candidate<T>> candidates, int count, Random random) {
  final groups = [
    for (final avoided in [false, true])
      for (final known in [true, false])
        [
          for (final c in candidates)
            if (c.avoided == avoided && c.known == known) c.value,
        ]..shuffle(random),
  ];
  return [for (final group in groups) ...group].take(count).toList();
}
