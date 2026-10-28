import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/settings_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/services/removable_indexer.dart';
import 'package:tuneshell/domain/settings/app_settings.dart';
import 'package:tuneshell/features/library/library_controller.dart';
import 'package:tuneshell/features/library/removable_controller.dart';
import 'package:tuneshell/features/settings/settings_page.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

import '../../fakes/fake_library.dart';
import '../../fakes/fake_library_controller.dart';
import '../../fakes/fake_settings_store.dart';

class _Removable extends RemovableController {
  new(this._disks);

  final List<RemovableDisk> _disks;

  @override
  RemovableViewState build() => RemovableViewState(disks: _disks);

  @override
  Future<void> onResumed() async {}
}

RemovableDisk disk(String label, RemovableStatus status) => RemovableDisk(
  disk: Disk(
    id: DiskId(label),
    label: label,
    kind: DiskKind.removable,
    markIndex: 0,
  ),
  folders: const {},
  status: status,
);

void main() {
  late FakeSettingsStore store;
  late LibraryCalls library;
  late FakeInternalAudioSource source;
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    Set<String> folders = const {'Music'},
    List<RemovableDisk> disks = const [],
    bool dynamicSupported = true,
    bool indexing = false,
    bool withoutAccess = false,
    Locale locale = const Locale('en'),
  }) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    store = FakeSettingsStore();
    library = LibraryCalls();
    source = FakeInternalAudioSource()
      ..files = [
        info('Music/a.mp3', title: 'A'),
        info('Download/b.mp3', title: 'B'),
      ];
    container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        chosenFoldersProvider.overrideWith((ref) => folders),
        dynamicColorsSupportedProvider.overrideWith((ref) => dynamicSupported),
        libraryControllerProvider.overrideWith(
          () => FakeLibraryController(
            LibraryReady(hasFolders: true, indexing: indexing),
            library,
            withoutAccess: withoutAccess,
          ),
        ),
        removableControllerProvider.overrideWith(() => _Removable(disks)),
        libraryRepositoryProvider.overrideWithValue(FakeLibraryRepository()),
        internalAudioSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: TsTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: const Scaffold(body: SettingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppSettings settings() => container.read(appSettingsProvider);

  Future<void> scrollTo(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(find.text(text), 200);
    await tester.pumpAndSettle();
  }

  /// @verifies FR-023.1
  /// @verifies FR-023.2
  testWidgets('four sections, and only the settings that work', (tester) async {
    await pump(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('LIBRARY'), findsOneWidget);
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('PLAYBACK'), findsOneWidget);
    await scrollTo(tester, 'Privacy');
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('Resume where I left off'), findsOneWidget);
    expect(find.textContaining('short files'), findsNothing);
  });

  testWidgets('French, word for word', (tester) async {
    await pump(tester, locale: const Locale('fr'));

    expect(find.text('Dossiers de musique'), findsOneWidget);
    expect(find.text('Disques amovibles'), findsOneWidget);
    expect(find.text('Actualiser au démarrage'), findsOneWidget);
    expect(
      find.text('Cherche les nouveaux fichiers à chaque ouverture'),
      findsOneWidget,
    );
    expect(find.text('Thème'), findsOneWidget);
    expect(find.text("Couleurs du fond d'écran"), findsOneWidget);
    expect(find.text('Index alphabétique à gauche'), findsOneWidget);
    await scrollTo(tester, 'Pause si le casque est débranché');
    expect(find.text("Reprendre là où j'en étais"), findsOneWidget);
    expect(
      find.text("Restaure la file d'attente au démarrage"),
      findsOneWidget,
    );
    expect(
      find.text(
        'Recommandé · câble débranché ou Bluetooth déconnecté, '
        'pas la détection de port des écouteurs',
      ),
      findsOneWidget,
    );
  });

  /// @verifies FR-023.4
  testWidgets('the defaults are shown', (tester) async {
    await pump(tester);

    bool on(String title) => tester
        .widget<Switch>(
          find.descendant(
            of: find.ancestor(
              of: find.text(title),
              matching: find.byType(InkWell),
            ),
            matching: find.byType(Switch),
          ),
        )
        .value;
    expect(on('Refresh at start'), isTrue);
    expect(on('Wallpaper colours'), isFalse);
    expect(on('Alphabet index on the left'), isFalse);
    await scrollTo(tester, 'Pause when headphones are unplugged');
    expect(on('Pause when headphones are unplugged'), isTrue);
  });

  /// @verifies FR-024.1
  testWidgets('choosing a theme changes the setting and writes it', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(settings().theme, ThemeChoice.dark);
    expect(store.writes, ['${SettingKey.theme}=dark']);
  });

  /// @verifies FR-024.4
  testWidgets('the left index switch', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Alphabet index on the left'));
    await tester.pumpAndSettle();

    expect(settings().indexOnLeft, isTrue);
  });

  /// @verifies FR-025.7
  testWidgets('the pause on unplug switch', (tester) async {
    await pump(tester);
    await scrollTo(tester, 'Pause when headphones are unplugged');

    await tester.tap(find.text('Pause when headphones are unplugged'));
    await tester.pumpAndSettle();

    expect(settings().pauseOnUnplug, isFalse);
  });

  /// @verifies FR-028
  testWidgets('the resume playback switch is on and can be turned off', (
    tester,
  ) async {
    await pump(tester);
    await scrollTo(tester, 'Resume where I left off');
    expect(find.text('Restores the queue at start'), findsOneWidget);
    expect(settings().resumePlayback, isTrue);

    await tester.tap(find.text('Resume where I left off'));
    await tester.pumpAndSettle();

    expect(settings().resumePlayback, isFalse);
  });

  /// @verifies FR-025.6
  testWidgets('the refresh at start switch', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Refresh at start'));
    await tester.pumpAndSettle();

    expect(settings().refreshOnStart, isFalse);
  });

  /// @verifies FR-024.2
  testWidgets('wallpaper colours can be switched on where Android has them', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Wallpaper colours'));
    await tester.pumpAndSettle();

    expect(settings().dynamicColors, isTrue);
  });

  /// @verifies FR-024.3
  testWidgets('wallpaper colours are greyed, and say why, before Android 12', (
    tester,
  ) async {
    await pump(tester, dynamicSupported: false);

    expect(find.text('Android 12 or later'), findsOneWidget);
    await tester.tap(find.text('Wallpaper colours'));
    await tester.pumpAndSettle();
    expect(settings().dynamicColors, isFalse);
  });

  /// @verifies FR-025.1
  group('music folders', () {
    testWidgets('the line says how many and which', (tester) async {
      await pump(tester, folders: {'Music', 'Download', 'Podcasts'});

      expect(find.text('3 folders · Download, Music, …'), findsOneWidget);
    });

    testWidgets('no folder', (tester) async {
      await pump(tester, folders: const {});

      expect(find.text('No folder'), findsOneWidget);
    });

    testWidgets('opens the choice as a page, and confirming closes it', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Music folders'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.text('Download').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(library.confirmed, 1);
      expect(library.confirmedFolders, contains('Download'));
    });

    testWidgets('Back leaves the choice unchanged', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Music folders'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(library.confirmed, 0);
    });

    testWidgets('waits while the library is being indexed', (tester) async {
      await pump(tester, indexing: true);

      await tester.tap(find.text('Music folders'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsNothing);
      expect(library.choiceOpened, 0);
    });

    testWidgets('without access to the audio, the explanation comes first', (
      tester,
    ) async {
      await pump(tester, withoutAccess: true);

      await tester.tap(find.text('Music folders'));
      await tester.pumpAndSettle();

      expect(library.choiceOpened, 1);
      expect(find.text('Confirm'), findsNothing);
    });
  });

  /// @verifies FR-025.2
  group('removable disks', () {
    testWidgets('none', (tester) async {
      await pump(tester);

      expect(find.text('No disk'), findsOneWidget);
      expect(find.textContaining('missing'), findsNothing);
    });

    testWidgets('one connected disk', (tester) async {
      await pump(tester, disks: [disk('Disk A', RemovableStatus.available)]);

      expect(find.text('Disk A · Connected'), findsOneWidget);
    });

    testWidgets('one absent disk shows a badge in words', (tester) async {
      await pump(tester, disks: [disk('Disk A', RemovableStatus.absent)]);

      expect(find.text('Disk A · Not connected'), findsOneWidget);
      expect(find.text('1 missing'), findsOneWidget);
    });

    testWidgets('several disks', (tester) async {
      await pump(
        tester,
        disks: [
          disk('A', RemovableStatus.available),
          disk('B', RemovableStatus.accessLost),
        ],
      );

      expect(find.text('2 disks'), findsOneWidget);
      expect(find.text('1 missing'), findsOneWidget);
    });

    testWidgets('opens the disks screen', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Removable disks'));
      await tester.pumpAndSettle();

      expect(find.text('Add a folder'), findsWidgets);
    });
  });

  /// @verifies FR-025.5
  group('refresh now', () {
    testWidgets('refreshes the library', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Refresh now'));
      await tester.pump();

      expect(library.refreshes, 1);
    });

    testWidgets('waits while the library is being indexed', (tester) async {
      await pump(tester, indexing: true);

      await tester.tap(find.text('Refresh now'));
      await tester.pump();

      expect(library.refreshes, 0);
    });
  });

  /// @verifies FR-026.1
  /// @verifies FR-026.2
  testWidgets('the about page', (tester) async {
    await pump(tester);
    await scrollTo(tester, 'TuneShell 0.1.0');

    await tester.tap(find.text('TuneShell 0.1.0'));
    await tester.pumpAndSettle();

    expect(find.text('© 2026 Eloi BERTIN'), findsOneWidget);
    expect(find.textContaining('GNU General Public License'), findsOneWidget);
    expect(find.text('https://github.com/e7oi/tuneshell'), findsOneWidget);
    await tester.tap(find.text('Licences of the components'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  /// @verifies FR-026.4
  testWidgets('the privacy page', (tester) async {
    await pump(tester);
    await scrollTo(tester, 'Privacy');

    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'TuneShell collects no data, has no account and uses no network.',
      ),
      findsOneWidget,
    );
    expect(find.text('What stays on your phone'), findsOneWidget);
    expect(find.text('What TuneShell asks Android for'), findsOneWidget);
  });

  /// @verifies FR-010.7 the gallery is offered in debug and profile builds.
  testWidgets('offers the component gallery, which opens', (tester) async {
    await pump(tester);
    await scrollTo(tester, 'Component gallery');

    await tester.tap(find.text('Component gallery'));
    await tester.pumpAndSettle();

    expect(find.text('Component gallery'), findsWidgets);
    expect(find.byType(SettingsPage), findsNothing);
  });

  /// @verifies FR-023.9
  testWidgets('keeps a readable width on a wide screen', (tester) async {
    tester.view
      ..physicalSize = const Size(1200, 800)
      ..devicePixelRatio = 1;
    await pump(tester);
    tester.view
      ..physicalSize = const Size(1200, 800)
      ..devicePixelRatio = 1;
    await tester.pumpAndSettle();

    final width = tester.getSize(find.byType(ListView).first).width;
    expect(width, TsSize.settingsMaxWidth);
  });
}
