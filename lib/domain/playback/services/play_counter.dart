import 'dart:async';

import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/listening_store.dart';
import 'package:tuneshell/domain/playback/model/player_state.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';

/// Counts the listens of the tracks the controller plays and records them
/// (BR-014, rules 4 and 5).
///
/// A listen is counted once the track has really played for
/// [listenThreshold], or for half of its length when it is shorter than
/// twice that. The time is the clock's, not the position's: a seek does not
/// count, a pause stops the time. A gap longer than [longestGap] between two
/// reports (the application was frozen) counts for no more than that. A track
/// that starts again (a turn of the repeat, going back to it) counts again.
/// A failing storage is reported to [onError] and never reaches playback.
///
/// @implements BR-014
class PlayCounter {
  new({
    required this._controller,
    required this._store,
    this.onRecorded,
    this.onError,
    this._enabled = true,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The time a track must play to count (BR-014, rule 4).
  static const listenThreshold = Duration(seconds: 30);

  /// The most one gap between two reports adds to the time played.
  static const longestGap = Duration(seconds: 5);

  final PlayerController _controller;
  final ListeningStore _store;
  final DateTime Function() _clock;

  /// Called after a listen is stored, for the lists that show the history.
  final void Function()? onRecorded;
  final void Function(Object error)? onError;

  bool _enabled;
  StreamSubscription<PlayerState>? _subscription;
  Future<void> _tail = Future<void>.value();

  /// The queue entry being listened to, the time it has played so far, and
  /// whether this turn was counted already.
  int? _entry;
  Duration _heard = Duration.zero;
  bool _counted = false;

  /// When the last report came, while the track was playing.
  DateTime? _lastTick;

  void start() {
    _subscription = _controller.states.listen(_onState);
  }

  /// BR-014, rule 7: turned off, nothing more is recorded.
  void setEnabled({required bool enabled}) {
    _enabled = enabled;
    _lastTick = null;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _tail;
  }

  void _onState(PlayerState state) {
    final now = _clock();
    final index = state.currentIndex;
    final entry = index != null && index < state.entryIds.length
        ? state.entryIds[index]
        : null;
    final track = state.currentTrack;

    // What happened since the last report belongs to what was playing then.
    final last = _lastTick;
    if (last != null && _entry == entry) {
      final gap = now.difference(last);
      _heard += gap > longestGap ? longestGap : gap;
    }
    // Another entry, or the same one loading again: a new turn.
    if (entry != _entry || state.status == PlayerStatus.loading) {
      _entry = entry;
      _heard = Duration.zero;
      _counted = false;
    }
    final active =
        _enabled &&
        track != null &&
        state.playing &&
        state.status == PlayerStatus.ready;
    _lastTick = active ? now : null;

    if (_enabled &&
        track != null &&
        !_counted &&
        _heard >= _thresholdFor(state.duration)) {
      _counted = true;
      _record(track, now);
    }
  }

  Duration _thresholdFor(Duration? duration) =>
      duration != null && duration < listenThreshold * 2
      ? duration ~/ 2
      : listenThreshold;

  void _record(Track track, DateTime at) {
    _tail = _tail.then((_) async {
      try {
        await _store.recordPlay(track, at);
        onRecorded?.call();
      } on Object catch (error) {
        onError?.call(error);
      }
    });
  }
}
