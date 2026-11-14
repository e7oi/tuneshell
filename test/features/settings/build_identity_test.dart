import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/settings/app_info.dart';
import 'package:tuneshell/features/settings/build_identity.dart';
import 'package:tuneshell/l10n/generated/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  /// @verifies FR-034.1
  test('version, commit and date', () {
    final info = BuildInfo.parse(commit: 'a1b2c3d', date: '2026-11-14');

    expect(buildIdentity(l10n, '0.1.0', info), '0.1.0 · a1b2c3d · 2026-11-14');
  });

  /// @verifies FR-034.1
  test('says when the tree was modified', () {
    final info = BuildInfo.parse(
      commit: 'a1b2c3d',
      dirty: true,
      date: '2026-11-14',
    );

    expect(
      buildIdentity(l10n, '0.1.0', info),
      '0.1.0 · a1b2c3d · modified · 2026-11-14',
    );
  });

  /// @verifies FR-034.2
  test('a local build is named, with no commit', () {
    expect(
      buildIdentity(l10n, '0.1.0', const BuildInfo()),
      '0.1.0 · local build',
    );
  });
}
