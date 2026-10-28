import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/gesture_providers.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/features/browse/album_detail_page.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/browse/browse_widgets.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/features/library/library_controller.dart';
import 'package:tuneshell/features/library/library_search.dart';
import 'package:tuneshell/features/library/library_search_state.dart';
import 'package:tuneshell/features/library/search_widgets.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/features/player/track_menu.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/album_card.dart';
import 'package:tuneshell/ui/widgets/alphabet_scroller.dart';

/// The Albums tab: a grid of covers sorted by album artist, with the alphabet
/// index (FR-020).
///
/// @implements FR-020
class AlbumsView extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AlbumsView> createState() => _AlbumsViewState();
}

class _AlbumsViewState extends ConsumerState<AlbumsView> {
  final ScrollController _scroll = ScrollController();
  late final HandleExclusion _exclusion = HandleExclusion(
    ref.read(gestureRegionsProvider),
    'albums',
  );

  /// Set by the last layout: the jump to a letter needs the row height.
  int _columns = 2;
  double _rowExtent = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _exclusion.read(context);
  }

  @override
  void dispose() {
    _exclusion.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toLetter(LibraryGroups groups, String letter) {
    final index = groups.albumFirstIndex[letter];
    if (index == null || !_scroll.hasClients) return;
    _scroll.jumpTo(
      ((index ~/ _columns) * _rowExtent).clamp(
        0,
        _scroll.position.maxScrollExtent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groups = ref.watch(libraryGroupsProvider);
    final query = ref.watch(searchTextProvider(SearchView.albums));
    final found = ref.watch(searchedAlbumsProvider);
    final shown = groups == null || groups.albums.isEmpty ? null : found;
    final search = ref.read(searchTextProvider(SearchView.albums).notifier);
    // Back closes the search before it leaves the tab (FR-027).
    return PopScope(
      canPop: query == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) search.close();
      },
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrowseHeader(
              view: SearchView.albums,
              title: l10n.navAlbums,
              canSearch: groups != null && groups.albums.isNotEmpty,
              count: groups == null
                  ? ''
                  : shown != null
                  ? l10n.searchResults(shown.length)
                  : l10n.albumsCount(groups.albums.length),
              sort: groups == null || groups.albums.isEmpty
                  ? null
                  : l10n.albumsSort,
            ),
            Expanded(
              child: groups == null
                  ? const Center(child: CircularProgressIndicator())
                  : groups.albums.isEmpty
                  ? BrowseEmpty(title: l10n.groupsEmptyAlbums)
                  : shown != null &&
                        shown.isEmpty &&
                        !SearchQuery.of(query ?? '').isEmpty
                  ? SearchNoResults(query: query!, onClear: search.close)
                  : _grid(context, groups, shown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(
    BuildContext context,
    LibraryGroups groups,
    List<AlbumGroup>? results,
  ) {
    final albums = results ?? groups.albums;
    final l10n = AppLocalizations.of(context);
    final colors = TsColors.of(context);
    final disks = ref.watch(disksByIdProvider);
    final unavailable = ref.watch(unavailableDiskIdsProvider);
    final scale = math.max(1, MediaQuery.textScalerOf(context).scale(1));
    return LayoutBuilder(
      builder: (context, constraints) {
        const margin = TsSpace.screenMargin;
        const gap = TsSpace.m;
        final usable = constraints.maxWidth - 2 * margin;
        _columns = math.max(
          2,
          math.min(
            TsSize.albumColumnsMax,
            ((usable + gap) / (TsSize.albumCardMinWidth + gap)).floor(),
          ),
        );
        final card = (usable - (_columns - 1) * gap) / _columns;
        final extent = card + TsSpace.s + TsSize.albumCardTextHeight * scale;
        _rowExtent = extent + gap;
        final grid = RefreshIndicator(
          onRefresh: () =>
              ref.read(libraryControllerProvider.notifier).refresh(),
          child: GridView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              margin,
              TsSpace.xs,
              margin,
              TsSize.listBottomInset,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              mainAxisExtent: extent,
            ),
            itemCount: albums.length,
            itemBuilder: (context, i) {
              final album = albums[i];
              return _AlbumGridCard(
                album: album,
                size: card,
                marks: albumMarks(album, disks, colors),
                diskName: album.available
                    ? null
                    : absentDiskName(album.disks, unavailable, disks, l10n),
              );
            },
          ),
        );
        if (results != null) return grid;
        return AlphabetScroller(
          letters: groups.albumLetters,
          alignStart: ref.watch(
            appSettingsProvider.select((s) => s.indexOnLeft),
          ),
          itemCount: groups.albums.length,
          onLetterSelected: (letter) => _toLetter(groups, letter),
          countLabel: l10n.albumsCount,
          letterSemantics: (letter, count) =>
              l10n.indexLetterItems(letter, l10n.albumsCount(count)),
          gridTitle: l10n.indexGoToLetter,
          onHandleRect: _exclusion.handle,
          child: grid,
        );
      },
    );
  }
}

/// An album of the grid, or of an artist's carousel.
class AlbumGridCard extends StatelessWidget {
  const new({
    required this.album,
    required this.size,
    required this.marks,
    required this.diskName,
    required this.onTap,
    required this.onLongPress,
    this.customActions,
    this.artwork,
    this.showArtist = true,
    super.key,
  });

  final AlbumGroup album;
  final double size;
  final List<Widget> marks;
  final ImageProvider? artwork;

  /// The absent disk to name when the album is unavailable.
  final String? diskName;

  /// The artist is the subtitle; the carousel of an artist shows the year.
  final bool showArtist;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Map<CustomSemanticsAction, VoidCallback>? customActions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = album.unknownAlbum ? l10n.albumUnknown : album.title;
    final artist = album.unknownArtist ? l10n.trackUnknownArtist : album.artist;
    final subtitle = [
      if (showArtist) artist,
      ?album.year?.toString(),
    ].join(' · ');
    final detail = l10n.groupTracks(album.trackCount);
    final label = [
      title,
      subtitle,
      detail,
    ].where((t) => t.isNotEmpty).join(', ');
    return AlbumCard(
      title: title,
      subtitle: subtitle,
      detail: detail,
      size: size,
      artwork: artwork,
      marks: showArtist ? marks : const [],
      unavailable: !album.available,
      semanticsLabel: diskName == null
          ? label
          : l10n.albumNotConnected(label, diskName!),
      onTap: onTap,
      onLongPress: onLongPress,
      customActions: customActions,
    );
  }
}

class _AlbumGridCard extends ConsumerWidget {
  const new({
    required this.album,
    required this.size,
    required this.marks,
    required this.diskName,
  });

  final AlbumGroup album;
  final double size;
  final List<Widget> marks;
  final String? diskName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = album.artwork;
    return AlbumGridCard(
      album: album,
      size: size,
      marks: marks,
      diskName: diskName,
      artwork: id == null ? null : ref.watch(artworkImageProvider(id)),
      onTap: () => unawaited(openAlbum(context, album.key)),
      onLongPress: () => unawaited(
        showTracksMenu(
          context,
          ref,
          name: albumName(AppLocalizations.of(context), album),
          tracks: album.tracks,
          origin: albumOrigin(album),
        ),
      ),
      customActions: menuSemanticsActions(
        context,
        ref,
        name: albumName(AppLocalizations.of(context), album),
        tracks: album.tracks,
        origin: albumOrigin(album),
      ),
    );
  }
}

/// What the confirmations and the origin call an album.
String albumName(AppLocalizations l10n, AlbumGroup album) =>
    album.unknownAlbum ? l10n.albumUnknown : album.title;

/// Where the queue of an album says it comes from (FR-022.6).
QueueOrigin albumOrigin(AlbumGroup album) => AlbumOrigin(album.title);
