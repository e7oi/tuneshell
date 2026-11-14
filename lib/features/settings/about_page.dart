import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/domain/settings/app_info.dart';
import 'package:tuneshell/features/settings/build_identity.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/settings_tiles.dart';

/// The about page (FR-026.2): version, licence, where the source code is, and
/// the licences of the components that Flutter lists.
///
/// @implements FR-026
/// @implements FR-034
class AboutPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = buildIdentity(
      AppLocalizations.of(context),
      appVersion,
      ref.watch(buildInfoProvider),
    );
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: TsSize.settingsMaxWidth),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: TsSpace.l),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TsSpace.screenMargin,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TuneShell', style: text.headlineSmall),
                    SelectableText(
                      l10n.settingsAbout(identity),
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: TsSpace.s),
                    Text(
                      l10n.aboutCopyright,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: TsSpace.l),
                    Text(l10n.aboutLicense, style: text.bodyLarge),
                    const SizedBox(height: TsSpace.l),
                    Text(l10n.aboutSource, style: text.labelLarge),
                    const SelectableText(sourceCodeUrl),
                  ],
                ),
              ),
              const SizedBox(height: TsSpace.l),
              SettingsNavTile(
                title: l10n.aboutLicenses,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'TuneShell',
                  applicationVersion: identity,
                  applicationLegalese: l10n.aboutCopyright,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
