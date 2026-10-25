import 'package:tuneshell/features/library/library_controller.dart';

/// What the screens asked of a [FakeLibraryController].
class LibraryCalls {
  int refreshes = 0;
  int confirmed = 0;
  Set<String>? confirmedFolders;
  int choiceOpened = 0;
}

/// A [LibraryController] that only counts what the screens ask of it.
class FakeLibraryController extends LibraryController {
  new(this._initial, this._calls, {this._withoutAccess = false});

  final LibraryViewState _initial;
  final LibraryCalls _calls;
  final bool _withoutAccess;

  @override
  LibraryViewState build() => _initial;

  /// Lets a test change what the screens see.
  // ignore: use_setters_to_change_properties, a notifier has no public setter
  void emit(LibraryViewState next) => state = next;

  @override
  bool withoutPhoneAccess() => _withoutAccess;

  @override
  Future<void> refresh() async => _calls.refreshes++;

  @override
  Future<void> confirmFolders(Set<String> folders) async {
    _calls.confirmed++;
    _calls.confirmedFolders = folders;
  }

  @override
  Future<void> openFolderChoice() async => _calls.choiceOpened++;
}
