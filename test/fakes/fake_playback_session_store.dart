import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/playback_session.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';
import 'package:tuneshell/domain/playback/ports/playback_session_store.dart';

/// In-memory [PlaybackSessionStore].
class FakePlaybackSessionStore implements PlaybackSessionStore {
  new([this.session]);

  /// What is stored.
  PlaybackSession? session;

  /// Every call, in order: `queue`, `progress`, `clear`.
  final List<String> calls = [];

  /// Every call throws while this is set.
  Exception? failure;

  void _check() {
    final problem = failure;
    if (problem != null) throw problem;
  }

  @override
  Future<PlaybackSession?> read() async {
    _check();
    return session;
  }

  @override
  Future<void> writeQueue(List<Track> queue, List<int>? origin) async {
    _check();
    calls.add('queue');
    final before = session;
    session = PlaybackSession(
      queue: List.of(queue),
      currentIndex: before?.currentIndex ?? 0,
      position: before?.position ?? Duration.zero,
      shuffle: origin != null,
      repeat: before?.repeat ?? RepeatMode.off,
      origin: origin,
    );
  }

  @override
  Future<void> writeProgress({
    required int currentIndex,
    required Duration position,
    required bool shuffle,
    required RepeatMode repeat,
  }) async {
    _check();
    calls.add('progress');
    final before = session;
    if (before == null) return;
    session = PlaybackSession(
      queue: before.queue,
      currentIndex: currentIndex,
      position: position,
      shuffle: shuffle,
      repeat: repeat,
      origin: before.origin,
    );
  }

  @override
  Future<void> clear() async {
    _check();
    calls.add('clear');
    session = null;
  }
}
