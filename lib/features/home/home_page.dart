import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/browse_request_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/features/browse/albums_view.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/browse/browse_widgets.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/features/home/home_providers.dart';
import 'package:tuneshell/features/player/clock.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/features/player/track_menu.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/progress_banner.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

/// The Home tab: three tracks and two albums not played for a while, and a
/// button to draw others (BR-016). What was playing last is the mini player's
/// business, not this view's.
///
/// @implements FR-033
/// @implements UC-014
class HomePage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final content = ref.watch(homeContentProvider);
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(canShuffle: content != null && !content.isEmpty),
          Expanded(
            child: content == null
                ? Align(
                    alignment: Alignment.topCenter,
                    child: ProgressBanner(label: l10n.homeLoading),
                  )
                : content.isEmpty
                ? const _Empty()
                : LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth >= TsSize.compactMax
                        ? _Wide(content: content)
                        : _Narrow(content: content),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const new({required this.canShuffle});

  final bool canShuffle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TsSpace.screenMargin,
        vertical: TsSpace.s,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                l10n.homeTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          if (canShuffle)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: TsSize.touchTarget),
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    unawaited(ref.read(homeDrawProvider.notifier).reshuffle()),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.homeShuffle),
              ),
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TsSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note_rounded,
              size: TsSize.heroIcon,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: TsSpace.m),
            Text(
              l10n.homeEmptyTitle,
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TsSpace.s),
            Text(
              l10n.homeEmptyBody,
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Narrow extends StatelessWidget {
  const new({required this.content});

  final HomeContent content;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: TsSize.listBottomInset),
    children: [
      if (content.tracks.isNotEmpty) _Tracks(tracks: content.tracks),
      if (content.albums.isNotEmpty) _Albums(content: content),
    ],
  );
}

class _Wide extends StatelessWidget {
  const new({required this.content});

  final HomeContent content;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.only(bottom: TsSize.listBottomInset),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.tracks.isNotEmpty)
          SizedBox(
            width: TsSize.homeTrackColumn,
            child: _Tracks(tracks: content.tracks),
          ),
        if (content.albums.isNotEmpty)
          Expanded(child: _Albums(content: content)),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const new(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TsSpace.screenMargin,
      TsSpace.l,
      TsSpace.screenMargin,
      TsSpace.xs,
    ),
    child: Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}

class _Tracks extends ConsumerWidget {
  const new({required this.tracks});

  final List<LibraryTrack> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(l10n.homeTracksTitle),
        for (final track in tracks) _TrackRow(track: track),
      ],
    );
  }
}

class _TrackRow extends ConsumerWidget {
  const new({required this.track});

  final LibraryTrack track;

  Future<void> _play(WidgetRef ref) async {
    final groups = ref.read(libraryGroupsProvider);
    if (groups == null) return;
    // FR-033.4: the queue is the whole library, by artist, album and track
    // number, placed on the track chosen.
    final queue = groups.tracksByArtist;
    final start = queue.indexWhere((t) => t.track == track.track);
    if (start < 0) return;
    final player = ref.read(playerControllerProvider);
    ref.read(queueOriginProvider.notifier).set(const HomeOrigin());
    await player.setQueue([for (final t in queue) t.track], startIndex: start);
    await player.play();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groups = ref.watch(libraryGroupsProvider);
    final album = groups?.albumOf(track);
    final artist = track.info.artist ?? l10n.trackUnknownArtist;
    final line = [artist, ?album?.title].join(' · ');
    final duration = track.info.duration;
    final artworkId = track.artwork;
    return TrackTile(
      title: track.displayTitle,
      artist: line,
      duration: duration == null ? null : formatClock(duration),
      artwork: artworkId == null
          ? null
          : ref.watch(artworkImageProvider(artworkId)),
      semanticsLabel: [
        track.displayTitle,
        line,
        if (duration != null) formatClock(duration),
      ].join(', '),
      onTap: () => unawaited(_play(ref)),
      onLongPress: () => unawaited(showTrackMenu(context, ref, track)),
    );
  }
}

class _Albums extends ConsumerWidget {
  const new({required this.content});

  final HomeContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = TsColors.of(context);
    final disks = ref.watch(disksByIdProvider);
    final scale = math.max(1, MediaQuery.textScalerOf(context).scale(1));
    const margin = TsSpace.screenMargin;
    const gap = TsSpace.m;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(l10n.homeAlbumsTitle),
        LayoutBuilder(
          builder: (context, constraints) {
            final card = (constraints.maxWidth - 2 * margin - gap) / 2;
            final extent =
                card + TsSpace.s + TsSize.albumCardTextHeight * scale;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: margin),
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final album in content.albums)
                    SizedBox(
                      width: card,
                      height: extent,
                      child: _AlbumCard(
                        album: album,
                        size: card,
                        marks: albumMarks(album, disks, colors),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AlbumCard extends ConsumerWidget {
  const new({required this.album, required this.size, required this.marks});

  final AlbumGroup album;
  final double size;
  final List<Widget> marks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = album.artwork;
    return AlbumGridCard(
      album: album,
      size: size,
      marks: marks,
      diskName: null,
      artwork: id == null ? null : ref.watch(artworkImageProvider(id)),
      // ADR-022: the detail opens in the Albums tab.
      onTap: () => ref
          .read(browseRequestProvider.notifier)
          .open(BrowseTab.albums, album.key),
      onLongPress: () => unawaited(
        showTracksMenu(
          context,
          ref,
          name: albumName(l10n, album),
          tracks: album.tracks,
          origin: albumOrigin(album),
        ),
      ),
      customActions: menuSemanticsActions(
        context,
        ref,
        name: albumName(l10n, album),
        tracks: album.tracks,
        origin: albumOrigin(album),
      ),
    );
  }
}
