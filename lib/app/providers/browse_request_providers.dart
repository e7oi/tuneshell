import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The tab that shows the group a request opens.
enum BrowseTab { albums, artists }

/// A request to open the detail of an album or of an artist in its tab. It
/// carries the key of the group (BR-010) and nothing else (ADR-022).
@immutable
final class BrowseRequest {
  const new({required this.tab, required this.key});

  final BrowseTab tab;
  final String key;

  @override
  bool operator ==(Object other) =>
      other is BrowseRequest && other.tab == tab && other.key == key;

  @override
  int get hashCode => Object.hash(tab, key);
}

/// Written by a screen above the tabs (the full-screen player), read and
/// cleared by the shell, which owns the navigators of the tabs.
///
/// @decision ADR-022
class BrowseRequests extends Notifier<BrowseRequest?> {
  @override
  BrowseRequest? build() => null;

  void open(BrowseTab tab, String key) =>
      state = BrowseRequest(tab: tab, key: key);

  void clear() => state = null;
}

final browseRequestProvider = NotifierProvider<BrowseRequests, BrowseRequest?>(
  BrowseRequests.new,
);
