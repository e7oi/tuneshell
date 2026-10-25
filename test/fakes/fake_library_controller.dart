import 'package:tuneshell/features/library/library_controller.dart';

/// A [LibraryController] that only counts what the screens ask of it.
class FakeLibraryController extends LibraryController {
  new(this._initial, {this.withoutAccess = false});

  final LibraryViewState _initial;
  final bool withoutAccess;
  int refreshes = 0;
  int confirmed = 0;
  Set<String>? confirmedFolders;
  int choiceOpened = 0;

  @override
  LibraryViewState build() => _initial;

  @override
  bool get withoutPhoneAccess => withoutAccess;

  @override
  Future<void> refresh() async => refreshes++;

  @override
  Future<void> confirmFolders(Set<String> folders) async {
    confirmed++;
    confirmedFolders = folders;
  }

  @override
  Future<void> openFolderChoice() async => choiceOpened++;
}
