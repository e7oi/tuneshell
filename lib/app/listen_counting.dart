import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/providers/listening_providers.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/domain/playback/services/play_counter.dart';

/// Starts counting the listens (BR-014) and follows the setting (FR-031.5).
///
/// @implements BR-014
/// @implements FR-031
PlayCounter startListenCounting(ProviderContainer container) {
  final counter = container.read(playCounterProvider)..start();
  container.listen(
    appSettingsProvider.select((s) => s.recordHistory),
    (_, on) => counter.setEnabled(enabled: on),
  );
  return counter;
}
