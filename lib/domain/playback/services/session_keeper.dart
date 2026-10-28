import 'dart:async';

import 'package:tuneshell/domain/playback/model/player_state.dart';
import 'package:tuneshell/domain/playback/ports/playback_session_store.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';

/// Keeps the stored playback session up to date with the controller
/// (BR-012, rule 2).
///
/// The queue is written after a short delay that groups a burst of changes,
/// and only when it changed. The progress (current track, modes) goes the
/// same way; the position alone is written at most once per interval while
/// playing, at once on a pause or a stop, and on [flush]. A failing storage
/// is reported to [onError] and never reaches playback.
///
/// @implements BR-012
class SessionKeeper {
  new({
    required this._controller,
    required this._store,
    this.queueDelay = const Duration(seconds: 1),
    this.progressInterval = const Duration(seconds: 10),
    this.onError,
    this._enabled = true,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final PlayerController _controller;
  final PlaybackSessionStore _store;
  final Duration queueDelay;
  final Duration progressInterval;
  final void Function(Object error)? onError;
  final DateTime Function() _clock;

  bool _enabled;
  StreamSubscription<PlayerState>? _subscription;
  Timer? _timer;
  PlayerState? _previous;

  /// The entry identifiers of the queue last written or adopted; null when
  /// nothing is stored.
  List<int>? _storedIds;
  bool _queueDirty = false;
  bool _progressDirty = false;
  DateTime? _lastWrite;
  Future<void> _tail = Future<void>.value();

  /// Starts following the controller.
  void start() {
    _previous = _controller.state;
    _subscription = _controller.states.listen(_onState);
  }

  /// Tells that the controller state is what is stored (a restored session),
  /// so that it is not written again (BR-012, rule 5).
  void adopt() {
    _previous = _controller.state;
    _storedIds = _previous!.entryIds;
    _queueDirty = false;
    _progressDirty = false;
    _lastWrite = _clock();
  }

  /// Writes now what is pending, and the progress (the position may have
  /// moved without a change to report): the application is going to the
  /// background or is being removed from the recent apps.
  Future<void> flush() {
    if (!_enabled) return _tail;
    _progressDirty = true;
    return _writeNow();
  }

  /// BR-012, rule 12: turned off, the stored session is forgotten and nothing
  /// is written; turned on, the queue of the moment is written.
  Future<void> setEnabled({required bool enabled}) {
    if (enabled == _enabled) return _tail;
    _enabled = enabled;
    _timer?.cancel();
    _queueDirty = false;
    _progressDirty = false;
    if (!enabled) return _forget();
    if (_controller.state.queue.isEmpty) return _tail;
    _storedIds = null;
    _queueDirty = true;
    _progressDirty = true;
    return _writeNow();
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _tail;
  }

  void _onState(PlayerState state) {
    final before = _previous ?? state;
    _previous = state;
    if (!_enabled) return;
    if (state.queue.isEmpty) {
      if (_storedIds != null || _queueDirty) {
        _timer?.cancel();
        unawaited(_forget());
      }
      return;
    }
    if (!identical(state.entryIds, _storedIds)) _queueDirty = true;
    if (state.currentIndex != before.currentIndex ||
        state.shuffle != before.shuffle ||
        state.repeat != before.repeat) {
      _progressDirty = true;
    }
    final wasEngaged =
        before.status == PlayerStatus.ready ||
        before.status == PlayerStatus.loading;
    final stopped =
        before.playing && !state.playing ||
        wasEngaged && state.status == PlayerStatus.stopped;
    if (stopped) {
      _progressDirty = true;
      unawaited(_writeNow());
      return;
    }
    if (state.position != before.position) {
      if (state.playing) {
        final last = _lastWrite;
        if (last == null || _clock().difference(last) >= progressInterval) {
          _progressDirty = true;
          unawaited(_writeNow());
          return;
        }
      } else {
        _progressDirty = true;
      }
    }
    // Not re-armed by every position tick: a change made while playing is
    // written one delay after it, not once the ticks stop.
    if ((_queueDirty || _progressDirty) && !(_timer?.isActive ?? false)) {
      _timer = Timer(queueDelay, () => unawaited(_writeNow()));
    }
  }

  Future<void> _forget() {
    _storedIds = null;
    return _chain(_store.clear);
  }

  Future<void> _writeNow() {
    _timer?.cancel();
    return _chain(_write);
  }

  Future<void> _write() async {
    final session = _controller.session;
    if (session == null || !(_queueDirty || _progressDirty)) return;
    final queue = _queueDirty;
    final ids = _controller.state.entryIds;
    _queueDirty = false;
    _progressDirty = false;
    _lastWrite = _clock();
    try {
      if (queue) {
        await _store.writeQueue(session.queue, session.origin);
        _storedIds = ids;
      }
      await _store.writeProgress(
        currentIndex: session.currentIndex,
        position: session.position,
        shuffle: session.shuffle,
        repeat: session.repeat,
      );
    } on Object {
      // The next change writes again what was not written.
      _queueDirty = _queueDirty || queue;
      _progressDirty = true;
      rethrow;
    }
  }

  Future<void> _chain(Future<void> Function() action) {
    final result = _tail.then((_) => action());
    return _tail = result.then<void>(
      (_) {},
      onError: (Object error) => onError?.call(error),
    );
  }
}
