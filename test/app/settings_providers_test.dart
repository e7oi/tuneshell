import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/domain/settings/app_settings.dart';

import '../fakes/fake_settings_store.dart';

void main() {
  late FakeSettingsStore store;
  late ProviderContainer container;

  ProviderContainer make() {
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    store = FakeSettingsStore();
    container = make();
  });

  AppSettings settings() => container.read(appSettingsProvider);
  AppSettingsNotifier notifier() =>
      container.read(appSettingsProvider.notifier);

  /// @verifies FR-023.6
  group('loading', () {
    test('before it is read, the defaults', () {
      expect(settings(), const AppSettings());
    });

    test('puts the stored settings in place', () async {
      store = FakeSettingsStore({
        SettingKey.theme: 'dark',
        SettingKey.indexOnLeft: 'true',
      });
      container = make();

      await notifier().load();

      expect(settings().theme, ThemeChoice.dark);
      expect(settings().indexOnLeft, isTrue);
    });

    test('a storage that cannot be read gives the defaults', () async {
      store = FakeSettingsStore()..failure = Exception('disk');
      container = make();

      await notifier().load();

      expect(settings(), const AppSettings());
    });

    test('damaged values give the defaults, setting by setting', () async {
      store = FakeSettingsStore({
        SettingKey.theme: '###',
        SettingKey.pauseOnUnplug: 'false',
      });
      container = make();

      await notifier().load();

      expect(settings().theme, ThemeChoice.system);
      expect(settings().pauseOnUnplug, isFalse);
    });
  });

  /// @verifies FR-023.5
  group('changing', () {
    test('the new value is there at once', () {
      notifier().setTheme(ThemeChoice.dark);

      expect(settings().theme, ThemeChoice.dark);
    });

    test('only what changed is written', () async {
      notifier()
        ..setTheme(ThemeChoice.light)
        ..setIndexOnLeft(enabled: true);
      await pumpEventQueue();

      expect(store.writes, [
        '${SettingKey.theme}=light',
        '${SettingKey.indexOnLeft}=true',
      ]);
    });

    test('setting the same value writes nothing', () async {
      notifier().setPauseOnUnplug(enabled: true);
      await pumpEventQueue();

      expect(store.writes, isEmpty);
    });

    test('a write that fails does not undo what is shown', () async {
      store.failure = Exception('disk full');

      notifier().setDynamicColors(enabled: true);
      await pumpEventQueue();

      expect(settings().dynamicColors, isTrue);
    });

    test('what was written is read back at the next start', () async {
      notifier()
        ..setTheme(ThemeChoice.dark)
        ..setRefreshOnStart(enabled: false);
      await pumpEventQueue();

      container = make();
      await notifier().load();

      expect(settings().theme, ThemeChoice.dark);
      expect(settings().refreshOnStart, isFalse);
    });

    test('each setting has its own setter', () {
      notifier()
        ..setTheme(ThemeChoice.light)
        ..setDynamicColors(enabled: true)
        ..setIndexOnLeft(enabled: true)
        ..setPauseOnUnplug(enabled: false)
        ..setRefreshOnStart(enabled: false);

      expect(
        settings(),
        const AppSettings(
          theme: ThemeChoice.light,
          dynamicColors: true,
          indexOnLeft: true,
          pauseOnUnplug: false,
          refreshOnStart: false,
        ),
      );
    });
  });
}
