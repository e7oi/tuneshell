import 'package:meta/meta.dart';

/// The keys under which the settings are stored (ADR-017). A key that is not
/// listed here is ignored when read.
abstract final class SettingKey {
  static const theme = 'theme';
  static const dynamicColors = 'dynamic_colors';
  static const indexOnLeft = 'index_on_left';
  static const pauseOnUnplug = 'pause_on_unplug';
  static const refreshOnStart = 'refresh_on_start';
  static const resumePlayback = 'resume_playback';
}

/// The theme the user chose: the system's, or one of the two.
enum ThemeChoice { system, light, dark }

/// What the user can set (FR-023). Every field has a default: a missing,
/// unknown or damaged stored value gives it back, without a message.
///
/// @implements FR-023
/// @implements FR-028
@immutable
final class AppSettings {
  const new({
    this.theme = ThemeChoice.system,
    this.dynamicColors = false,
    this.indexOnLeft = false,
    this.pauseOnUnplug = true,
    this.refreshOnStart = true,
    this.resumePlayback = true,
  });

  /// Reads the stored texts leniently, setting by setting (FR-023.7).
  factory fromEntries(Map<String, String> entries) {
    const defaults = AppSettings();
    return AppSettings(
      theme: ThemeChoice.values.firstWhere(
        (choice) => choice.name == entries[SettingKey.theme],
        orElse: () => defaults.theme,
      ),
      dynamicColors: _bool(
        entries[SettingKey.dynamicColors],
        defaults.dynamicColors,
      ),
      indexOnLeft: _bool(entries[SettingKey.indexOnLeft], defaults.indexOnLeft),
      pauseOnUnplug: _bool(
        entries[SettingKey.pauseOnUnplug],
        defaults.pauseOnUnplug,
      ),
      refreshOnStart: _bool(
        entries[SettingKey.refreshOnStart],
        defaults.refreshOnStart,
      ),
      resumePlayback: _bool(
        entries[SettingKey.resumePlayback],
        defaults.resumePlayback,
      ),
    );
  }

  final ThemeChoice theme;

  /// Colours from the system wallpaper instead of the design's (FR-024.2).
  final bool dynamicColors;

  /// The alphabet index on the left (FR-024.4).
  final bool indexOnLeft;

  /// Playback pauses when headphones are unplugged (FR-025.7, BR-005).
  final bool pauseOnUnplug;

  /// The library is indexed again at each start (FR-025.6, FR-003.7).
  final bool refreshOnStart;

  /// The queue, the track and the position are kept and restored (FR-028,
  /// BR-012).
  final bool resumePlayback;

  AppSettings copyWith({
    ThemeChoice? theme,
    bool? dynamicColors,
    bool? indexOnLeft,
    bool? pauseOnUnplug,
    bool? refreshOnStart,
    bool? resumePlayback,
  }) => AppSettings(
    theme: theme ?? this.theme,
    dynamicColors: dynamicColors ?? this.dynamicColors,
    indexOnLeft: indexOnLeft ?? this.indexOnLeft,
    pauseOnUnplug: pauseOnUnplug ?? this.pauseOnUnplug,
    refreshOnStart: refreshOnStart ?? this.refreshOnStart,
    resumePlayback: resumePlayback ?? this.resumePlayback,
  );

  /// Every setting as the text that is stored.
  Map<String, String> toEntries() => {
    SettingKey.theme: theme.name,
    SettingKey.dynamicColors: '$dynamicColors',
    SettingKey.indexOnLeft: '$indexOnLeft',
    SettingKey.pauseOnUnplug: '$pauseOnUnplug',
    SettingKey.refreshOnStart: '$refreshOnStart',
    SettingKey.resumePlayback: '$resumePlayback',
  };

  /// The entries that differ from [before]: the only ones to write.
  Map<String, String> changesFrom(AppSettings before) {
    final previous = before.toEntries();
    return {
      for (final entry in toEntries().entries)
        if (previous[entry.key] != entry.value) entry.key: entry.value,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.theme == theme &&
      other.dynamicColors == dynamicColors &&
      other.indexOnLeft == indexOnLeft &&
      other.pauseOnUnplug == pauseOnUnplug &&
      other.refreshOnStart == refreshOnStart &&
      other.resumePlayback == resumePlayback;

  @override
  int get hashCode => Object.hash(
    theme,
    dynamicColors,
    indexOnLeft,
    pauseOnUnplug,
    refreshOnStart,
    resumePlayback,
  );

  @override
  String toString() => 'AppSettings(${toEntries()})';
}

bool _bool(String? text, bool fallback) => switch (text) {
  'true' => true,
  'false' => false,
  _ => fallback,
};
