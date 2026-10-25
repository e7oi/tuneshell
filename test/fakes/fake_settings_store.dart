import 'package:tuneshell/domain/settings/ports/settings_store.dart';

/// In-memory [SettingsStore].
class FakeSettingsStore implements SettingsStore {
  new([Map<String, String> initial = const {}]) : entries = {...initial};

  /// What is stored.
  final Map<String, String> entries;

  /// Every write, in order, as `key=value`.
  final List<String> writes = [];

  /// Reading and writing throw while this is set.
  Exception? failure;

  @override
  Future<Map<String, String>> readAll() async {
    final problem = failure;
    if (problem != null) throw problem;
    return {...entries};
  }

  @override
  Future<void> write(String key, String value) async {
    final problem = failure;
    if (problem != null) throw problem;
    writes.add('$key=$value');
    entries[key] = value;
  }
}
