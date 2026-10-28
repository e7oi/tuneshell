import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/gesture_providers.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/domain/library/services/removable_indexer.dart';
import 'package:tuneshell/domain/settings/app_info.dart';
import 'package:tuneshell/domain/settings/app_settings.dart';
import 'package:tuneshell/features/library/folder_choice_page.dart';
import 'package:tuneshell/features/library/library_controller.dart';
import 'package:tuneshell/features/library/removable_controller.dart';
import 'package:tuneshell/features/library/removable_page.dart';
import 'package:tuneshell/features/settings/about_page.dart';
import 'package:tuneshell/features/settings/privacy_page.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/demo/component_gallery.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/settings_tiles.dart';

/// The Settings view (FR-023, UC-009): four sections of lines that open a
/// page, switch something or choose among a few values. In debug and profile
/// builds it also offers the component gallery (FR-010.7).
///
/// @implements FR-023
/// @implements FR-024
/// @implements FR-025
/// @implements FR-026
class SettingsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final dynamicSupported = ref.watch(dynamicColorsSupportedProvider);
    final indexing = ref.watch(
      libraryControllerProvider.select(
        (state) => state is LibraryReady && state.indexing,
      ),
    );
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TsSpace.screenMargin,
            ),
            child: SizedBox(
              height: TsSize.touchTarget + TsSpace.s,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.navSettings,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: TsSize.settingsMaxWidth,
                ),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: TsSpace.xl),
                  children: [
                    SettingsSectionHeader(l10n.settingsSectionLibrary),
                    const _FoldersTile(),
                    const _DisksTile(),
                    SettingsNavTile(
                      title: l10n.settingsRefreshNow,
                      subtitle: l10n.settingsRefreshNowSub,
                      showArrow: false,
                      enabled: !indexing,
                      onTap: () => unawaited(
                        ref.read(libraryControllerProvider.notifier).refresh(),
                      ),
                    ),
                    SettingsSwitchTile(
                      title: l10n.settingsRefreshStart,
                      subtitle: l10n.settingsRefreshStartSub,
                      value: settings.refreshOnStart,
                      onChanged: (on) =>
                          notifier.setRefreshOnStart(enabled: on),
                    ),
                    SettingsSectionHeader(l10n.settingsSectionAppearance),
                    SettingsSegmentedTile<ThemeChoice>(
                      title: l10n.settingsTheme,
                      choices: [
                        (ThemeChoice.system, l10n.settingsThemeSystem),
                        (ThemeChoice.light, l10n.settingsThemeLight),
                        (ThemeChoice.dark, l10n.settingsThemeDark),
                      ],
                      selected: settings.theme,
                      onChanged: notifier.setTheme,
                    ),
                    SettingsSwitchTile(
                      title: l10n.settingsDynamic,
                      subtitle: dynamicSupported
                          ? l10n.settingsDynamicSub
                          : l10n.settingsDynamicUnavailable,
                      value: settings.dynamicColors && dynamicSupported,
                      enabled: dynamicSupported,
                      onChanged: (on) => notifier.setDynamicColors(enabled: on),
                    ),
                    SettingsSwitchTile(
                      title: l10n.settingsIndexLeft,
                      subtitle: l10n.settingsIndexLeftSub,
                      value: settings.indexOnLeft,
                      onChanged: (on) => notifier.setIndexOnLeft(enabled: on),
                    ),
                    SettingsSectionHeader(l10n.settingsSectionPlayback),
                    SettingsSwitchTile(
                      title: l10n.settingsPauseUnplug,
                      subtitle: l10n.settingsPauseUnplugSub,
                      value: settings.pauseOnUnplug,
                      onChanged: (on) => notifier.setPauseOnUnplug(enabled: on),
                    ),
                    SettingsSectionHeader(l10n.settingsSectionAbout),
                    SettingsNavTile(
                      title: l10n.settingsAbout(appVersion),
                      subtitle: l10n.settingsAboutSub,
                      onTap: () => _open(context, const AboutPage()),
                    ),
                    SettingsNavTile(
                      title: l10n.settingsPrivacy,
                      subtitle: l10n.settingsPrivacySub,
                      onTap: () => _open(context, const PrivacyPage()),
                    ),
                    if (kDebugMode || kProfileMode)
                      SettingsNavTile(
                        title: l10n.demoGallery,
                        onTap: () => _open(
                          context,
                          ComponentGallery(
                            // FR-010.5: the handle keeps the Back gesture out.
                            onHandleRect: (rect) {
                              final ratio = View.of(context).devicePixelRatio;
                              unawaited(
                                ref.read(gestureRegionsProvider).set(
                                  'gallery',
                                  [
                                    if (rect != null)
                                      Rect.fromLTRB(
                                        rect.left * ratio,
                                        rect.top * ratio,
                                        rect.right * ratio,
                                        rect.bottom * ratio,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _open(BuildContext context, Widget page) {
  Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => page));
}

/// "Dossiers de musique" (FR-025.1): the folder choice as a page, or, without
/// access to the phone's audio, the explanation of the access.
class _FoldersTile extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chosen = ref.watch(chosenFoldersProvider).value;
    final names = [...?chosen]..sort();
    final summary = chosen == null
        ? null
        : names.isEmpty
        ? l10n.settingsFoldersNone
        : l10n.settingsFoldersSummary(
            names.length,
            [
              for (final name in names.take(2))
                if (name.isEmpty) l10n.foldersRoot else name,
              if (names.length > 2) '…',
            ].join(', '),
          );
    final indexing = ref.watch(
      libraryControllerProvider.select(
        (state) => state is LibraryReady && state.indexing,
      ),
    );
    return SettingsNavTile(
      title: l10n.foldersTitle,
      subtitle: summary,
      enabled: !indexing,
      onTap: () => unawaited(openFolderChoice(context, ref)),
    );
  }
}

/// "Disques amovibles" (FR-025.2): the disks screen, with the state of the
/// disks on the line itself.
class _DisksTile extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final disks = ref.watch(
      removableControllerProvider.select((state) => state.disks),
    );
    String stateOf(RemovableStatus status) => switch (status) {
      RemovableStatus.available => l10n.removableAvailable,
      RemovableStatus.absent => l10n.removableAbsent,
      RemovableStatus.accessLost => l10n.removableAccessLost,
    };
    final lost = disks
        .where((disk) => disk.status != RemovableStatus.available)
        .length;
    return SettingsNavTile(
      title: l10n.removableTitle,
      subtitle: switch (disks.length) {
        0 => l10n.settingsDisksNone,
        1 => l10n.settingsDiskState(
          disks.single.disk.label,
          stateOf(disks.single.status),
        ),
        final count => l10n.settingsDisksMany(count),
      },
      badge: lost == 0 ? null : l10n.disksAbsentBadge(lost),
      onTap: () => _open(context, const RemovablePage()),
    );
  }
}
