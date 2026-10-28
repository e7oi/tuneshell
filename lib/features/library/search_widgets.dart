import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/features/library/library_search_state.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/search_field.dart';

/// The title of a view, with its search button; while the search is open the
/// field takes the place of the title (FR-027).
///
/// @implements FR-027
class SearchTitleBar extends ConsumerWidget {
  const new({
    required this.view,
    required this.title,
    required this.canSearch,
    super.key,
  });

  final SearchView view;
  final String title;

  /// False when the view has nothing to search (an empty library).
  final bool canSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = ref.watch(searchTextProvider(view));
    final search = ref.read(searchTextProvider(view).notifier);
    if (text != null) {
      return Padding(
        padding: const EdgeInsets.only(right: TsSpace.s),
        child: SearchField(
          text: text,
          hint: switch (view) {
            SearchView.tracks => l10n.searchHintTracks,
            SearchView.albums => l10n.searchHintAlbums,
            SearchView.artists => l10n.searchHintArtists,
          },
          clearLabel: l10n.searchClear,
          backLabel: l10n.searchClose,
          onChanged: search.update,
          onClose: search.close,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(
        left: TsSpace.screenMargin,
        right: TsSpace.s,
      ),
      child: SizedBox(
        height: TsSize.touchTarget + TsSpace.s,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.searchOpen,
              icon: const Icon(Icons.search_rounded),
              onPressed: canSearch ? search.open : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Says the count of results to TalkBack half a second after the last change
/// of the text, so that typing does not make it talk at each letter
/// (FR-027).
class ResultsAnnouncer extends StatefulWidget {
  const new({required this.text, required this.child, super.key});

  final String text;
  final Widget child;

  @override
  State<ResultsAnnouncer> createState() => _ResultsAnnouncerState();
}

class _ResultsAnnouncerState extends State<ResultsAnnouncer> {
  static const _delay = Duration(milliseconds: 500);

  String _spoken = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _spoken = widget.text;
  }

  @override
  void didUpdateWidget(ResultsAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text) return;
    _timer?.cancel();
    _timer = Timer(_delay, () {
      if (mounted) setState(() => _spoken = widget.text);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: _spoken,
    child: ExcludeSemantics(child: widget.child),
  );
}

/// Nothing matches: the text searched, and the way out (FR-027).
class SearchNoResults extends StatelessWidget {
  const new({required this.query, required this.onClear, super.key});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TsSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.searchNoResults(query.trim()),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TsSpace.l),
            OutlinedButton(
              onPressed: onClear,
              child: Text(l10n.searchClearAction),
            ),
          ],
        ),
      ),
    );
  }
}
