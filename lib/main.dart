import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/app/app.dart';
import 'package:tuneshell/app/licenses.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/app/system_playback.dart';
import 'package:tuneshell/data/audio/media_kit_audio_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKitAudioEngine.ensureInitialized();
  registerLicenses();
  // One container shared by the screens and the media session.
  final container = ProviderContainer();
  // Read before the first screen, so that the chosen theme never flashes
  // (FR-023.6).
  await container.read(appSettingsProvider.notifier).load();
  await startSystemPlayback(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TuneShellApp(),
    ),
  );
}
