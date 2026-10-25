import 'package:tuneshell/data/db/library_database.dart';
import 'package:tuneshell/domain/settings/ports/settings_store.dart';

/// The settings in the `app_settings` table of the library database
/// (ADR-017).
///
/// @implements FR-023.5
class DriftSettingsStore implements SettingsStore {
  new(this._db);

  final LibraryDatabase _db;

  @override
  Future<Map<String, String>> readAll() async => {
    for (final row in await _db.select(_db.settingEntries).get())
      row.key: row.value,
  };

  @override
  Future<void> write(String key, String value) => _db
      .into(_db.settingEntries)
      .insertOnConflictUpdate(
        SettingEntriesCompanion.insert(key: key, value: value),
      );
}
