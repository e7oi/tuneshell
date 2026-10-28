import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/media_node.dart';
import 'package:tuneshell/domain/playback/ports/media_tree.dart';
import 'package:tuneshell/domain/playback/services/library_media_tree.dart';

import '../../fakes/fake_library.dart';

const _ssd = DiskId('ssd');

const _labels = MediaTreeLabels(
  albums: 'Albums',
  artists: 'Artists',
  tracks: 'Tracks',
  unknownAlbum: 'Unknown album',
  unknownArtist: 'Unknown artist',
  empty: 'Open TuneShell on the phone',
);

var _nextId = 1;

LibraryTrack track(
  String path, {
  String? title,
  String? artist,
  DiskId disk = internalDisk,
  String? artwork,
}) => LibraryTrack(
  id: _nextId++,
  disk: disk,
  info: TrackInfo(
    relativePath: path,
    size: 1,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
    title: title ?? path.split('/').last,
    artist: artist,
  ),
  artwork: artwork,
);

MediaAlbum album(
  String key,
  String title,
  String artist,
  List<LibraryTrack> tracks, {
  bool unknownAlbum = false,
  bool unknownArtist = false,
}) => MediaAlbum(
  key: key,
  title: title,
  artist: artist,
  tracks: tracks,
  unknownAlbum: unknownAlbum,
  unknownArtist: unknownArtist,
);

LibraryMediaTree treeOf({
  List<MediaAlbum> albums = const [],
  List<MediaArtist> artists = const [],
  List<LibraryTrack> tracks = const [],
  Set<DiskId> unavailable = const {},
  LibraryTrack? current,
  int maxChildren = 100,
}) => LibraryMediaTree(
  albums: albums,
  artists: artists,
  tracks: tracks,
  labels: _labels,
  fold: (text) => text.toLowerCase(),
  unavailable: unavailable,
  current: current,
  maxChildren: maxChildren,
);

List<String> titles(List<MediaNode> nodes) => [for (final n in nodes) n.title];

void main() {
  final a1 = track('a/1.flac', title: 'One', artist: 'Ann');
  final a2 = track('a/2.flac', title: 'Two', artist: 'Ann');
  final b1 = track('b/1.flac', title: 'Three', artist: 'Bob');
  final ann = album('ann\u0000first', 'First', 'Ann', [a1, a2]);
  final bob = album('bob\u0000second', 'Second', 'Bob', [b1]);
  final artists = [
    MediaArtist(key: 'ann', name: 'Ann', albums: [ann]),
    MediaArtist(key: 'bob', name: 'Bob', albums: [bob]),
  ];

  LibraryMediaTree library({
    Set<DiskId> unavailable = const {},
    LibraryTrack? current,
    int maxChildren = 100,
  }) => treeOf(
    albums: [ann, bob],
    artists: artists,
    tracks: [a1, b1, a2],
    unavailable: unavailable,
    current: current,
    maxChildren: maxChildren,
  );

  /// @verifies BR-013
  group('BR-013 the root', () {
    test('rule 1: Albums, Artists and Tracks, nothing to resume', () {
      final root = library().children(MediaTree.rootId);

      expect(titles(root), ['Albums', 'Artists', 'Tracks']);
      expect(root.every((n) => n.browsable && !n.playable), isTrue);
    });

    test('rule 2: "Reprendre" is the current track, first and playable', () {
      final tree = library(current: a2);

      final root = tree.children(MediaTree.rootId);

      expect(root.first.title, 'Two');
      expect(root.first.subtitle, 'Ann');
      expect(root.first.playable, isTrue);
      expect(tree.children(MediaTree.recentId), [
        isA<MediaNode>().having((n) => n.title, 'title', 'Two'),
      ]);
      expect(tree.action(root.first.id), isA<ResumeAction>());
    });

    test('rule 6: a current track on an absent disk is not offered', () {
      final away = track('x/9.flac', title: 'Away', disk: _ssd);
      final tree = treeOf(
        tracks: [a1, away],
        unavailable: {_ssd},
        current: away,
      );

      expect(titles(tree.children(MediaTree.rootId)), [
        'Albums',
        'Artists',
        'Tracks',
      ]);
      expect(tree.children(MediaTree.recentId), isEmpty);
      expect(tree.action('resume'), isNull);
    });

    test('rule 2: no queue, nothing to resume and no action', () {
      final tree = library();

      expect(tree.children(MediaTree.recentId), isEmpty);
      expect(tree.action('resume'), isNull);
    });

    test('rule 8: an empty library has one message and nothing else', () {
      final root = treeOf().children(MediaTree.rootId);

      expect(titles(root), ['Open TuneShell on the phone']);
      expect(root.single.playable || root.single.browsable, isFalse);
    });

    test('rule 8: a library of absent tracks only counts as empty', () {
      final tree = treeOf(
        tracks: [track('x.flac', disk: _ssd)],
        unavailable: {_ssd},
      );

      expect(titles(tree.children(MediaTree.rootId)), [
        'Open TuneShell on the phone',
      ]);
    });
  });

  /// @verifies BR-013
  group('BR-013 albums, artists and tracks', () {
    test('rule 3: albums keep their order and say the artist', () {
      final nodes = library().children('albums');

      expect(titles(nodes), ['First', 'Second']);
      expect(nodes.first.subtitle, 'Ann');
      expect(nodes.every((n) => n.browsable), isTrue);
    });

    test('rule 3: an artist opens onto the albums of the artist', () {
      final tree = library();
      final artistNode = tree.children('artists').first;

      expect(artistNode.title, 'Ann');
      expect(titles(tree.children(artistNode.id)), ['First']);
    });

    test('rule 3: an album opens onto its tracks, in the album order', () {
      final tree = library();
      final albumNode = tree.children('albums').first;

      final nodes = tree.children(albumNode.id);

      expect(titles(nodes), ['One', 'Two']);
      expect(nodes.every((n) => n.playable), isTrue);
    });

    test('rule 3: tracks come in the order they are given', () {
      expect(titles(library().children('tracks')), ['One', 'Three', 'Two']);
    });

    test('rule 9: the unknown album and artist have the fixed texts', () {
      final tree = treeOf(
        albums: [
          album('k', '', '', [a1], unknownAlbum: true, unknownArtist: true),
        ],
        artists: [
          MediaArtist(
            key: '',
            name: '',
            unknown: true,
            albums: [
              album('k', '', '', [a1], unknownAlbum: true, unknownArtist: true),
            ],
          ),
        ],
        tracks: [a1],
      );

      final albums = tree.children('albums');

      expect(albums.single.title, 'Unknown album');
      expect(albums.single.subtitle, 'Unknown artist');
      expect(tree.children('artists').single.title, 'Unknown artist');
    });

    test('rule 9: a track without tags shows its file name', () {
      final bare = LibraryTrack(
        id: 99,
        disk: internalDisk,
        info: info('Music/Plain.mp3'),
      );

      final node = treeOf(tracks: [bare]).children('tracks').single;

      expect(node.title, 'Plain.mp3');
      expect(node.subtitle, isNull);
    });

    test('the cover of a track is handed over by identifier', () {
      final cover = track('c.flac', title: 'Covered', artwork: 'abc123');

      final node = treeOf(tracks: [cover]).children('tracks').single;

      expect(node.artwork, 'abc123');
    });
  });

  /// @verifies BR-013
  group('BR-013 choosing a track', () {
    test('rule 5: an album track queues the album from that track', () {
      final tree = library();
      final albumId = tree.children('albums').first.id;
      final second = tree.children(albumId).last;

      final action = tree.action(second.id);

      expect(action, isA<PlayTracks>());
      final play = action! as PlayTracks;
      expect(play.queue, [a1.track, a2.track]);
      expect(play.startIndex, 1);
    });

    test('rule 5: a track of the Tracks list queues that list', () {
      final tree = library();
      final three = tree.children('tracks')[1];

      final play = tree.action(three.id)! as PlayTracks;

      expect(play.queue, [a1.track, b1.track, a2.track]);
      expect(play.startIndex, 1);
    });

    test('rule 7: the identifiers do not change when the tree is rebuilt', () {
      final first = library().children('tracks').map((n) => n.id).toList();
      final again = library().children('tracks').map((n) => n.id).toList();

      expect(again, first);
      expect(first.toSet().length, first.length);
    });

    test('rule 7: an identifier finds its node again, odd paths included', () {
      final odd = track(
        'Mu sic/a|b%c é.flac',
        title: 'Odd',
        disk: const DiskId('d|1'),
      );
      final tree = treeOf(tracks: [odd]);

      final id = tree.children('tracks').single.id;

      expect(tree.node(id)!.title, 'Odd');
      expect((tree.action(id)! as PlayTracks).queue, [odd.track]);
    });

    test('an unknown or foreign identifier plays nothing', () {
      final tree = library();

      expect(tree.action('t|tracks|nope|nope'), isNull);
      expect(tree.action('albums'), isNull);
      expect(tree.action('garbage'), isNull);
      expect(tree.node('garbage'), isNull);
      expect(tree.children('garbage'), isEmpty);
    });
  });

  /// @verifies BR-013
  group('BR-013 absent sources', () {
    test('rule 6: tracks of an absent disk are not proposed or queued', () {
      final away = track('s/x.flac', title: 'Away', disk: _ssd);
      final tree = treeOf(
        albums: [
          album('mixed', 'Mixed', 'Ann', [a1, away]),
          album('gone', 'Gone', 'Zed', [away]),
        ],
        artists: [
          MediaArtist(
            key: 'zed',
            name: 'Zed',
            albums: [
              album('gone', 'Gone', 'Zed', [away]),
            ],
          ),
          MediaArtist(
            key: 'ann',
            name: 'Ann',
            albums: [
              album('mixed', 'Mixed', 'Ann', [a1, away]),
            ],
          ),
        ],
        tracks: [a1, away],
        unavailable: {_ssd},
      );

      expect(titles(tree.children('albums')), ['Mixed']);
      expect(titles(tree.children('artists')), ['Ann']);
      expect(titles(tree.children('tracks')), ['One']);
      final inAlbum = tree.children(tree.children('albums').single.id);
      expect(titles(inAlbum), ['One']);
      expect((tree.action(inAlbum.single.id)! as PlayTracks).queue, [a1.track]);
    });
  });

  /// @verifies BR-013
  group('BR-013 long lists', () {
    final many = [
      for (var i = 0; i < 30; i++)
        track('t/a$i.flac', title: 'Apple ${i.toString().padLeft(2, '0')}'),
      for (var i = 0; i < 5; i++) track('t/b$i.flac', title: 'Berry $i'),
      for (var i = 0; i < 3; i++) track('t/c$i.flac', title: 'Cherry $i'),
    ];

    test('rule 4: a list over the limit is cut by first letters', () {
      final tree = treeOf(tracks: many, maxChildren: 10);

      final top = tree.children('tracks');

      expect(titles(top), ['APPLE', 'BERRY', 'CHERRY']);
      expect(top.every((n) => n.browsable && !n.playable), isTrue);
    });

    test('rule 4: a letter that still holds too much is cut again', () {
      final tree = treeOf(tracks: many, maxChildren: 10);
      final apple = tree.children('tracks').first;

      final next = tree.children(apple.id);

      expect(titles(next), ['APPLE 0', 'APPLE 1', 'APPLE 2']);
      expect(next.every((n) => n.browsable && !n.playable), isTrue);
      expect(tree.node(next.first.id)!.title, 'APPLE 0');
    });

    test('rule 4: a leading space does not split the cut from the folder', () {
      final spaced = [
        track('t/s.flac', title: ' Spaced'),
        for (var i = 0; i < 12; i++) track('t/x$i.flac', title: 'Xylo $i'),
      ];
      final tree = treeOf(tracks: spaced, maxChildren: 10);
      final found = <String>[];
      void walk(String id) {
        for (final node in tree.children(id)) {
          if (node.playable) {
            found.add(node.title);
          } else {
            walk(node.id);
          }
        }
      }

      walk('tracks');

      expect(found.length, spaced.length);
    });

    test('a malformed or stale identifier gives nothing and never throws', () {
      final tree = treeOf(tracks: many, maxChildren: 10);

      expect(tree.children('tracks|%E0%A4%A'), isEmpty);
      expect(tree.node('t|%zz'), isNull);
      expect(tree.action('album|gone'), isNull);
      expect(tree.node('root'), isNull);
    });

    test('rule 4: no track is lost, whatever the depth', () {
      final tree = treeOf(tracks: many, maxChildren: 10);
      final found = <String>[];
      void walk(String id) {
        for (final node in tree.children(id)) {
          if (node.playable) {
            found.add(node.title);
          } else {
            walk(node.id);
          }
        }
      }

      walk('tracks');

      expect(found.toSet(), {for (final t in many) t.displayTitle});
      expect(found.length, many.length);
    });

    test('rule 4: a track found in a letter queues that letter', () {
      final tree = treeOf(tracks: many, maxChildren: 10);
      final cherry = tree.children('tracks').last;
      final cherries = tree.children(cherry.id);

      final play = tree.action(cherries.last.id)! as PlayTracks;

      expect(play.queue.length, 3);
      expect(play.startIndex, 2);
    });

    test('a list at the limit stays whole', () {
      final tree = treeOf(tracks: many.take(10).toList(), maxChildren: 10);

      expect(tree.children('tracks'), hasLength(10));
      expect(tree.children('tracks').every((n) => n.playable), isTrue);
    });
  });
}
