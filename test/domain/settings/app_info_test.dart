import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/settings/app_info.dart';

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
}
