import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/media_node.dart';
import 'package:tuneshell/domain/playback/ports/media_tree.dart';

/// An album as the tree needs it (BR-010).
@immutable
final class MediaAlbum {
  const new({
    required this.key,
    required this.title,
    required this.artist,
    required this.tracks,
    this.unknownAlbum = false,
    this.unknownArtist = false,
    this.artwork,
  });

  /// The identity of the album, stable across launches.
  final String key;
  final String title;
  final String artist;
  final bool unknownAlbum;
  final bool unknownArtist;

  /// In the order of the album (BR-010, rule 6).
  final List<LibraryTrack> tracks;
  final String? artwork;
}

/// An artist as the tree needs it (BR-010).
@immutable
final class MediaArtist {
  const new({
    required this.key,
    required this.name,
    required this.albums,
    this.unknown = false,
  });

  final String key;
  final String name;
  final bool unknown;
  final List<MediaAlbum> albums;
}

/// The fixed texts of the tree, already in the language of the phone.
@immutable
final class MediaTreeLabels {
  const new({
    required this.albums,
    required this.artists,
    required this.tracks,
    required this.unknownAlbum,
    required this.unknownArtist,
    required this.empty,
    required this.currentAlbum,
    required this.currentArtist,
  });

  final String albums;
  final String artists;
  final String tracks;
  final String unknownAlbum;
  final String unknownArtist;

  /// The only entry of an empty library.
  final String empty;

  /// The folders of the album and of the artist of the current track
  /// (FR-032.7).
  final String currentAlbum;
  final String currentArtist;
}

/// The media tree of the library (BR-013): Albums, Artists and Tracks, long
/// lists cut by the first letters, tracks of an absent disk left out.
///
/// @implements BR-013
class LibraryMediaTree implements MediaTree {
  new({
    required this.albums,
    required this.artists,
    required this.tracks,
    required this.labels,
    required this._fold,
    this.unavailable = const {},
    this.current,
    this.maxChildren = 100,
    int? maxTracks,
  }) : maxTracks = maxTracks ?? maxChildren {
    _albums = [
      for (final album in albums)
        if (_playable(album.tracks).isNotEmpty) album,
    ];
    _artists = [
      for (final artist in artists)
        if (artist.albums.any((a) => _playable(a.tracks).isNotEmpty)) artist,
    ];
    _tracks = _playable(tracks);
    final now = current;
    _resume = now == null || unavailable.contains(now.disk) ? null : now;
  }

  /// In the order of the Albums view (BR-010).
  final List<MediaAlbum> albums;

  /// In the order of the Artists view (BR-010).
  final List<MediaArtist> artists;

  /// In the order of the Tracks view (FR-011.7).
  final List<LibraryTrack> tracks;
  final MediaTreeLabels labels;

  /// The disks whose tracks cannot be played now (BR-001).
  final Set<DiskId> unavailable;

  /// The track of the queue the controller holds, for "Reprendre"; null when
  /// there is no queue (BR-013, rule 2).
  final LibraryTrack? current;

  /// The most entries of a list before it is cut by letters (BR-013,
  /// rule 4).
  final int maxChildren;

  /// The same cut for the Tracks list alone: the other lists may stay whole
  /// while this one is cut by letters (BR-015, rule 1).
  ///
  /// @implements BR-015
  final int maxTracks;

  final String Function(String text) _fold;
  late final List<MediaAlbum> _albums;
  late final List<MediaArtist> _artists;
  late final List<LibraryTrack> _tracks;

  /// [current], unless it is on an absent disk (BR-013, rule 6).
  late final LibraryTrack? _resume;

  // The sorting text of each entry, made once: a long list is cut at every
  // request of a car.
  late final List<String> _albumKeys = [
    for (final a in _albums)
      _key('${a.unknownArtist ? '' : a.artist} ${a.title}'),
  ];
  late final List<String> _artistKeys = [
    for (final a in _artists) _key(a.unknown ? '' : a.name),
  ];
  late final List<String> _trackKeys = [
    for (final t in _tracks) _key(t.displayTitle),
  ];

  String _key(String text) => _fold(text.trim());

  static const _resumeId = 'resume';
  static const _albumsId = 'albums';
  static const _artistsId = 'artists';
  static const _tracksId = 'tracks';
  static const _currentId = 'current';
  static const _searchId = 'search';
  static const _searchLimit = 100;

  /// A longer query is cut: it is repeated in the identifier of every track
  /// found (BR-015, rule 5).
  static const _queryLimit = 100;
  static final _blanks = RegExp(r'\s+');
  static const _albumKind = 'album';
  static const _artistKind = 'artist';

  List<LibraryTrack> _playable(List<LibraryTrack> all) => [
    for (final track in all)
      if (!unavailable.contains(track.disk)) track,
  ];

  @override
  List<MediaNode> children(String parentId) {
    final parts = _split(parentId);
    switch (parts.first) {
      case MediaTree.rootId:
        if (_tracks.isEmpty) {
          return [MediaNode(id: 'empty', title: labels.empty)];
        }
        return [
          ?_resumeNode(),
          ?_currentNode(_albumKind),
          ?_currentNode(_artistKind),
          _folder(_albumsId, labels.albums),
          _folder(_artistsId, labels.artists),
          _folder(_tracksId, labels.tracks),
        ];
      case MediaTree.recentId:
        return [?_resumeNode()];
      case _currentId:
        final target = _currentTarget(_prefixOf(parts));
        return target == null ? const [] : children(target.id);
      case _albumsId:
        return _cut(
          parentId,
          _albums,
          _albumKeys,
          _albumNode,
          _prefixOf(parts),
        );
      case _artistsId:
        return _cut(
          parentId,
          _artists,
          _artistKeys,
          _artistNode,
          _prefixOf(parts),
        );
      case _tracksId:
        return _cut(
          parentId,
          _tracks,
          _trackKeys,
          (t) => _trackNode(t, parentId),
          _prefixOf(parts),
          maxTracks,
        );
      case 'album':
        final album = _albumOf(parts.length > 1 ? parts[1] : '');
        if (album == null) return const [];
        return [
          for (final t in _playable(album.tracks)) _trackNode(t, parentId),
        ];
      case 'artist':
        final artist = _artistOf(parts.length > 1 ? parts[1] : '');
        if (artist == null) return const [];
        return [
          for (final a in artist.albums)
            if (_playable(a.tracks).isNotEmpty) _albumNode(a),
        ];
    }
    return const [];
  }

  // The text each track is searched in (BR-011, rule 1): its title as shown,
  // its artist, its album artist and its album, made once.
  late final List<String> _trackTexts = [
    for (final t in _tracks)
      _key(
        [
          t.displayTitle,
          ?t.info.artist,
          ?t.info.albumArtist,
          ?t.info.album,
        ].join(' '),
      ),
  ];

  /// What [query] finds: albums, artists and tracks (BR-015, rule 4).
  ///
  /// @implements BR-015
  ({
    List<MediaAlbum> albums,
    List<MediaArtist> artists,
    List<LibraryTrack> tracks,
  })
  _found(String query) {
    // Cut like the phone's search (BR-011, rule 4): on any run of blanks.
    final words = [
      for (final w in _key(
        query.length > _queryLimit ? query.substring(0, _queryLimit) : query,
      ).split(_blanks))
        if (w.isNotEmpty) w,
    ];
    if (words.isEmpty) {
      return (albums: const [], artists: const [], tracks: const []);
    }
    bool matches(String text) => words.every(text.contains);
    final albums = [
      for (var i = 0; i < _albums.length; i++)
        if (matches(_albumTexts[i])) _albums[i],
    ];
    final artists = [
      for (var i = 0; i < _artists.length; i++)
        if (matches(_artistKeys[i])) _artists[i],
    ];
    final tracks = [
      for (var i = 0; i < _tracks.length; i++)
        if (matches(_trackTexts[i])) _tracks[i],
    ];
    return (
      albums: albums.take(_searchLimit).toList(),
      artists: artists.take(_searchLimit).toList(),
      tracks: tracks.take(_searchLimit).toList(),
    );
  }

  late final List<String> _albumTexts = [
    for (final a in _albums)
      _key(
        '${a.unknownAlbum ? '' : a.title} ${a.unknownArtist ? '' : a.artist}',
      ),
  ];

  @override
  List<MediaNode> search(String query) {
    final found = _found(query);
    final parent = [_searchId, Uri.encodeComponent(query)].join('|');
    return [
      for (final a in found.albums) _albumNode(a),
      for (final a in found.artists) _artistNode(a),
      for (final t in found.tracks) _trackNode(t, parent),
    ];
  }

  @override
  MediaNode? node(String id) {
    final parts = _split(id);
    switch (parts.first) {
      case MediaTree.rootId:
        return null;
      case _resumeId:
        return _resumeNode();
      case _currentId:
        return _currentNode(_prefixOf(parts));
      case _albumsId:
        return _folder(id, labels.albums, _prefixOf(parts));
      case _artistsId:
        return _folder(id, labels.artists, _prefixOf(parts));
      case _tracksId:
        return _folder(id, labels.tracks, _prefixOf(parts));
      case 'album':
        final album = _albumOf(parts.length > 1 ? parts[1] : '');
        return album == null ? null : _albumNode(album);
      case 'artist':
        final artist = _artistOf(parts.length > 1 ? parts[1] : '');
        return artist == null ? null : _artistNode(artist);
      case 't':
        final hit = _findTrack(parts);
        return hit == null ? null : _trackNode(hit.track, parts[1]);
    }
    return null;
  }

  @override
  BrowseAction? action(String id) {
    final parts = _split(id);
    if (parts.first == _resumeId) {
      return _resume == null ? null : const ResumeAction();
    }
    if (parts.first != 't') return null;
    final hit = _findTrack(parts);
    if (hit == null) return null;
    return PlayTracks(
      queue: [for (final t in hit.list) t.track],
      startIndex: hit.index,
    );
  }

  // The identifier of a track: `t|<where it was listed>|<disk>|<path>`, each
  // part escaped (BR-013, rule 7).
  String _trackId(LibraryTrack track, String parentId) => [
    't',
    parentId,
    track.disk.value,
    track.info.relativePath,
  ].map(Uri.encodeComponent).join('|');

  ({List<LibraryTrack> list, int index, LibraryTrack track})? _findTrack(
    List<String> parts,
  ) {
    if (parts.length != 4) return null;
    final list = _listedBy(parts[1]);
    for (var i = 0; i < list.length; i++) {
      final t = list[i];
      if (t.disk.value == parts[2] && t.info.relativePath == parts[3]) {
        return (list: list, index: i, track: t);
      }
    }
    return null;
  }

  /// The playable tracks a parent lists, in order.
  List<LibraryTrack> _listedBy(String parentId) {
    final parts = _split(parentId);
    switch (parts.first) {
      case _tracksId:
        // The whole list, whatever letter the track was found under: the
        // queue is the library, as when playing from the Tracks view.
        return _tracks;
      case 'album':
        final album = _albumOf(parts.length > 1 ? parts[1] : '');
        return album == null ? const [] : _playable(album.tracks);
      // BR-015, rule 6: a found track queues the tracks found.
      case _searchId:
        return _found(parts.length > 1 ? parts[1] : '').tracks;
    }
    return const [];
  }

  /// The parts of an identifier; one empty part for an identifier that is
  /// not one of ours (a stale or foreign one never throws).
  List<String> _split(String id) {
    try {
      return [for (final part in id.split('|')) Uri.decodeComponent(part)];
      // ignore: avoid_catching_errors, decodeComponent offers no non-throwing form.
    } on ArgumentError {
      return const [''];
    }
  }

  String _prefixOf(List<String> parts) => parts.length > 1 ? parts[1] : '';

  MediaAlbum? _albumOf(String key) {
    for (final album in _albums) {
      if (album.key == key) return album;
    }
    return null;
  }

  MediaArtist? _artistOf(String key) {
    for (final artist in _artists) {
      if (artist.key == key) return artist;
    }
    return null;
  }

  /// A list folder: the name of the list, or the letters of a cut.
  MediaNode _folder(String id, String title, [String prefix = '']) => MediaNode(
    id: id,
    title: prefix.trim().isEmpty ? title : prefix.trim().toUpperCase(),
    browsable: true,
  );

  MediaNode? _resumeNode() {
    final track = _resume;
    if (track == null) return null;
    return MediaNode(
      id: _resumeId,
      title: track.displayTitle,
      subtitle: track.info.artist,
      artwork: track.artwork,
      playable: true,
    );
  }

  /// The album or the artist of the current track, the same group the list
  /// shows (BR-013, rule 3), or null: no current track, a track of an absent
  /// disk, an unknown album or an unknown artist (FR-032.7).
  ///
  /// @implements FR-032
  MediaNode? _currentTarget(String kind) {
    final track = _resume;
    if (track == null || (kind != _albumKind && kind != _artistKind)) {
      return null;
    }
    MediaAlbum? album;
    for (final candidate in _albums) {
      if (candidate.tracks.any((t) => t.id == track.id)) {
        album = candidate;
        break;
      }
    }
    if (album == null || album.unknownAlbum) return null;
    if (kind == _albumKind) return _albumNode(album);
    for (final artist in _artists) {
      if (artist.unknown) continue;
      if (artist.albums.any((a) => a.key == album!.key)) {
        return _artistNode(artist);
      }
    }
    return null;
  }

  MediaNode? _currentNode(String kind) {
    final target = _currentTarget(kind);
    if (target == null) return null;
    final album = kind == _albumKind;
    return MediaNode(
      id: [_currentId, kind].map(Uri.encodeComponent).join('|'),
      title: album ? labels.currentAlbum : labels.currentArtist,
      subtitle: target.title,
      browsable: true,
    );
  }

  MediaNode _albumNode(MediaAlbum album) => MediaNode(
    id: ['album', album.key].map(Uri.encodeComponent).join('|'),
    title: album.unknownAlbum ? labels.unknownAlbum : album.title,
    subtitle: album.unknownArtist ? labels.unknownArtist : album.artist,
    artwork: album.artwork,
    browsable: true,
  );

  MediaNode _artistNode(MediaArtist artist) => MediaNode(
    id: ['artist', artist.key].map(Uri.encodeComponent).join('|'),
    title: artist.unknown ? labels.unknownArtist : artist.name,
    browsable: true,
  );

  MediaNode _trackNode(LibraryTrack track, String parentId) => MediaNode(
    id: _trackId(track, parentId),
    title: track.displayTitle,
    subtitle: track.info.artist,
    artwork: track.artwork,
    playable: true,
  );

  /// The entries of a list under [prefix]: the entries themselves when they
  /// fit, otherwise one folder per next letter (BR-013, rule 4). A folder
  /// takes the whole start its entries have in common, so that a chain of
  /// folders with a single way on never builds up. The order of the list is
  /// kept.
  List<MediaNode> _cut<T>(
    String listId,
    List<T> items,
    List<String> keys,
    MediaNode Function(T item) toNode,
    String prefix, [
    int? limit,
  ]) {
    final most = limit ?? maxChildren;
    final kind = _split(listId).first;
    final inside = [
      for (var i = 0; i < items.length; i++)
        if (keys[i].startsWith(prefix)) i,
    ];
    if (inside.length <= most) {
      return [for (final i in inside) toNode(items[i])];
    }
    // The entries that end at the prefix, and for each next letter, where
    // its entries are.
    final entries = <Object>[];
    final groups = <String, List<int>>{};
    for (final i in inside) {
      final rest = keys[i].substring(prefix.length);
      if (rest.isEmpty) {
        entries.add(i);
        continue;
      }
      final next = prefix + String.fromCharCode(rest.runes.first);
      final members = groups[next];
      if (members == null) {
        groups[next] = [i];
        entries.add(next);
      } else {
        members.add(i);
      }
    }
    return [
      for (final entry in entries)
        if (entry is int)
          toNode(items[entry])
        else
          _folder(
            [
              kind,
              _common([for (final i in groups[entry]!) keys[i]]),
            ].map(Uri.encodeComponent).join('|'),
            '',
            _common([for (final i in groups[entry]!) keys[i]]),
          ),
    ];
  }

  /// The start all of [texts] share.
  String _common(List<String> texts) {
    var common = texts.first;
    for (final text in texts.skip(1)) {
      var n = 0;
      while (n < common.length && n < text.length && common[n] == text[n]) {
        n++;
      }
      common = common.substring(0, n);
    }
    return common;
  }
}
