import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/listening_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/features/player/player_session.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';

/// What the menu of a track, an album or an artist can do (FR-019.1,
/// FR-022.7).
enum MenuAction { next, last, favorite }

/// The menu of a track in the list: play it next, or add it to the end of the
/// queue (FR-019).
///
/// @implements FR-019
Future<void> showTrackMenu(
  BuildContext context,
  WidgetRef ref,
  LibraryTrack track,
) => showTracksMenu(
  context,
  ref,
  name: track.displayTitle,
  tracks: [track],
  favorite: true,
);

/// The same menu for a group of tracks, such as an album or an artist, in
/// the order given (FR-022.7). [name] is what the confirmation names.
///
/// @implements FR-022
Future<void> showTracksMenu(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  required List<LibraryTrack> tracks,
  QueueOrigin? origin,
  bool favorite = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final marked =
      favorite && ref.read(favoriteTracksProvider).contains(tracks.first.track);
  final choice = await showModalBottomSheet<MenuAction>(
    context: context,
    showDragHandle: true,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.playlist_play_rounded),
            title: Text(l10n.menuPlayNext),
            onTap: () => Navigator.of(context).pop(MenuAction.next),
          ),
          ListTile(
            leading: const Icon(Icons.queue_music_rounded),
            title: Text(l10n.menuAddToQueue),
            onTap: () => Navigator.of(context).pop(MenuAction.last),
          ),
          // FR-031.4: only the menu of one track, not of an album or artist.
          if (favorite)
            ListTile(
              leading: Icon(
                marked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              ),
              title: Text(marked ? l10n.favoriteRemove : l10n.favoriteAdd),
              onTap: () => Navigator.of(context).pop(MenuAction.favorite),
            ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  await applyTracksAction(
    context,
    ref,
    name: name,
    tracks: tracks,
    action: choice,
    origin: origin,
  );
}

/// The two menu actions as custom actions of a row, for TalkBack
/// (FR-019.1, FR-022.7).
Map<CustomSemanticsAction, VoidCallback> menuSemanticsActions(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  required List<LibraryTrack> tracks,
  QueueOrigin? origin,
}) {
  final l10n = AppLocalizations.of(context);
  return {
    for (final action in MenuAction.values.where(
      (a) => a != MenuAction.favorite,
    ))
      CustomSemanticsAction(
        label: action == MenuAction.next
            ? l10n.menuPlayNext
            : l10n.menuAddToQueue,
      ): () => unawaited(
        applyTracksAction(
          context,
          ref,
          name: name,
          tracks: tracks,
          action: action,
          origin: origin,
        ),
      ),
  };
}

/// Does [action] on one track and confirms it in a snack bar. Also the
/// target of the custom actions TalkBack offers on a row (FR-019.1).
Future<void> applyTrackAction(
  BuildContext context,
  WidgetRef ref,
  LibraryTrack track,
  MenuAction action,
) => applyTracksAction(
  context,
  ref,
  name: track.displayTitle,
  tracks: [track],
  action: action,
);

/// Puts [tracks], in their order, after the current track or at the end of
/// the queue, and confirms it naming [name] (BR-009, rule 11).
Future<void> applyTracksAction(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  required List<LibraryTrack> tracks,
  required MenuAction action,
  QueueOrigin? origin,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final player = ref.read(playerControllerProvider);
  final list = [for (final t in tracks) t.track];
  if (action == MenuAction.favorite) {
    final notifier = ref.read(favoriteTracksProvider.notifier);
    final marked = ref.read(favoriteTracksProvider).contains(list.first);
    unawaited(notifier.toggle(list.first));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            marked ? l10n.favoriteRemoved(name) : l10n.favoriteAdded(name),
          ),
        ),
      );
    return;
  }
  // On an empty queue the tracks start a queue of their own: it comes from
  // [origin], an album or an artist, or from nowhere (FR-022.8).
  if (player.state.queue.isEmpty) {
    final holder = ref.read(queueOriginProvider.notifier);
    if (origin == null) {
      holder.clear();
    } else {
      holder.set(origin);
    }
  }
  switch (action) {
    case MenuAction.next:
      unawaited(player.playNext(list));
    case MenuAction.last:
      unawaited(player.enqueue(list));
    case MenuAction.favorite:
      break;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          action == MenuAction.next
              ? l10n.menuPlayNextDone(name)
              : l10n.menuAddedDone(name),
        ),
      ),
    );
}
