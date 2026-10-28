import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/ports/media_tree.dart';
import 'package:tuneshell/domain/playback/services/library_media_tree.dart';
import 'package:tuneshell/features/browse/browse_providers.dart';
import 'package:tuneshell/features/browse/library_groups.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';
import 'package:tuneshell/features/library/removable_controller.dart';
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

/// The last tree made and what it was made from: a car asks again for every
/// folder it opens, and a tree of a big library is not cheap to build.
final _memo = Expando<_Made>();

class _Made {
  const new(this.inputs, this.tree);
  final List<Object?> inputs;
  final MediaTree tree;
}

/// The disks are read once per process: with no screen open nobody did, and
/// every track would look present.
final _disksRead = Expando<Future<void>>();

/// The media tree a car browses, made from the library as it is now
/// (BR-013, ADR-020). Waits for the first read of the library: a car can ask
/// before the screens ever did. [keepMediaTreeReadable] must have been called.
///
/// @implements FR-029
Future<MediaTree> currentMediaTree(ProviderContainer container) async {
  await container.read(listedTracksProvider.future);
  await (_disksRead[container] ??= container
      .read(removableControllerProvider.notifier)
      .load());
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
  final unavailable = container.read(unavailableDiskIdsProvider);
  final current = now == null ? null : container.read(trackIndexProvider)[now];
  final inputs = <Object?>[
    groups,
    sorted,
    unavailable.toList()..sort((a, b) => a.value.compareTo(b.value)),
    current,
    l10n.localeName,
  ];
  final made = _memo[container];
  if (made != null && _same(made.inputs, inputs)) return made.tree;
  final tree = LibraryMediaTree(
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
    unavailable: unavailable,
    current: current,
  );
  _memo[container] = _Made(inputs, tree);
  return tree;
}

bool _same(List<Object?> a, List<Object?> b) {
  for (var i = 0; i < a.length; i++) {
    final x = a[i];
    final y = b[i];
    if (x is List<DiskId> && y is List<DiskId>) {
      if (x.length != y.length) return false;
      for (var j = 0; j < x.length; j++) {
        if (x[j] != y[j]) return false;
      }
    } else if (!identical(x, y) && x != y) {
      return false;
    }
  }
  return true;
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
