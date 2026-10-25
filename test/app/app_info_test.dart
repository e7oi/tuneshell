import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/app_info.dart';
import 'package:tuneshell/app/licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// @verifies FR-026.5
  test('the version shown is the one of pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull);
    expect(appVersion, match!.group(1));
  });

  /// @verifies FR-026.2
  test('the licence of the application and of its fonts are listed', () async {
    registerLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final byPackage = {
      for (final entry in entries)
        for (final package in entry.packages) package: entry,
    };

    expect(byPackage.keys, containsAll(['TuneShell', 'Manrope', 'Inter']));
    final text = byPackage['TuneShell']!.paragraphs
        .map((p) => p.text)
        .join('\n');
    expect(text, contains('GNU GENERAL PUBLIC LICENSE'));
    expect(text, contains('Version 3'));
  });
}
