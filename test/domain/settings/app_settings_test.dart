import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/settings/app_settings.dart';

void main() {
  /// @verifies FR-023.4
  group('defaults', () {
    test('a first installation: system theme, indexes on the right, '
        'pause on unplug and refresh at start on', () {
      const settings = AppSettings();

      expect(settings.theme, ThemeChoice.system);
      expect(settings.dynamicColors, isFalse);
      expect(settings.indexOnLeft, isFalse);
      expect(settings.pauseOnUnplug, isTrue);
      expect(settings.refreshOnStart, isTrue);
    });

    test('an empty store gives the defaults', () {
      expect(AppSettings.fromEntries(const {}), const AppSettings());
    });
  });

  /// @verifies FR-023.7
  group('reading', () {
    test('every setting comes back as it was written', () {
      const settings = AppSettings(
        theme: ThemeChoice.dark,
        dynamicColors: true,
        indexOnLeft: true,
        pauseOnUnplug: false,
        refreshOnStart: false,
      );

      final read = AppSettings.fromEntries(settings.toEntries());

      expect(read, settings);
    });

    test('each theme round-trips', () {
      for (final theme in ThemeChoice.values) {
        final read = AppSettings.fromEntries(
          AppSettings(theme: theme).toEntries(),
        );
        expect(read.theme, theme);
      }
    });

    test('an unknown theme gives the system theme', () {
      final read = AppSettings.fromEntries(const {SettingKey.theme: 'purple'});

      expect(read.theme, ThemeChoice.system);
    });

    test('a value that is not a boolean gives that setting its default', () {
      final read = AppSettings.fromEntries(const {
        SettingKey.dynamicColors: 'maybe',
        SettingKey.indexOnLeft: '',
        SettingKey.pauseOnUnplug: '1',
        SettingKey.refreshOnStart: 'null',
      });

      expect(read, const AppSettings());
    });

    test('one bad value does not spoil the others', () {
      final read = AppSettings.fromEntries(const {
        SettingKey.theme: '???',
        SettingKey.indexOnLeft: 'true',
        SettingKey.pauseOnUnplug: 'false',
      });

      expect(read.theme, ThemeChoice.system);
      expect(read.indexOnLeft, isTrue);
      expect(read.pauseOnUnplug, isFalse);
    });

    test('keys it does not know are ignored', () {
      final read = AppSettings.fromEntries(const {
        'resume_session': 'true',
        SettingKey.theme: 'light',
      });

      expect(read.theme, ThemeChoice.light);
    });
  });

  group('writing', () {
    test('writes every setting as text', () {
      final entries = const AppSettings(
        theme: ThemeChoice.light,
        indexOnLeft: true,
      ).toEntries();

      expect(entries, {
        SettingKey.theme: 'light',
        SettingKey.dynamicColors: 'false',
        SettingKey.indexOnLeft: 'true',
        SettingKey.pauseOnUnplug: 'true',
        SettingKey.refreshOnStart: 'true',
      });
    });

    test('only what changed has to be written', () {
      const before = AppSettings();
      final after = before.copyWith(
        theme: ThemeChoice.dark,
        pauseOnUnplug: false,
      );

      expect(after.changesFrom(before), {
        SettingKey.theme: 'dark',
        SettingKey.pauseOnUnplug: 'false',
      });
    });

    test('no change, nothing to write', () {
      expect(const AppSettings().changesFrom(const AppSettings()), isEmpty);
    });
  });

  group('value', () {
    test('copyWith changes one field and keeps the others', () {
      const settings = AppSettings(indexOnLeft: true);

      final next = settings.copyWith(theme: ThemeChoice.dark);

      expect(next.theme, ThemeChoice.dark);
      expect(next.indexOnLeft, isTrue);
    });

    test('equal settings are equal', () {
      expect(const AppSettings(), const AppSettings());
      expect(const AppSettings().hashCode, const AppSettings().hashCode);
      expect(
        const AppSettings(),
        isNot(const AppSettings(dynamicColors: true)),
      );
    });
  });
}
