/// Where the settings are kept between two launches (ADR-017).
///
/// A store holds texts by key; reading and writing the values is the job of
/// `AppSettings`. A port with two implementations: the database and, in the
/// tests, a map in memory.
abstract interface class SettingsStore {
  /// Every stored entry. Throws when the storage cannot be read: the caller
  /// then uses the defaults.
  Future<Map<String, String>> readAll();

  /// Stores [value] under [key], replacing what was there.
  Future<void> write(String key, String value);
}
