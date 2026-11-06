import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/data/db/drift_listening_store.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/listening_store.dart';
import 'package:tuneshell/domain/playback/services/play_counter.dart';

final listeningStoreProvider = Provider<ListeningStore>(
  (ref) => DriftListeningStore(ref.watch(libraryDatabaseProvider)),
);

/// The favorites (BR-014). A change shows at once and is written behind it;
/// a failed write puts the mark back as it was and is logged.
///
/// @implements BR-014
/// @implements FR-031
class FavoriteTracks extends Notifier<Set<Track>> {
  @override
  Set<Track> build() {
    unawaited(_load());
    return const {};
  }

  Future<void> _load() async {
    try {
      final stored = await ref.read(listeningStoreProvider).favorites();
      // A mark made while the read was running stays.
      state = {...stored, ...state};
    } on Object catch (error) {
      debugPrint('favorites: cannot read: ${error.runtimeType}');
    }
  }

  Future<void> toggle(Track track) async {
    final marked = !state.contains(track);
    state = marked ? {...state, track} : ({...state}..remove(track));
    try {
      await ref
          .read(listeningStoreProvider)
          .setFavorite(track, favorite: marked);
    } on Object catch (error) {
      debugPrint('favorites: cannot write: ${error.runtimeType}');
      if (!ref.mounted) return;
      state = marked ? ({...state}..remove(track)) : {...state, track};
    }
  }
}

final favoriteTracksProvider = NotifierProvider<FavoriteTracks, Set<Track>>(
  FavoriteTracks.new,
);

/// The tracks listened to, the latest first (BR-014, rule 8). Read again
/// after each recorded listen and after the history is cleared.
class RecentTracks extends Notifier<List<Track>> {
  @override
  List<Track> build() {
    unawaited(refresh());
    return const [];
  }

  Future<void> refresh() async {
    try {
      final recent = await ref.read(listeningStoreProvider).recent();
      if (ref.mounted) state = recent;
    } on Object catch (error) {
      debugPrint('history: cannot read: ${error.runtimeType}');
    }
  }

  /// FR-031.6: forgets every listen; the favorites stay.
  Future<void> clear() async {
    try {
      await ref.read(listeningStoreProvider).clearHistory();
    } on Object catch (error) {
      debugPrint('history: cannot clear: ${error.runtimeType}');
    }
    await refresh();
  }
}

final recentTracksProvider = NotifierProvider<RecentTracks, List<Track>>(
  RecentTracks.new,
);

/// Counts the listens of the controller (BR-014). Started by
/// `startListenCounting`; whether it records follows the setting (FR-031.5).
final playCounterProvider = Provider<PlayCounter>((ref) {
  final counter = PlayCounter(
    controller: ref.watch(playerControllerProvider),
    store: ref.watch(listeningStoreProvider),
    enabled: ref.read(appSettingsProvider).recordHistory,
    onRecorded: () =>
        unawaited(ref.read(recentTracksProvider.notifier).refresh()),
    onError: (error) =>
        debugPrint('history: cannot record: ${error.runtimeType}'),
  );
  ref.onDispose(() => unawaited(counter.dispose()));
  return counter;
});
