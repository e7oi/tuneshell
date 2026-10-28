import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';
import 'package:tuneshell/features/library/library_search.dart';

/// The three views that have a search (FR-027).
enum SearchView { tracks, albums, artists }

/// The search of one view: null when it is closed, otherwise the text typed,
/// possibly empty. Kept while the user changes tab or opens a detail, dropped
/// when the search is closed (FR-027, ADR-018).
class SearchText extends Notifier<String?> {
  @override
  String? build() => null;

  void open() => state ??= '';

  // ignore: use_setters_to_change_properties, the notifier API is a method
  void update(String text) => state = text;

  void close() => state = null;
}

final _tracksSearch = NotifierProvider<SearchText, String?>(SearchText.new);
final _albumsSearch = NotifierProvider<SearchText, String?>(SearchText.new);
final _artistsSearch = NotifierProvider<SearchText, String?>(SearchText.new);

/// The provider of the search of [view].
NotifierProvider<SearchText, String?> searchTextProvider(SearchView view) =>
    switch (view) {
      SearchView.tracks => _tracksSearch,
      SearchView.albums => _albumsSearch,
      SearchView.artists => _artistsSearch,
    };

/// The search index of the tracks, rebuilt when the listed tracks change and
/// not at each keystroke.
final trackSearchIndexProvider = Provider<SearchIndex<LibraryTrack>?>((ref) {
  final tracks = ref.watch(sortedTracksProvider);
  return tracks == null ? null : SearchIndex(tracks, trackTexts);
});

/// The tracks that match the search, in display order; null while no search
/// is open (BR-011).
final searchedTracksProvider = Provider<List<LibraryTrack>?>((ref) {
  final text = ref.watch(searchTextProvider(SearchView.tracks));
  final index = ref.watch(trackSearchIndexProvider);
  if (text == null || index == null) return null;
  return index.filter(SearchQuery.of(text));
});
