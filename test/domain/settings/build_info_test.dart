import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/settings/app_info.dart';

void main() {
  /// @verifies FR-034.2
  test('a build without values is local', () {
    expect(const BuildInfo().isLocal, isTrue);
    expect(BuildInfo.compiled.isLocal, isTrue, reason: 'tests are not built');
    expect(BuildInfo.parse().isLocal, isTrue);
  });

  /// @verifies FR-034.1
  test('a build with a commit is not local', () {
    final info = BuildInfo.parse(commit: 'a1b2c3d4e5', date: '2026-11-14');

    expect(info.isLocal, isFalse);
    expect(info.commit, 'a1b2c3d');
    expect(info.dirty, isFalse);
    expect(info.date, '2026-11-14');
  });

  /// @verifies FR-034.5
  test('keeps only a short hexadecimal commit', () {
    expect(BuildInfo.parse(commit: 'A1B2C3D4E5F6').commit, 'a1b2c3d');
    expect(BuildInfo.parse(commit: '/home/user/x').isLocal, isTrue);
    expect(BuildInfo.parse(commit: 'abc').isLocal, isTrue);
    expect(BuildInfo.parse(commit: 'a1b2c3d', date: 'Tuesday').date, '');
    expect(BuildInfo.parse(dirty: true).dirty, isFalse);
  });

  /// @verifies FR-034.1
  test('a full hash is cut to seven characters and keeps the dirty flag', () {
    final info = BuildInfo.parse(
      commit: 'a' * 40,
      dirty: true,
      date: '2026-11-14',
    );

    expect(info.commit, 'aaaaaaa');
    expect(info.dirty, isTrue);
  });

  /// @verifies FR-034.5
  test('a date alone, or a commit with blanks, makes a local build', () {
    expect(BuildInfo.parse(date: '2026-11-14').date, '');
    expect(BuildInfo.parse(commit: 'a1b2c3d\n').isLocal, isTrue);
    expect(BuildInfo.parse(commit: ' a1b2c3d').isLocal, isTrue);
  });
}
