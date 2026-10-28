import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/features/browse/artist_list_model.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';
import 'package:tuneshell/features/library/library_search.dart';
import 'package:tuneshell/features/library/library_search_state.dart';

/// The ids of the unavailable disks as one string: a watcher that compares
/// it is woken only when the set really changes.
final _unavailableKeyProvider = Provider<String>((ref) {
  final ids = [
    for (final id in ref.watch(unavailableDisksProvider).keys) id.value,
  ]..sort();
  return ids.join('\u0000');
});

/// The unavailable disks, as a set.
final unavailableDiskIdsProvider = Provider<Set<DiskId>>((ref) {
  final key = ref.watch(_unavailableKeyProvider);
  return {
    if (key.isNotEmpty)
      for (final id in key.split('\u0000')) DiskId(id),
  };
});

/// The albums and the artists, recomputed when the listed tracks (at most
/// twice a second) or the unavailable disks change; null until the tracks are
/// read (BR-010, rule 10, ADR-016).
final libraryGroupsProvider = Provider<LibraryGroups?>((ref) {
  final tracks = ref.watch(listedTracksProvider).value;
  if (tracks == null) return null;
  return LibraryGroups.build(
    tracks: tracks,
    unavailableDisks: ref.watch(unavailableDiskIdsProvider),
  );
});

/// A disk by identifier, for names and marks.
final disksByIdProvider = Provider<Map<DiskId, Disk>>((ref) {
  final disks = ref.watch(libraryDisksProvider).value ?? const <Disk>[];
  return {for (final disk in disks) disk.id: disk};
});

/// The Artists list with its letter headers, made once per change of the
/// groups, not at each build of the view.
final artistListModelProvider = Provider<ArtistListModel?>((ref) {
  final groups = ref.watch(libraryGroupsProvider);
  return groups == null ? null : ArtistListModel.build(groups.artists);
});

/// The search indexes of the albums and of the artists, rebuilt when the
/// groups change and not at each keystroke; built only once a search is open.
final _albumIndexProvider = Provider<SearchIndex<AlbumGroup>?>((ref) {
  if (ref.watch(searchTextProvider(SearchView.albums)) == null) return null;
  final groups = ref.watch(libraryGroupsProvider);
  return groups == null ? null : SearchIndex(groups.albums, albumTexts);
});

final _artistIndexProvider = Provider<SearchIndex<ArtistGroup>?>((ref) {
  if (ref.watch(searchTextProvider(SearchView.artists)) == null) return null;
  final groups = ref.watch(libraryGroupsProvider);
  return groups == null ? null : SearchIndex(groups.artists, artistTexts);
});

/// The albums that match the search; null while it is closed (BR-011).
final searchedAlbumsProvider = Provider<List<AlbumGroup>?>((ref) {
  final text = ref.watch(searchTextProvider(SearchView.albums));
  final index = ref.watch(_albumIndexProvider);
  return text == null || index == null
      ? null
      : index.filter(SearchQuery.of(text));
});

/// The artists that match the search; null while it is closed (BR-011).
final searchedArtistsProvider = Provider<List<ArtistGroup>?>((ref) {
  final text = ref.watch(searchTextProvider(SearchView.artists));
  final index = ref.watch(_artistIndexProvider);
  return text == null || index == null
      ? null
      : index.filter(SearchQuery.of(text));
});

/// The Artists list of the search results.
final searchedArtistListModelProvider = Provider<ArtistListModel?>((ref) {
  final found = ref.watch(searchedArtistsProvider);
  return found == null ? null : ArtistListModel.build(found);
});
