import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';

/// What it takes to find the music again after the application stopped: the
/// queue in its order, the current track, the position and the two modes
/// (BR-012).
///
/// @implements BR-012
@immutable
final class PlaybackSession {
  const new({
    required this.queue,
    required this.currentIndex,
    this.position = Duration.zero,
    this.shuffle = false,
    this.repeat = RepeatMode.off,
    this.origin,
  });

  final List<Track> queue;

  /// A position in [queue].
  final int currentIndex;

  final Duration position;

  final bool shuffle;

  final RepeatMode repeat;

  /// While [shuffle] is on: for each place of the queue before the shuffle,
  /// the position in [queue] of the entry that was there (BR-009, rule 2).
  /// Null otherwise.
  final List<int>? origin;

  /// False for a session that cannot be restored: an empty queue, a current
  /// index outside it, a negative position, or an original order that is not
  /// a permutation of the queue or that does not match the shuffle (BR-012,
  /// rule 11).
  bool get isValid {
    if (queue.isEmpty || currentIndex < 0 || currentIndex >= queue.length) {
      return false;
    }
    if (position.isNegative) return false;
    final order = origin;
    if (shuffle != (order != null)) return false;
    if (order == null) return true;
    if (order.length != queue.length) return false;
    final seen = <int>{};
    return order.every(
      (index) => index >= 0 && index < queue.length && seen.add(index),
    );
  }

  /// The session without the entries [isKnown] refuses, or null when none is
  /// left (BR-012, rules 8 and 9). A current track that is gone gives way to
  /// the first entry that followed it, at its start, or else to the last one
  /// before it.
  PlaybackSession? keeping(bool Function(Track track) isKnown) {
    final kept = [
      for (var i = 0; i < queue.length; i++)
        if (isKnown(queue[i])) i,
    ];
    if (kept.isEmpty) return null;
    final newIndex = {for (var i = 0; i < kept.length; i++) kept[i]: i};
    final int current;
    var at = position;
    final same = newIndex[currentIndex];
    if (same != null) {
      current = same;
    } else {
      at = Duration.zero;
      final after = kept.where((i) => i > currentIndex);
      current = newIndex[after.isNotEmpty ? after.first : kept.last]!;
    }
    final order = origin;
    return PlaybackSession(
      queue: [for (final i in kept) queue[i]],
      currentIndex: current,
      position: at,
      shuffle: shuffle,
      repeat: repeat,
      origin: order == null ? null : [for (final i in order) ?newIndex[i]],
    );
  }
}
