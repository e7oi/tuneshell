import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/track.dart';

/// One entry of the media tree a car shows (BR-013): a folder to open or a
/// track to play.
///
/// @implements BR-013
@immutable
final class MediaNode {
  const new({
    required this.id,
    required this.title,
    this.subtitle,
    this.artwork,
    this.playable = false,
    this.browsable = false,
    this.group,
  });

  /// Stable from one launch to the next (BR-013, rule 7); never shown.
  final String id;
  final String title;
  final String? subtitle;

  /// Identifier of the cover, once read (FR-007.6).
  final String? artwork;
  final bool playable;
  final bool browsable;

  /// The title of the group this entry belongs to in a list of results:
  /// entries of one group follow each other and a car shows the title above
  /// them (BR-015, rule 4). Null in the lists of the tree.
  final String? group;
}

/// What choosing a playable [MediaNode] does.
@immutable
sealed class BrowseAction {
  const new();
}

/// Plays the queue the controller already holds (BR-013, rule 2).
final class ResumeAction extends BrowseAction {
  const new();
}

/// Makes [queue] the queue and plays from [startIndex] (BR-013, rule 5).
final class PlayTracks extends BrowseAction {
  const new({required this.queue, required this.startIndex});

  final List<Track> queue;
  final int startIndex;
}
