import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/listening_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/services/rediscovery.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/features/library/removable_controller.dart';
import 'package:tuneshell/features/player/player_session.dart';

/// The clock and the random source of the draw; replaced in tests.
final homeNowProvider = Provider<DateTime Function()>((_) => DateTime.now);
final homeRandomProvider = Provider<Random>((_) => Random());

/// The tracks and the albums drawn to rediscover (BR-016), kept in memory for
/// the life of the application: the draw is made once the library is known,
/// and again only when the user asks (BR-016, rule 6). Null until the first
/// draw is made.
///
/// @implements BR-016
/// @decision ADR-024
class HomeDraw extends Notifier<RediscoverySelection?> {
  bool _drawing = false;

  @override
  RediscoverySelection? build() {
    ref.listen(libraryGroupsProvider, (_, groups) {
      if (groups == null) return;
      // A first scan hands the library over in pieces: an empty draw is
      // made again once there is something to draw from.
      final drawn = state;
      if (drawn == null || (drawn.isEmpty && groups.albums.isNotEmpty)) {
        unawaited(_draw());
      }
    }, fireImmediately: true);
    // The draw can be made before the session is restored or the removable
    // disks are read; each of these two facts is then taken in once, as the
    // draw is not allowed to hold what it would have left out (BR-016 rules
    // 2 and 3). Later changes follow rule 7: no replacement.
    ref
      ..listen(playerStateProvider.select((s) => s.value?.currentTrack), (
        previous,
        track,
      ) {
        if (previous == null && track != null) _refit();
      })
      ..listen(removableControllerProvider.select((s) => s.disks.isEmpty), (
        previous,
        empty,
      ) {
        if (previous ?? false) if (!empty) _refit();
      });
    return null;
  }

  /// Draws again when something drawn is not eligible after all.
  void _refit() {
    final drawn = state;
    final groups = ref.read(libraryGroupsProvider);
    if (drawn == null || groups == null) return;
    final unavailable = ref.read(unavailableDiskIdsProvider);
    final current = ref.read(playerStateProvider).value?.currentTrack;
    final index = ref.read(trackIndexProvider);
    final albums = {for (final album in groups.albums) album.key: album};
    final stale =
        drawn.tracks.any((t) {
          final found = index[t];
          return t == current ||
              found == null ||
              unavailable.contains(found.disk);
        }) ||
        drawn.albumKeys.any((key) {
          final album = albums[key];
          return album == null ||
              !album.available ||
              (current != null && album.tracks.any((t) => t.track == current));
        });
    if (stale) unawaited(_draw());
  }

  /// "More suggestions": a new draw that leaves out what is shown while other
  /// elements remain (FR-033.3).
  Future<void> reshuffle() => _draw(avoid: state);

  Future<void> _draw({RediscoverySelection? avoid}) async {
    if (_drawing) return;
    _drawing = true;
    try {
      final store = ref.read(listeningStoreProvider);
      var lastPlayed = const <Track, DateTime>{};
      var favorites = const <Track>{};
      try {
        lastPlayed = await store.lastPlayedAt();
        favorites = await store.favorites();
      } on Object catch (error) {
        // Without the history, everything counts as never listened to.
        debugPrint('home: cannot read the history: ${error.runtimeType}');
      }
      if (!ref.mounted) return;
      final groups = ref.read(libraryGroupsProvider);
      if (groups == null) return;
      final unavailable = ref.read(unavailableDiskIdsProvider);
      state = const Rediscovery().pick(
        items: [
          for (final album in groups.albums)
            for (final track in album.tracks)
              RediscoveryItem(
                track: track.track,
                albumKey: album.unknownAlbum ? null : album.key,
                available: !unavailable.contains(track.disk),
              ),
        ],
        lastPlayed: lastPlayed,
        favorites: favorites,
        now: ref.read(homeNowProvider)(),
        random: ref.read(homeRandomProvider),
        current: ref.read(playerStateProvider).value?.currentTrack,
        avoidTracks: avoid?.tracks.toSet() ?? const {},
        avoidAlbums: avoid?.albumKeys.toSet() ?? const {},
      );
    } finally {
      _drawing = false;
    }
  }
}

final homeDrawProvider = NotifierProvider<HomeDraw, RediscoverySelection?>(
  HomeDraw.new,
);

/// What the Home tab shows: the draw, without what left the library or lost
/// its disk since (BR-016, rule 7).
@immutable
final class HomeContent {
  const new({required this.tracks, required this.albums});

  final List<LibraryTrack> tracks;
  final List<AlbumGroup> albums;

  bool get isEmpty => tracks.isEmpty && albums.isEmpty;
}

/// Null while the library or the first draw is not ready (FR-033.2).
final homeContentProvider = Provider<HomeContent?>((ref) {
  final groups = ref.watch(libraryGroupsProvider);
  final drawn = ref.watch(homeDrawProvider);
  if (groups == null || drawn == null) return null;
  final unavailable = ref.watch(unavailableDiskIdsProvider);
  final index = ref.watch(trackIndexProvider);
  final albums = {for (final album in groups.albums) album.key: album};
  return HomeContent(
    tracks: [
      for (final track in drawn.tracks)
        if (index[track] case final found?
            when !unavailable.contains(found.disk))
          found,
    ],
    albums: [
      for (final key in drawn.albumKeys)
        if (albums[key] case final album? when album.available) album,
    ],
  );
});
