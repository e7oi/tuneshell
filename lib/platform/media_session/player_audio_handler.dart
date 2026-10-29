import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/media_node.dart';
import 'package:tuneshell/domain/playback/model/player_state.dart';
import 'package:tuneshell/domain/playback/model/repeat_mode.dart';
import 'package:tuneshell/domain/playback/ports/media_tree.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';

/// Finds the library information of a track; null when it is not known.
typedef TrackDescriber = LibraryTrack? Function(Track track);

/// Where the image of an artwork identifier is stored; null when the folder
/// of the images is not known yet.
/// What a browse row stands for, to choose its placeholder image.
enum BrowseKind { album, artist, track }

typedef ArtworkLocator = Uri? Function(String artwork);

/// The media tree of the library as it is now; it may have to wait for the
/// library to be read (ADR-020).
typedef MediaTreeLocator = Future<MediaTree> Function();

/// The media session of Android (notification, lock screen, media buttons)
/// over the [PlayerController] (ADR-006). It holds no playback logic: every
/// command goes to the controller, and the session shows the controller's
/// state.
///
/// @implements FR-005
class PlayerAudioHandler extends BaseAudioHandler with SeekHandler {
  new(
    this._controller, {
    required this._describe,
    this._artworkOf = _noArtwork,
    this._browseFallbackArt,
    this._tabIcon,
    this._mediaTree,
    this._onQueueChosen,
    this._clock = DateTime.now,
    this._stopGrace = const Duration(milliseconds: 500),
  }) {
    _subscription = _controller.states.listen(_show);
    _show(_controller.state);
  }

  static Uri? _noArtwork(String artwork) => null;

  /// A position this far from the one the system extrapolates is a seek or a
  /// jump: it is sent; regular progress is not.
  static const _positionTolerance = Duration(milliseconds: 1500);

  final PlayerController _controller;
  final TrackDescriber _describe;
  final ArtworkLocator _artworkOf;

  /// The image of a browse row that has none, by kind of row: a car aligns
  /// the text of a row with an image only when every row of the list has one
  /// (FR-029).
  final Uri? Function(BrowseKind kind)? _browseFallbackArt;

  /// The icon of a tab of the car: the three folders of the root. A car
  /// draws a tab from its icon alone, and reads it from a resource of the
  /// application rather than from a provider.
  final Uri? Function(BrowseKind kind)? _tabIcon;

  /// Null: the session cannot be browsed (no car, in the tests).
  final MediaTreeLocator? _mediaTree;

  /// Called when a browser replaces the queue, before it is replaced.
  final void Function()? _onQueueChosen;
  final DateTime Function() _clock;

  /// Choosing another track goes through "stopped" for an instant: the
  /// session is released only when the player stays stopped this long, so
  /// that the notification does not disappear and come back.
  final Duration _stopGrace;

  late final StreamSubscription<PlayerState> _subscription;
  Timer? _release;

  Track? _shownTrack;

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> stop() => _controller.stop();

  @override
  Future<void> seek(Duration position) => _controller.seek(position);

  @override
  Future<void> skipToNext() => _controller.next();

  static const _shuffleAction = 'shuffle';
  static const _repeatAction = 'repeat';

  /// The two buttons of a car's player: shuffle on or off, repeat through
  /// off, all, one (BR-009).
  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) =>
      switch (name) {
        _shuffleAction => _controller.setShuffle(
          enabled: !_controller.state.shuffle,
        ),
        _repeatAction => _controller.setRepeat(
          switch (_controller.state.repeat) {
            RepeatMode.off => RepeatMode.all,
            RepeatMode.all => RepeatMode.one,
            RepeatMode.one => RepeatMode.off,
          },
        ),
        _ => Future<void>.value(),
      };

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) =>
      _controller.setShuffle(
        enabled: shuffleMode != AudioServiceShuffleMode.none,
      );

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) =>
      _controller.setRepeat(switch (repeatMode) {
        AudioServiceRepeatMode.none => RepeatMode.off,
        AudioServiceRepeatMode.one => RepeatMode.one,
        AudioServiceRepeatMode.all ||
        AudioServiceRepeatMode.group => RepeatMode.all,
      });

  @override
  Future<void> skipToPrevious() => _controller.previous();

  /// What a car browses (BR-013, FR-029).
  ///
  /// @implements FR-029
  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    final tree = await _mediaTree?.call();
    if (tree == null) return const [];
    return [for (final node in tree.children(parentMediaId)) _browseItem(node)];
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    final node = (await _mediaTree?.call())?.node(mediaId);
    return node == null ? null : _browseItem(node);
  }

  /// A car chose [mediaId]: a track of a list, or "Reprendre" (BR-013, rules
  /// 2 and 5).
  ///
  /// @implements FR-029
  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final action = (await _mediaTree?.call())?.action(mediaId);
    switch (action) {
      case null:
        return;
      case ResumeAction():
        await _controller.play();
      case PlayTracks(:final queue, :final startIndex):
        _onQueueChosen?.call();
        await _controller.setQueue(queue, startIndex: startIndex);
        await _controller.play();
    }
  }

  /// The kind of a row, from the first part of its identifier (BR-013).
  static BrowseKind _kindOf(String id) =>
      switch (Uri.decodeComponent(id.split('|').first)) {
        'albums' || 'album' => BrowseKind.album,
        'artists' || 'artist' => BrowseKind.artist,
        _ => BrowseKind.track,
      };

  Uri? _tabIconOf(String id) => switch (id) {
    'albums' => _tabIcon?.call(BrowseKind.album),
    'artists' => _tabIcon?.call(BrowseKind.artist),
    'tracks' => _tabIcon?.call(BrowseKind.track),
    _ => null,
  };

  MediaItem _browseItem(MediaNode node) {
    final artwork = node.artwork;
    return MediaItem(
      id: node.id,
      title: node.title,
      artist: node.subtitle,
      artUri:
          _tabIconOf(node.id) ??
          (artwork == null ? null : _artworkOf(artwork)) ??
          _browseFallbackArt?.call(_kindOf(node.id)),
      playable: node.playable,
    );
  }

  /// FR-005, requirement 8: playback outlives the task; a paused player
  /// does not.
  @override
  Future<void> onTaskRemoved() async {
    if (!_controller.state.playing) await stop();
  }

  /// Shows the current track again with what the library knows now: the tags
  /// and the artwork are read after the track may already be playing.
  ///
  /// @implements FR-005
  void refreshItem() {
    final state = _controller.state;
    final track = state.currentTrack;
    if (track == null || track != _shownTrack) return;
    final item = _itemOf(track, state);
    if (!_sameInfo(item, mediaItem.value)) mediaItem.add(item);
  }

  Future<void> dispose() {
    _release?.cancel();
    return _subscription.cancel();
  }

  void _show(PlayerState state) {
    final stopped =
        state.status == PlayerStatus.stopped ||
        state.status == PlayerStatus.idle;
    if (!stopped) {
      _release?.cancel();
      _release = null;
    } else if (playbackState.value.processingState !=
        AudioProcessingState.idle) {
      _release ??= Timer(_stopGrace, () {
        _release = null;
        _showNow(_controller.state);
      });
      return;
    }
    _showNow(state);
  }

  void _showNow(PlayerState state) {
    final track = state.currentTrack;
    if (track != _shownTrack || _durationChanged(state)) {
      _shownTrack = track;
      mediaItem.add(track == null ? null : _itemOf(track, state));
    }
    final next = _playbackOf(state);
    if (_differs(playbackState.value, next)) playbackState.add(next);
  }

  bool _durationChanged(PlayerState state) =>
      state.duration != null && mediaItem.value?.duration != state.duration;

  /// [MediaItem] compares by identifier only.
  static bool _sameInfo(MediaItem a, MediaItem? b) =>
      b != null &&
      a.title == b.title &&
      a.artist == b.artist &&
      a.album == b.album &&
      a.duration == b.duration &&
      a.artUri == b.artUri;

  MediaItem _itemOf(Track track, PlayerState state) {
    final known = _describe(track);
    final path = track.relativePath;
    final artwork = known?.artwork;
    return MediaItem(
      id: '${track.disk.value}/$path',
      title: known?.displayTitle ?? path.substring(path.lastIndexOf('/') + 1),
      artist: known?.info.artist,
      album: known?.info.album,
      duration: state.duration ?? known?.info.duration,
      artUri:
          (artwork == null ? null : _artworkOf(artwork)) ??
          _browseFallbackArt?.call(BrowseKind.track),
    );
  }

  PlaybackState _playbackOf(PlayerState state) => PlaybackState(
    controls: [
      MediaControl.skipToPrevious,
      if (state.playing) MediaControl.pause else MediaControl.play,
      MediaControl.stop,
      MediaControl.skipToNext,
      // Actions of the player of a car; the notification only shows the
      // four above (FR-029, BR-009).
      MediaControl.custom(
        androidIcon: state.shuffle
            ? 'drawable/ic_shuffle_on'
            : 'drawable/ic_shuffle_off',
        label: 'Shuffle',
        name: _shuffleAction,
      ),
      MediaControl.custom(
        androidIcon: switch (state.repeat) {
          RepeatMode.off => 'drawable/ic_repeat_off',
          RepeatMode.all => 'drawable/ic_repeat_all',
          RepeatMode.one => 'drawable/ic_repeat_one',
        },
        label: 'Repeat',
        name: _repeatAction,
      ),
    ],
    androidCompactActionIndices: const [0, 1, 3],
    systemActions: const {
      MediaAction.seek,
      MediaAction.setShuffleMode,
      MediaAction.setRepeatMode,
    },
    shuffleMode: state.shuffle
        ? AudioServiceShuffleMode.all
        : AudioServiceShuffleMode.none,
    repeatMode: switch (state.repeat) {
      RepeatMode.off => AudioServiceRepeatMode.none,
      RepeatMode.all => AudioServiceRepeatMode.all,
      RepeatMode.one => AudioServiceRepeatMode.one,
    },
    processingState: switch (state.status) {
      PlayerStatus.idle || PlayerStatus.stopped => AudioProcessingState.idle,
      PlayerStatus.loading => AudioProcessingState.loading,
      PlayerStatus.ready => AudioProcessingState.ready,
    },
    playing: state.playing,
    updatePosition: state.position,
    updateTime: _clock(),
    queueIndex: state.currentIndex,
  );

  bool _differs(PlaybackState shown, PlaybackState next) {
    if (shown.playing != next.playing ||
        shown.processingState != next.processingState ||
        shown.queueIndex != next.queueIndex ||
        shown.shuffleMode != next.shuffleMode ||
        shown.repeatMode != next.repeatMode) {
      return true;
    }
    final elapsed = shown.playing
        ? next.updateTime.difference(shown.updateTime)
        : Duration.zero;
    final expected = shown.updatePosition + elapsed;
    return (next.updatePosition - expected).abs() > _positionTolerance;
  }
}
