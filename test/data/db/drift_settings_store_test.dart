import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/data/db/drift_settings_store.dart';
import 'package:tuneshell/data/db/library_database.dart';
import 'package:tuneshell/domain/settings/app_settings.dart';

void main() {
  late LibraryDatabase db;
  late DriftSettingsStore store;

  setUp(() {
    db = LibraryDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    store = DriftSettingsStore(db);
  });

  tearDown(() => db.close());

  /// @verifies FR-023.5
  group('DriftSettingsStore', () {
    test('a new database holds no setting', () async {
      expect(await store.readAll(), isEmpty);
    });

    test('writes and reads back a setting', () async {
      await store.write(SettingKey.theme, 'dark');

      expect(await store.readAll(), {SettingKey.theme: 'dark'});
    });

    test('a second write replaces the first', () async {
      await store.write(SettingKey.theme, 'dark');
      await store.write(SettingKey.theme, 'light');
      await store.write(SettingKey.indexOnLeft, 'true');

      expect(await store.readAll(), {
        SettingKey.theme: 'light',
        SettingKey.indexOnLeft: 'true',
      });
    });

    test('the settings survive a reopened database', () async {
      // The same connection stands for the file kept between two launches.
      await store.write(SettingKey.pauseOnUnplug, 'false');

      final again = DriftSettingsStore(db);

      final settings = AppSettings.fromEntries(await again.readAll());
      expect(settings.pauseOnUnplug, isFalse);
    });
  });
}
