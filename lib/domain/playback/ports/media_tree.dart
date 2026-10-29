import 'package:tuneshell/domain/playback/model/media_node.dart';

/// The library as a car browses it: a tree of folders and tracks, and what
/// choosing a track does (BR-013). A snapshot: it is read, never changed.
///
/// Two implementations: the library and, in the tests, the same logic over
/// made-up tracks.
///
/// @implements BR-013
abstract interface class MediaTree {
  /// The root a browser asks for first.
  static const rootId = 'root';

  /// The root a browser asks for to offer "continue where you were".
  static const recentId = 'recent';

  /// The entries under [parentId]; empty for an unknown or empty parent.
  List<MediaNode> children(String parentId);

  /// The entry [id], or null when it is not in the tree.
  MediaNode? node(String id);

  /// What playing [id] does, or null when it cannot be played.
  BrowseAction? action(String id);
}
