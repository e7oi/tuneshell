import 'package:flutter/material.dart';
import 'package:tuneshell/features/library/library_list_providers.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// The pastilles under the title of the Tracks view: all, favorites, recent
/// (FR-031.1). One choice at a time; the state is read out by TalkBack.
///
/// @implements FR-031
class TrackFilterChips extends StatelessWidget {
  const new({required this.selected, required this.onSelected, super.key});

  final TrackFilter selected;
  final ValueChanged<TrackFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      TrackFilter.all: l10n.filterAll,
      TrackFilter.favorites: l10n.filterFavorites,
      TrackFilter.recent: l10n.filterRecent,
    };
    return Semantics(
      container: true,
      label: l10n.filterGroupLabel,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TsSpace.screenMargin),
        child: Wrap(
          spacing: TsSpace.s,
          children: [
            for (final filter in TrackFilter.values)
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: TsSize.touchTarget,
                ),
                child: Center(
                  child: ChoiceChip(
                    label: Text(labels[filter]!),
                    selected: selected == filter,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: (_) => onSelected(filter),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The message of a pastille with nothing to show (FR-031.5).
class TrackFilterEmpty extends StatelessWidget {
  const new({required this.filter, required this.historyOff, super.key});

  final TrackFilter filter;

  /// The history is turned off, which the Recent message then says.
  final bool historyOff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final favorites = filter == TrackFilter.favorites;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TsSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              favorites ? Icons.favorite_border_rounded : Icons.history_rounded,
              size: TsSize.coverPanel / 2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: TsSpace.l),
            Text(
              favorites ? l10n.emptyFavoritesTitle : l10n.emptyRecentTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TsSpace.s),
            Text(
              favorites
                  ? l10n.emptyFavoritesBody
                  : historyOff
                  ? l10n.emptyRecentOffBody
                  : l10n.emptyRecentBody,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
