import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/playback/ports/media_tree.dart';
import 'package:tuneshell/domain/playback/services/library_media_tree.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/widgets/alphabet_index.dart';

/// Keeps the library read and grouped for as long as the process lives: a
/// provider nobody listens to is paused, and a car can browse with no screen
/// open (ADR-020).
void keepMediaTreeReadable(ProviderContainer container) {
  container
    ..listen(libraryGroupsProvider, (_, _) {})
    ..listen(sortedTracksProvider, (_, _) {});
}

/// The media tree a car browses, made from the library as it is now
/// (BR-013, ADR-020). Waits for the first read of the library: a car can ask
/// before the screens ever did. [keepMediaTreeReadable] must have been called.
///
/// @implements FR-029
Future<MediaTree> currentMediaTree(ProviderContainer container) async {
  await container.read(listedTracksProvider.future);
  final groups = container.read(libraryGroupsProvider);
  final sorted = container.read(sortedTracksProvider) ?? const [];
  final controller = container.read(playerControllerProvider);
  final now = controller.state.currentTrack;
  final l10n = lookupAppLocalizations(
    basicLocaleListResolution(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    ),
  );
  return LibraryMediaTree(
    albums: [for (final a in groups?.albums ?? const <AlbumGroup>[]) _album(a)],
    artists: [
      for (final a in groups?.artists ?? const <ArtistGroup>[])
        MediaArtist(
          key: a.key,
          name: a.name,
          unknown: a.unknown,
          albums: [for (final album in a.albums) _album(album)],
        ),
    ],
    tracks: sorted,
    labels: MediaTreeLabels(
      albums: l10n.navAlbums,
      artists: l10n.navArtists,
      tracks: l10n.navTracks,
      unknownAlbum: l10n.albumUnknown,
      unknownArtist: l10n.trackUnknownArtist,
      empty: l10n.carEmptyLibrary,
    ),
    fold: foldText,
    unavailable: container.read(unavailableDiskIdsProvider),
    current: now == null ? null : container.read(trackIndexProvider)[now],
  );
}

MediaAlbum _album(AlbumGroup a) => MediaAlbum(
  key: a.key,
  title: a.title,
  artist: a.artist,
  tracks: a.tracks,
  unknownAlbum: a.unknownAlbum,
  unknownArtist: a.unknownArtist,
  artwork: a.artwork,
);
