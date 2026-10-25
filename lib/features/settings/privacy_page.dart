import 'package:flutter/material.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// The privacy page (FR-026.4): nothing collected, no account, no network;
/// what stays on the phone; what Android is asked for and why.
///
/// @implements FR-026
class PrivacyPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    Widget heading(String label) => Padding(
      padding: const EdgeInsets.only(top: TsSpace.l, bottom: TsSpace.xs),
      child: Semantics(
        header: true,
        child: Text(label, style: text.titleMedium),
      ),
    );
    Widget bullet(String label) => Padding(
      padding: const EdgeInsets.only(bottom: TsSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: text.bodyLarge),
          Expanded(child: Text(label, style: text.bodyLarge)),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: TsSize.settingsMaxWidth),
          child: ListView(
            padding: const EdgeInsets.all(TsSpace.screenMargin),
            children: [
              Text(l10n.privacyIntro, style: text.titleLarge),
              heading(l10n.privacyStaysTitle),
              Text(l10n.privacyStaysBody, style: text.bodyLarge),
              heading(l10n.privacyAsksTitle),
              bullet(l10n.privacyAskFiles),
              bullet(l10n.privacyAskNotification),
              bullet(l10n.privacyAskFolders),
            ],
          ),
        ),
      ),
    );
  }
}
