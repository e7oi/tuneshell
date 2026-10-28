import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/playback_session.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';

const internal = DiskId('internal');

Track t(String name) => Track(disk: internal, relativePath: '$name.flac');

void main() {
  final a = t('a');
  final b = t('b');
  final c = t('c');
  final d = t('d');
  final e = t('e');

  PlaybackSession session({
    List<Track>? queue,
    int current = 0,
    Duration position = const Duration(seconds: 80),
    List<int>? origin,
  }) => PlaybackSession(
    queue: queue ?? [a, b, c, d, e],
    currentIndex: current,
    position: position,
    shuffle: origin != null,
    origin: origin,
  );

  /// @verifies BR-012
  group('BR-012 rule 11: a session that cannot be used', () {
    test('a normal session is valid', () {
      expect(session(current: 2).isValid, isTrue);
      expect(session(origin: [0, 1, 2, 3, 4]).isValid, isTrue);
    });

    test('an empty queue, an index outside it, a negative position', () {
      expect(session(queue: const []).isValid, isFalse);
      expect(session(current: 5).isValid, isFalse);
      expect(session(current: -1).isValid, isFalse);
      expect(session(position: const Duration(seconds: -1)).isValid, isFalse);
    });

    test('an original order that is not a permutation of the queue', () {
      expect(session(origin: [0, 1, 2]).isValid, isFalse);
      expect(session(origin: [0, 1, 2, 3, 3]).isValid, isFalse);
      expect(session(origin: [0, 1, 2, 3, 9]).isValid, isFalse);
    });

    test('the original order goes with the shuffle', () {
      final withoutOrder = PlaybackSession(
        queue: [a, b],
        currentIndex: 0,
        shuffle: true,
      );
      final withoutShuffle = PlaybackSession(
        queue: [a, b],
        currentIndex: 0,
        origin: const [0, 1],
      );

      expect(withoutOrder.isValid, isFalse);
      expect(withoutShuffle.isValid, isFalse);
    });
  });

  /// @verifies BR-012
  group('BR-012 rules 8 and 9: tracks that are gone', () {
    test('keeps everything when everything is known', () {
      final kept = session(current: 2).keeping((_) => true)!;

      expect(kept.queue, [a, b, c, d, e]);
      expect(kept.currentIndex, 2);
      expect(kept.position, const Duration(seconds: 80));
    });

    test('rule 8: an unknown entry leaves the queue, the current follows', () {
      final kept = session(current: 3).keeping((x) => x != a && x != c)!;

      expect(kept.queue, [b, d, e]);
      expect(kept.currentIndex, 1);
      expect(kept.position, const Duration(seconds: 80));
    });

    test('rule 9: a current track that is gone gives way to the next', () {
      final kept = session(current: 2).keeping((x) => x != c)!;

      expect(kept.queue, [a, b, d, e]);
      expect(kept.currentIndex, 2);
      expect(kept.queue[kept.currentIndex], d);
      expect(kept.position, Duration.zero);
    });

    test('rule 9: with none after it, the last one before it', () {
      final kept = session(current: 3).keeping((x) => x != d && x != e)!;

      expect(kept.queue, [a, b, c]);
      expect(kept.currentIndex, 2);
      expect(kept.position, Duration.zero);
    });

    test('rule 9: nothing left, nothing to restore', () {
      expect(session().keeping((_) => false), isNull);
    });

    test('the original order loses the same entries', () {
      // Queue [a b c d e] shuffled from the original order e a d b c.
      final shuffled = session(queue: [a, b, c, d, e], origin: [4, 0, 3, 1, 2]);

      final kept = shuffled.keeping((x) => x != a && x != d)!;

      // Remaining queue [b c e]; original order e b c -> indexes 2 0 1.
      expect(kept.queue, [b, c, e]);
      expect(kept.origin, [2, 0, 1]);
      expect(kept.isValid, isTrue);
    });

    test('keeps the modes', () {
      final kept = PlaybackSession(
        queue: [a, b],
        currentIndex: 1,
        repeat: RepeatMode.all,
      ).keeping((_) => true)!;

      expect(kept.repeat, RepeatMode.all);
    });

    test('a track queued twice is kept twice', () {
      final kept = PlaybackSession(
        queue: [a, b, a],
        currentIndex: 2,
      ).keeping((_) => true)!;

      expect(kept.queue, [a, b, a]);
      expect(kept.currentIndex, 2);
    });
  });
}
