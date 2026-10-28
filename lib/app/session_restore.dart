import 'package:flutter/foundation.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/playback/ports/playback_session_store.dart';
import 'package:tuneshell/domain/playback/services/player_controller.dart';
import 'package:tuneshell/domain/playback/services/session_keeper.dart';

/// Puts the stored playback session back in the controller at launch
/// (BR-012, rules 5 to 12), paused and with nothing loaded.
///
/// [libraryTracks] reads the tracks the library knows from the database,
/// once; entries that are not among them are dropped. A library that has no
/// track yet (first launch, nothing indexed) restores nothing and keeps the
/// stored session for later. Any problem leaves the controller empty: the
/// application starts as it did before.
///
/// @implements BR-012
Future<void> restorePlaybackSession({
  required PlayerController controller,
  required PlaybackSessionStore store,
  required SessionKeeper keeper,
  required Future<Set<Track>> Function() libraryTracks,
  required bool enabled,
}) async {
  try {
    if (!enabled) {
      await store.clear();
      return;
    }
    final session = await store.read();
    if (session == null) {
      await store.clear();
      return;
    }
    final known = await libraryTracks();
    if (known.isEmpty) return;
    final kept = session.keeping(known.contains);
    if (kept == null) {
      await store.clear();
      return;
    }
    final restored = await controller.restore(kept);
    // What was stored is what is in the controller: nothing to write again.
    if (restored && kept.queue.length == session.queue.length) keeper.adopt();
  } on Object catch (error) {
    debugPrint(
      'session: cannot restore the playback session: ${error.runtimeType}',
    );
  }
}
