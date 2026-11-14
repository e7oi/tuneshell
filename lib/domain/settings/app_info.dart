// The analyser knows no define and calls the arguments of `compiled` redundant.
// ignore_for_file: avoid_redundant_argument_values

/// The version shown in the about page; a test keeps it equal to the one of
/// `pubspec.yaml` (FR-026.5).
const appVersion = '0.1.0';

/// Where the source code is (FR-026.2); shown as text, never opened: the app
/// has no network and no browser link (D15).
const sourceCodeUrl = 'https://github.com/e7oi/tuneshell';

final _hexCommit = RegExp(r'^[0-9a-fA-F]{7,40}$');
final _isoDay = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Which build this is, given at compile time by `tool/build-release.sh`
/// with `--dart-define` (FR-034, ADR-025). Without the values the build is
/// local: no commit is invented.
///
/// @implements FR-034
class BuildInfo {
  const new({this.commit = '', this.dirty = false, this.date = ''});

  /// Keeps what looks like a commit (seven hexadecimal characters out of a
  /// longer hash) and a day; anything else is dropped, so that no path or
  /// name can reach the screen (FR-034.5).
  factory parse({String commit = '', bool dirty = false, String date = ''}) {
    final hex = _hexCommit.hasMatch(commit);
    return BuildInfo(
      commit: hex ? commit.substring(0, 7).toLowerCase() : '',
      dirty: hex && dirty,
      date: hex && _isoDay.hasMatch(date) ? date : '',
    );
  }

  /// The values of the running build.
  static final compiled = BuildInfo.parse(
    commit: const String.fromEnvironment('BUILD_COMMIT'),
    dirty: const bool.fromEnvironment('BUILD_DIRTY'),
    date: const String.fromEnvironment('BUILD_DATE'),
  );

  /// Seven characters, lower case; empty when unknown.
  final String commit;

  /// The working tree had changes that were not committed.
  final bool dirty;

  /// Day of the compilation, UTC, `YYYY-MM-DD`; empty when unknown.
  final String date;

  bool get isLocal => commit.isEmpty;
}
