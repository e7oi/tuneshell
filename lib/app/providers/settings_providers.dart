import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/data/db/drift_settings_store.dart';
import 'package:tuneshell/domain/settings/app_settings.dart';
import 'package:tuneshell/domain/settings/ports/settings_store.dart';

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => DriftSettingsStore(ref.watch(libraryDatabaseProvider)),
);

/// The settings: the defaults until [load] reads the stored ones, which
/// `main` does before the first screen (FR-023.6, ADR-017). A change shows at
/// once and is written behind it; a failed write is logged and does not undo
/// what is shown.
///
/// @implements FR-023
class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  /// Reads the stored settings. A storage that cannot be read leaves the
  /// defaults (FR-023.7).
  Future<void> load() async {
    try {
      final entries = await ref.read(settingsStoreProvider).readAll();
      state = AppSettings.fromEntries(entries);
    } on Object catch (error) {
      debugPrint('settings: cannot read the stored settings: $error');
    }
  }

  void setTheme(ThemeChoice theme) => _change((s) => s.copyWith(theme: theme));

  void setDynamicColors({required bool enabled}) =>
      _change((s) => s.copyWith(dynamicColors: enabled));

  void setIndexOnLeft({required bool enabled}) =>
      _change((s) => s.copyWith(indexOnLeft: enabled));

  void setPauseOnUnplug({required bool enabled}) =>
      _change((s) => s.copyWith(pauseOnUnplug: enabled));

  void setRefreshOnStart({required bool enabled}) =>
      _change((s) => s.copyWith(refreshOnStart: enabled));

  void _change(AppSettings Function(AppSettings) change) {
    final before = state;
    final after = change(before);
    final changes = after.changesFrom(before);
    if (changes.isEmpty) return;
    state = after;
    unawaited(_write(changes));
  }

  Future<void> _write(Map<String, String> changes) async {
    final store = ref.read(settingsStoreProvider);
    try {
      for (final entry in changes.entries) {
        await store.write(entry.key, entry.value);
      }
    } on Object catch (error) {
      debugPrint('settings: cannot write $changes: $error');
    }
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

/// Whether Android gives dynamic colours here (Android 12 and later); asked
/// once. Without them the wallpaper colours line is greyed (FR-024.3).
final dynamicColorsSupportedProvider = FutureProvider<bool>(
  (ref) async => await DynamicColorPlugin.getCorePalette() != null,
);

/// The folders of the phone chosen for the library (FR-003), for the
/// subtitle of the settings line; invalidated when the choice changes.
final FutureProvider<Set<String>> chosenFoldersProvider =
    FutureProvider.autoDispose<Set<String>>(
      (ref) => ref.watch(libraryIndexerProvider).chosenFolders(),
    );
