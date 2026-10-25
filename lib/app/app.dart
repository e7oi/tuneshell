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

/// The theme follows the settings: the mode (FR-024.1) and, when asked and
/// available, the system colours in place of the design's (FR-024.2).
///
/// @implements FR-008.2
/// @implements FR-024
class TuneShellApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final system = ref.watch(systemSchemesProvider).value;
    return _app(
      themeMode: switch (settings.theme) {
        ThemeChoice.system => ThemeMode.system,
        ThemeChoice.light => ThemeMode.light,
        ThemeChoice.dark => ThemeMode.dark,
      },
      light: settings.dynamicColors ? system?.light : null,
      dark: settings.dynamicColors ? system?.dark : null,
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
