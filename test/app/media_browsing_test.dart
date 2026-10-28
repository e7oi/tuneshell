import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/media_browsing.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/model/media_node.dart';
import 'package:tuneshell/domain/playback/ports/media_tree.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';

import '../fakes/fake_audio_engine.dart';
import '../fakes/fake_library.dart';
import '../fakes/fake_storage.dart';

TrackInfo tagged(
  String path, {
  required String title,
  required String artist,
  required String album,
  int number = 1,
}) => TrackInfo(
  relativePath: path,
  size: 1,
  modifiedAt: DateTime.fromMillisecondsSinceEpoch(1000),
  title: title,
  artist: artist,
  album: album,
  albumArtist: artist,
  trackNumber: number,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeLibraryRepository library;

  setUp(() async {
    library = FakeLibraryRepository();
    await library.ensureDisk(Disk.internal);
  });

  Future<ProviderContainer> start() async {
    final container = ProviderContainer(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(library),
        playerControllerProvider.overrideWith((ref) {
          final controller = PlayerController(
            engine: FakeAudioEngine(),
            opener: FakeTrackSourceOpener(),
            volumes: FakeVolumeEvents({internalDisk}),
          );
          ref.onDispose(controller.dispose);
          unawaited(controller.start());
          return controller;
        }),
      ],
    );
    addTearDown(container.dispose);
    keepMediaTreeReadable(container);
    return container;
  }

  List<String> titles(List<MediaNode> nodes) => [
    for (final n in nodes) n.title,
  ];

  /// @verifies BR-013
  /// @verifies FR-029
  group('FR-029 the tree of the library', () {
    test('rule 3: the same albums, artists and tracks as the views', () async {
      await library.applyIndex(internalDisk, [
        tagged(
          'M/b2.flac',
          title: 'Two',
          artist: 'Bob',
          album: 'Beta',
          number: 2,
        ),
        tagged('M/b1.flac', title: 'One', artist: 'Bob', album: 'Beta'),
        tagged('M/a1.flac', title: 'Solo', artist: 'Ann', album: 'Alpha'),
      ]);
      final container = await start();

      final tree = await currentMediaTree(container);

      expect(titles(tree.children(MediaTree.rootId)), [
        'Albums',
        'Artists',
        'Tracks',
      ]);
      final albums = tree.children('albums');
      expect(titles(albums), ['Alpha', 'Beta']);
      expect(albums.last.subtitle, 'Bob');
      expect(titles(tree.children(albums.last.id)), ['One', 'Two']);
      expect(titles(tree.children('artists')), ['Ann', 'Bob']);
      expect(titles(tree.children('tracks')), ['One', 'Solo', 'Two']);
    });

    test('an unchanged library gives the same tree again', () async {
      await library.applyIndex(internalDisk, [
        tagged('M/a1.flac', title: 'Solo', artist: 'Ann', album: 'Alpha'),
      ]);
      final container = await start();

      final first = await currentMediaTree(container);
      final second = await currentMediaTree(container);

      expect(identical(first, second), isTrue);
    });

    test('choosing a track of an album queues the album from there', () async {
      await library.applyIndex(internalDisk, [
        tagged(
          'M/b2.flac',
          title: 'Two',
          artist: 'Bob',
          album: 'Beta',
          number: 2,
        ),
        tagged('M/b1.flac', title: 'One', artist: 'Bob', album: 'Beta'),
      ]);
      final container = await start();
      final tree = await currentMediaTree(container);
      final inAlbum = tree.children(tree.children('albums').single.id);

      final play = tree.action(inAlbum.last.id)! as PlayTracks;

      expect(
        [for (final t in play.queue) t.relativePath],
        ['M/b1.flac', 'M/b2.flac'],
      );
      expect(play.startIndex, 1);
    });

    test('rule 2: the track of the held queue is offered first', () async {
      await library.applyIndex(internalDisk, [
        tagged('M/a.flac', title: 'Alpha', artist: 'Ann', album: 'First'),
        tagged(
          'M/b.flac',
          title: 'Beta',
          artist: 'Ann',
          album: 'First',
          number: 2,
        ),
      ]);
      final container = await start();
      final controller = container.read(playerControllerProvider);
      await controller.setQueue([
        const Track(disk: internalDisk, relativePath: 'M/b.flac'),
      ]);
      await pumpEventQueue();

      final tree = await currentMediaTree(container);

      final root = tree.children(MediaTree.rootId);
      expect(root.first.title, 'Beta');
      expect(root.first.playable, isTrue);
    });

    test('rule 8: an empty library gives only the message', () async {
      final container = await start();

      final tree = await currentMediaTree(container);

      expect(titles(tree.children(MediaTree.rootId)), [
        'Open TuneShell on your phone to choose your music',
      ]);
    });
  });
}
