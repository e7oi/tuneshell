import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/app.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/domain/library/ports/internal_audio_source.dart';
import 'package:tuneshell/domain/settings/app_settings.dart';
import 'package:tuneshell/platform/internal_storage.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

import '../fakes/fake_audio_engine.dart';
import '../fakes/fake_library.dart';
import '../fakes/fake_settings_store.dart';
import '../fakes/fake_storage.dart';

void main() {
  late FakeSettingsStore settingsStore;

  setUp(() => settingsStore = FakeSettingsStore());

  Future<void> pumpApp(
    WidgetTester tester,
    Locale locale, {
    AppSettings? settings,
    SystemSchemes? schemes,
  }) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final permission = FakeAudioPermission(AudioPermissionStatus.denied)
      ..answer = AudioPermissionStatus.denied;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(FakeLibraryRepository()),
          internalAudioSourceProvider.overrideWithValue(
            FakeInternalAudioSource(),
          ),
          audioPermissionProvider.overrideWithValue(permission),
          audioEngineProvider.overrideWithValue(FakeAudioEngine()),
          trackSourceOpenerProvider.overrideWithValue(FakeTrackSourceOpener()),
          volumeEventsProvider.overrideWithValue(InternalVolumeEvents()),
          settingsStoreProvider.overrideWithValue(settingsStore),
          systemSchemesProvider.overrideWith(
            (ref) async => schemes ?? (light: null, dark: null),
          ),
        ],
        child: const TuneShellApp(),
      ),
    );
    if (settings != null) {
      settingsStore.entries.addAll(settings.toEntries());
      await ProviderScope.containerOf(tester.element(find.byType(TuneShellApp)))
          .read(appSettingsProvider.notifier)
          .load();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('speaks French', (tester) async {
    await pumpApp(tester, const Locale('fr'));

    expect(find.text("Autoriser l'accès à ta musique"), findsOneWidget);
  });

  testWidgets('falls back to English for other locales', (tester) async {
    await pumpApp(tester, const Locale('de'));

    expect(find.text('Allow access to your music'), findsOneWidget);
  });

  /// @verifies FR-008.2
  testWidgets('follows the system theme', (tester) async {
    await pumpApp(tester, const Locale('en'));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);
  });

  /// @verifies FR-008.2
  testWidgets('turns dark with the system, without restarting', (tester) async {
    await pumpApp(tester, const Locale('en'));
    Brightness shown() =>
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness;
    expect(shown(), Brightness.light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();

    expect(shown(), Brightness.dark);
  });

  /// @verifies FR-014.7
  testWidgets('the first-launch screens are full screen, the library is not', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, const Locale('en'));

    expect(find.text('Allow access to your music'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Access to your music not granted'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  /// @verifies FR-024.1
  group('the theme chosen in the settings', () {
    ThemeMode mode(WidgetTester tester) =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

    testWidgets('dark is imposed whatever the system says', (tester) async {
      await pumpApp(
        tester,
        const Locale('en'),
        settings: const AppSettings(theme: ThemeChoice.dark),
      );

      expect(mode(tester), ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark,
      );
    });

    testWidgets('light is imposed too', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(
        tester,
        const Locale('en'),
        settings: const AppSettings(theme: ThemeChoice.light),
      );

      expect(mode(tester), ThemeMode.light);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.light,
      );
    });

    testWidgets('changing the setting changes the theme at once', (
      tester,
    ) async {
      await pumpApp(tester, const Locale('en'));
      expect(mode(tester), ThemeMode.system);

      ProviderScope.containerOf(tester.element(find.byType(TuneShellApp)))
          .read(appSettingsProvider.notifier)
          .setTheme(ThemeChoice.dark);
      await tester.pumpAndSettle();

      expect(mode(tester), ThemeMode.dark);
    });
  });

  /// @verifies FR-024.2
  /// @verifies FR-024.3
  group('the system colours', () {
    final wallpaper = ColorScheme.fromSeed(seedColor: const Color(0xFFAA3366));

    SystemSchemes with_(ColorScheme? light) => (light: light, dark: light);

    Color primary(WidgetTester tester) => tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .theme!
        .colorScheme
        .primary;

    testWidgets('used when the setting is on and Android has them', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Locale('en'),
        settings: const AppSettings(dynamicColors: true),
        schemes: with_(wallpaper),
      );

      expect(primary(tester), wallpaper.primary);
    });

    testWidgets('not used when the setting is off', (tester) async {
      await pumpApp(tester, const Locale('en'), schemes: with_(wallpaper));

      expect(primary(tester), TsSchemes.light.primary);
    });

    testWidgets('the design is kept when Android has none', (tester) async {
      await pumpApp(
        tester,
        const Locale('en'),
        settings: const AppSettings(dynamicColors: true),
        schemes: with_(null),
      );

      expect(primary(tester), TsSchemes.light.primary);
    });

    testWidgets('the fixed colours of the design stay', (tester) async {
      await pumpApp(
        tester,
        const Locale('en'),
        settings: const AppSettings(dynamicColors: true),
        schemes: with_(wallpaper),
      );

      final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
      expect(theme.extension<TsColors>(), TsColors.light);
    });
  });
}
