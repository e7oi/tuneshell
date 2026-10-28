import 'package:flutter/material.dart';
import 'package:tuneshell/features/library/library_list_model.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/status_banner.dart';

/// The banner of unavailable sources (BR-008, rules 2 and 3).
class SourcesBanner extends StatelessWidget {
  const new({
    required this.banner,
    required this.onSee,
    required this.onDismiss,
    super.key,
  });

  final SourceBanner banner;
  final VoidCallback onSee;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StatusBanner(
      kind: BannerKind.warning,
      message: bannerText(l10n, banner),
      actionLabel: l10n.bannerSee,
      onAction: onSee,
      dismissTooltip: l10n.bannerDismiss,
      onDismiss: onDismiss,
    );
  }
}

/// "12 tracks skipped: SSD missing", or the forms for several disks and for
/// a lost access (BR-008, rule 2).
String bannerText(AppLocalizations l10n, SourceBanner banner) {
  final disks = banner.disks;
  if (disks.length == 1) {
    final disk = disks.single;
    return disk.issue == DiskIssue.absent
        ? l10n.bannerAbsentOne(banner.tracks, disk.label)
        : l10n.bannerAccessOne(banner.tracks, disk.label);
  }
  return disks.every((d) => d.issue == DiskIssue.absent)
      ? l10n.bannerAbsentMany(banner.tracks, disks.length)
      : l10n.bannerOther(banner.tracks, disks.length);
}

/// "2 600 tracks · 12 unavailable" and the label of the sort (FR-011.5).
class LibraryCountRow extends StatelessWidget {
  const new({required this.text, this.showSort = true, super.key});

  final String text;
  final bool showSort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TsSpace.screenMargin,
        vertical: TsSpace.s,
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: style)),
          if (showSort) Text(l10n.librarySortTitle, style: style),
        ],
      ),
    );
  }
}
