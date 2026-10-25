import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/features/library/folder_choice_view.dart';
import 'package:tuneshell/features/library/library_controller.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';

/// Opens the choice of the phone's music folders from the settings or from an
/// empty library: as a page, or, without access to the phone's audio, as the
/// explanation of the access (FR-025.1, FR-014.5).
Future<void> openFolderChoice(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(libraryControllerProvider.notifier);
  final state = ref.read(libraryControllerProvider);
  // A choice made while the library is indexed would only queue a second
  // index behind the first one (FR-025.1).
  if (state is LibraryReady && state.indexing) return;
  if (controller.withoutPhoneAccess()) {
    await controller.openFolderChoice();
    return;
  }
  await Navigator.of(context)
      .push<void>(MaterialPageRoute(builder: (_) => const FolderChoicePage()));
  ref.invalidate(chosenFoldersProvider);
}

/// The choice of the phone's music folders, as a page opened from the
/// settings (FR-025.1, ADR-017). "Confirm" or Back closes it; confirming
/// indexes the library.
///
/// @implements FR-025
class FolderChoicePage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<FolderChoicePage> createState() => _FolderChoicePageState();
}

class _FolderChoicePageState extends ConsumerState<FolderChoicePage> {
  LibraryFolderChoice _choice = const LibraryFolderChoice(
    folders: [],
    selected: {},
    cancelable: true,
    loading: true,
  );
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _failed = false;
      _choice = const LibraryFolderChoice(
        folders: [],
        selected: {},
        cancelable: true,
        loading: true,
      );
    });
    try {
      final indexer = ref.read(libraryIndexerProvider);
      final folders = await indexer.availableFolders();
      final selected = await indexer.chosenFolders();
      if (!mounted) return;
      setState(
        () => _choice = LibraryFolderChoice(
          folders: folders,
          selected: selected,
          cancelable: true,
        ),
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _confirm(Set<String> folders) {
    final controller = ref.read(libraryControllerProvider.notifier);
    Navigator.of(context).pop();
    unawaited(controller.confirmFolders(folders));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.foldersTitle)),
      body: _failed
          ? FolderLoadFailedView(onRetry: () => unawaited(_load()))
          : FolderChoiceView(
              key: ValueKey(_choice),
              choice: _choice,
              onConfirm: _confirm,
              onAddFolder: () => unawaited(
                ref
                    .read(libraryControllerProvider.notifier)
                    .addRemovableFolder(),
              ),
              onReload: () => unawaited(_load()),
            ),
    );
  }
}
