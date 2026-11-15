import 'package:flutter/foundation.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/features/browse/album_key_text.dart';
import 'package:tuneshell/ui/widgets/alphabet_index.dart';

/// An album: the tracks that share an album artist and a title (BR-010).
@immutable
final class AlbumGroup {
  const new({
    required this.key,
    required this.artistKey,
    required this.titleKey,
    required this.title,
    required this.artist,
    required this.unknownAlbum,
    required this.unknownArtist,
    required this.variousArtists,
    required this.tracks,
    required this.duration,
    required this.discCount,
    required this.disks,
    required this.available,
    this.year,
    this.genre,
    this.artwork,
  });

  /// Folded identity: artist and title without case, accents or extra spaces.
  final String key;

  /// The folded artist alone, the identity of the artist (empty: unknown).
  final String artistKey;

  /// The folded title alone, what the albums are sorted by.
  final String titleKey;

  /// The most frequent spelling; empty when [unknownAlbum].
  final String title;

  /// The most frequent spelling; empty when [unknownArtist].
  final String artist;
  final bool unknownAlbum;
  final bool unknownArtist;

  /// True when the album is by various artists (BR-017, rule 4): its artist
  /// is the one "Various artists", whose name the interface writes.
  final bool variousArtists;

  /// In the order of BR-010, rule 6: disc, then track number. The one order
  /// of an album, shown, played and queued alike.
  final List<LibraryTrack> tracks;
  final Duration duration;
  final int discCount;

  /// The oldest known year.
  final int? year;

  /// The most frequent genre.
  final String? genre;

  /// The cover of the first track that has one.
  final String? artwork;

  /// The disks the tracks are on, in track order, without repeats.
  final List<DiskId> disks;

  /// False when every track is on an unavailable disk (BR-010, rule 9).
  final bool available;

  int get trackCount => tracks.length;
}

/// An artist: the albums that share an album artist (BR-010).
@immutable
final class ArtistGroup {
  const new({
    required this.key,
    required this.name,
    required this.unknown,
    required this.various,
    required this.albums,
    required this.tracks,
    required this.duration,
    required this.available,
  });

  final String key;

  /// The most frequent spelling; empty when [unknown].
  final String name;
  final bool unknown;

  /// The one artist "Various artists" (BR-017, rule 5); its [name] is empty.
  final bool various;

  /// In the order of BR-010, rule 7.
  final List<AlbumGroup> albums;

  /// Every track, album by album, each in its own order.
  final List<LibraryTrack> tracks;
  final Duration duration;
  final bool available;

  int get trackCount => tracks.length;
}

/// The albums and the artists of the library, ready to show (BR-010).
///
/// @implements BR-010
@immutable
final class LibraryGroups {
  new _({
    required this.albums,
    required this.artists,
    required this.albumLetters,
    required this.albumFirstIndex,
    required this.artistLetters,
    required this.artistFirstIndex,
  });

  /// Groups [tracks]; [unavailableDisks] are the disks that cannot be read.
  factory build({
    required List<LibraryTrack> tracks,
    required Set<DiskId> unavailableDisks,
  }) {
    final byAlbum = <String, List<LibraryTrack>>{};
    final artistKeys = <String, String>{};
    final merged = _mergedKeys(tracks);
    for (final track in tracks) {
      final album = _text(track.info.album);
      final String artistKey;
      final bucket = merged[track.id];
      if (_isVarious(track) || bucket != null) {
        artistKey = _variousKey;
      } else {
        final artist = _albumArtist(track);
        artistKey = artist == null ? '' : _fold(artist);
      }
      // BR-017, rule 8: the untagged tracks of a folder are an album of their
      // own, even when another folder holds an album of the same title.
      final key =
          '$artistKey\u0000${album == null ? '' : _fold(album)}${bucket ?? ''}';
      artistKeys[key] = artistKey;
      (byAlbum[key] ??= []).add(track);
    }

    final albums = [
      for (final entry in byAlbum.entries)
        _album(
          entry.key,
          artistKeys[entry.key]!,
          entry.value,
          unavailableDisks,
        ),
    ]..sort(_compareAlbums);

    final byArtist = <String, List<AlbumGroup>>{};
    for (final album in albums) {
      (byArtist[album.artistKey] ??= []).add(album);
    }
    final artists = [
      for (final entry in byArtist.entries) _artist(entry.key, entry.value),
    ]..sort((a, b) => _artistSort(a).compareTo(_artistSort(b)));

    final albumNames = [
      for (final a in albums)
        if (a.unknownAlbum) '' else a.title,
    ];
    final artistNames = [for (final a in artists) a.name];
    return LibraryGroups._(
      albums: albums,
      artists: artists,
      albumLetters: buildLetters(albumNames),
      albumFirstIndex: firstIndexes(albumNames),
      artistLetters: buildLetters(artistNames),
      artistFirstIndex: firstIndexes(artistNames),
    );
  }

  /// In display order: artist, then year, then title.
  final List<AlbumGroup> albums;

  /// In display order: the unknown artist first, then by folded name.
  final List<ArtistGroup> artists;

  /// "#" then A to Z, counted over the albums (by the letter of the artist).
  final List<AlphabetLetter> albumLetters;
  final Map<String, int> albumFirstIndex;
  final List<AlphabetLetter> artistLetters;
  final Map<String, int> artistFirstIndex;

  /// Every track by artist, then album title, then disc and track number: the
  /// queue of a track chosen on the home tab (FR-033, rule 4). The unknown
  /// artist comes last, the tracks without an album after the albums of their
  /// artist.
  ///
  /// @implements FR-033
  late final List<LibraryTrack> tracksByArtist = _tracksByArtist(artists);

  /// The album of each track, by the track's internal identity; made on the
  /// first question, a library has thousands of tracks.
  late final Map<int, AlbumGroup> _albumOfTrack = {
    for (final album in albums)
      for (final track in album.tracks) track.id: album,
  };
  late final Map<String, ArtistGroup> _artistByKey = {
    for (final artist in artists) artist.key: artist,
  };

  /// The album [track] belongs to, or null when its album is unknown or it is
  /// not in the library (FR-032.1).
  ///
  /// @implements FR-032
  AlbumGroup? albumOf(LibraryTrack track) {
    final album = _albumOfTrack[track.id];
    return album == null || album.unknownAlbum ? null : album;
  }

  /// The artist group [track] belongs to, that of its album artist (BR-010,
  /// rule 1), or null when it is unknown or the various artist, which no
  /// track is by (FR-032.1, FR-035.5).
  ///
  /// @implements FR-032
  ArtistGroup? artistOf(LibraryTrack track) {
    final album = _albumOfTrack[track.id];
    final artist = album == null ? null : _artistByKey[album.artistKey];
    return artist == null || artist.unknown || artist.various ? null : artist;
  }
}

List<LibraryTrack> _tracksByArtist(List<ArtistGroup> artists) {
  final known = [
    for (final artist in artists)
      if (!artist.unknown) artist,
  ];
  final unknown = [
    for (final artist in artists)
      if (artist.unknown) artist,
  ];
  return [
    for (final artist in [...known, ...unknown])
      for (final album in [...artist.albums]..sort(_compareByTitle))
        ...album.tracks,
  ];
}

/// The albums of one artist by title, the unknown album last.
int _compareByTitle(AlbumGroup a, AlbumGroup b) {
  if (a.unknownAlbum != b.unknownAlbum) return a.unknownAlbum ? 1 : -1;
  final byTitle = a.titleKey.compareTo(b.titleKey);
  return byTitle != 0 ? byTitle : a.key.compareTo(b.key);
}

String? _text(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

/// BR-010, rule 1.
String? _albumArtist(LibraryTrack track) =>
    _text(track.info.albumArtist) ?? _text(track.info.artist);

/// BR-010, rule 3 and BR-017, rule 1: case, accents, spaces and the shapes of
/// the punctuation do not count.
String _fold(String text) => albumKeyText(text);

AlbumGroup _album(
  String key,
  String artistKey,
  List<LibraryTrack> found,
  Set<DiskId> unavailable,
) {
  // The sort keys are made once per track, not once per comparison.
  final keyed = [
    for (final t in found)
      (
        track: t,
        disc: _disc(t),
        number: _number(t),
        title: sortKey(t.displayTitle),
      ),
  ]..sort(_compareKeyed);
  final tracks = [for (final k in keyed) k.track];
  final various = artistKey == _variousKey;
  final artist = _mostFrequent([for (final t in tracks) ?_albumArtist(t)]);
  final title = _mostFrequent([for (final t in tracks) ?_text(t.info.album)]);
  final years = [
    for (final t in tracks)
      if (t.info.year != null && t.info.year! > 0) t.info.year!,
  ]..sort();
  final discs = {for (final t in tracks) _disc(t)};
  final disks = <DiskId>[];
  for (final t in tracks) {
    if (!disks.contains(t.disk)) disks.add(t.disk);
  }
  var duration = Duration.zero;
  for (final t in tracks) {
    duration += t.info.duration ?? Duration.zero;
  }
  return AlbumGroup(
    key: key,
    artistKey: artistKey,
    titleKey: key.substring(artistKey.length + 1),
    title: title ?? '',
    artist: various ? '' : artist ?? '',
    unknownAlbum: title == null,
    unknownArtist: artist == null && !various,
    variousArtists: various,
    tracks: List.unmodifiable(tracks),
    duration: duration,
    discCount: discs.length,
    year: years.isEmpty ? null : years.first,
    genre: _mostFrequent([for (final t in tracks) ?_text(t.info.genre)]),
    artwork: tracks.map((t) => t.artwork).nonNulls.firstOrNull,
    disks: List.unmodifiable(disks),
    available: tracks.any((t) => !unavailable.contains(t.disk)),
  );
}

ArtistGroup _artist(String key, List<AlbumGroup> found) {
  final various = key == _variousKey;
  final albums = [...found]..sort(_compareInArtist);
  final names = <String>[
    for (final album in albums)
      if (!album.unknownArtist)
        for (var i = 0; i < album.trackCount; i++) album.artist,
  ];
  var duration = Duration.zero;
  for (final album in albums) {
    duration += album.duration;
  }
  return ArtistGroup(
    key: key,
    name: various ? '' : _mostFrequent(names) ?? '',
    unknown: names.isEmpty && !various,
    various: various,
    albums: List.unmodifiable(albums),
    tracks: List.unmodifiable([for (final a in albums) ...a.tracks]),
    duration: duration,
    available: albums.any((a) => a.available),
  );
}

/// The value that occurs most; the first one met on a tie. Null when empty.
String? _mostFrequent(List<String> values) {
  if (values.isEmpty) return null;
  final counts = <String, int>{};
  for (final value in values) {
    counts.update(value, (n) => n + 1, ifAbsent: () => 1);
  }
  var best = values.first;
  for (final value in values) {
    if (counts[value]! > counts[best]!) best = value;
  }
  return best;
}

/// A disc number below one counts as absent, which is disc one.
int _disc(LibraryTrack track) {
  final disc = track.info.discNumber;
  return disc == null || disc < 1 ? 1 : disc;
}

/// The track number, or null when it is absent or below one.
int? _number(LibraryTrack track) {
  final number = track.info.trackNumber;
  return number == null || number < 1 ? null : number;
}

typedef _Keyed = ({LibraryTrack track, int disc, int? number, String title});

/// BR-010, rule 6: disc, then track number (none after the numbered), then
/// title, then path.
int _compareKeyed(_Keyed a, _Keyed b) {
  final byDisc = a.disc.compareTo(b.disc);
  if (byDisc != 0) return byDisc;
  if (a.number != b.number) {
    if (a.number == null) return 1;
    if (b.number == null) return -1;
    return a.number!.compareTo(b.number!);
  }
  final byTitle = a.title.compareTo(b.title);
  if (byTitle != 0) return byTitle;
  return a.track.info.relativePath.compareTo(b.track.info.relativePath);
}

/// The unknown artist leads: its key is shorter than any other; the various
/// artist comes right after it, before the names that start with a symbol.
const _variousSort = '0\u0000';

String _artistSort(ArtistGroup artist) =>
    artist.unknown ? '0' : (artist.various ? _variousSort : artist.key);

/// BR-010, rule 7: the albums by title (the unknown album leads, in the "#"
/// group), then artist, then year (none last).
int _compareAlbums(AlbumGroup a, AlbumGroup b) {
  if (a.unknownAlbum != b.unknownAlbum) return a.unknownAlbum ? -1 : 1;
  final byTitle = a.titleKey.compareTo(b.titleKey);
  if (byTitle != 0) return byTitle;
  final byArtist = _artistKey(a).compareTo(_artistKey(b));
  if (byArtist != 0) return byArtist;
  final byYear = _compareYears(a.year, b.year);
  if (byYear != 0) return byYear;
  return a.key.compareTo(b.key);
}

/// BR-010, rule 7: the albums of one artist by year (none last), then title
/// (the unknown album last).
int _compareInArtist(AlbumGroup a, AlbumGroup b) {
  final byYear = _compareYears(a.year, b.year);
  if (byYear != 0) return byYear;
  if (a.unknownAlbum != b.unknownAlbum) return a.unknownAlbum ? 1 : -1;
  final byTitle = a.titleKey.compareTo(b.titleKey);
  if (byTitle != 0) return byTitle;
  return a.key.compareTo(b.key);
}

int _compareYears(int? a, int? b) {
  if (a == b) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

String _artistKey(AlbumGroup album) => album.unknownArtist
    ? '0'
    : (album.variousArtists ? _variousSort : album.artistKey);

/// The folded artist of the one artist "Various artists" (BR-017, rule 5);
/// no real name folds to it, the control character cannot be typed in a tag.
const _variousKey = '\u0001';

/// BR-017, rule 2: what an album artist tag says to mean "various artists".
final Set<String> _variousNames = {
  for (final name in const [
    'Various Artists',
    'Various',
    'VA',
    'Artistes divers',
    'Divers',
  ])
    albumKeyText(name),
};

/// @implements BR-017
bool _isVarious(LibraryTrack track) {
  final artist = _text(track.info.albumArtist);
  return artist != null && _variousNames.contains(albumKeyText(artist));
}

/// BR-017, rule 3: the tracks without an album artist that are put together
/// by the title, the folder and the disk they share. A folder holds an album
/// of various artists when its untagged tracks of one title are by two
/// artists or more, or when one track of that title says "various artists".
/// The result gives each of those tracks the identity of its folder, empty
/// when the folder has a track tagged "various artists": the tag says the
/// album is the one of that title, whatever the folder (BR-017, rule 5).
///
/// @implements BR-017
Map<int, String> _mergedKeys(List<LibraryTrack> tracks) {
  final buckets = <String, ({List<LibraryTrack> untagged, bool various})>{};
  for (final track in tracks) {
    final album = _text(track.info.album);
    if (album == null) continue;
    final various = _isVarious(track);
    if (_text(track.info.albumArtist) != null && !various) continue;
    final path = track.info.relativePath;
    final folder = path.substring(0, path.lastIndexOf('/') + 1);
    final key = '${track.disk.value}\u0000$folder\u0000${_fold(album)}';
    final bucket = buckets[key] ?? (untagged: <LibraryTrack>[], various: false);
    if (!various) bucket.untagged.add(track);
    buckets[key] = (
      untagged: bucket.untagged,
      various: bucket.various || various,
    );
  }
  final merged = <int, String>{};
  for (final entry in buckets.entries) {
    final bucket = entry.value;
    final artists = {
      for (final t in bucket.untagged)
        if (_albumArtist(t) != null) _fold(_albumArtist(t)!),
    };
    if (bucket.various || artists.length >= 2) {
      final identity = bucket.various ? '' : '\u0002${entry.key}';
      for (final t in bucket.untagged) {
        merged[t.id] = identity;
      }
    }
  }
  return merged;
}
