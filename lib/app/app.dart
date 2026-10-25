import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/domain/settings/app_settings.dart';
import 'package:tuneshell/features/browse/albums_view.dart';
import 'package:tuneshell/features/browse/artists_view.dart';
import 'package:tuneshell/features/library/library_controller.dart';
import 'package:tuneshell/features/library/library_page.dart';
import 'package:tuneshell/features/player/mini_player_bar.dart';
import 'package:tuneshell/features/settings/settings_page.dart';
import 'package:tuneshell/features/shell/home_shell.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// Gives its builder the light and dark colour schemes Android derives from
/// the wallpaper, or null for each when it has none (FR-024.3).
typedef DynamicSchemesBuilder = Widget Function(
  Widget Function(ColorScheme? light, ColorScheme? dark) builder,
);

Widget _systemSchemes(
  Widget Function(ColorScheme? light, ColorScheme? dark) builder,
) => DynamicColorBuilder(builder: builder);

/// The theme follows the settings: the mode (FR-024.1) and, when asked and
/// available, the system colours in place of the design's (FR-024.2).
///
/// @implements FR-008.2
/// @implements FR-024
class TuneShellApp extends ConsumerWidget {
  const new({this.dynamicSchemes = _systemSchemes, super.key});

  /// Where the system colours come from; the tests give their own.
  final DynamicSchemesBuilder dynamicSchemes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return dynamicSchemes(
      (light, dark) => _app(
        themeMode: switch (settings.theme) {
          ThemeChoice.system => ThemeMode.system,
          ThemeChoice.light => ThemeMode.light,
          ThemeChoice.dark => ThemeMode.dark,
        },
        light: settings.dynamicColors ? light : null,
        dark: settings.dynamicColors ? dark : null,
      ),
    );
  }

  Widget _app({
    required ThemeMode themeMode,
    ColorScheme? light,
    ColorScheme? dark,
  }) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    themeMode: themeMode,
    theme: TsTheme.light(dynamicScheme: light),
    darkTheme: TsTheme.dark(dynamicScheme: dark),
    home: Consumer(
      builder: (context, ref, _) => HomeShell(
        immersive: ref.watch(
          libraryControllerProvider.select(isFirstLaunchScreen),
        ),
        tracks: const LibraryPage(),
        albums: const AlbumsView(),
        artists: const ArtistsView(),
        settings: const SettingsPage(),
        playerBar: const MiniPlayerBar(),
      ),
    ),
  );
}
