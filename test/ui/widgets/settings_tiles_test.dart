import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/settings_tiles.dart';

import 'support.dart';

void main() {
  /// @verifies FR-023.1
  for (final dark in themes) {
    group('in ${themeName(dark: dark)}', () {
      testWidgets('a navigation line shows its texts, badge and arrow', (
        tester,
      ) async {
        var taps = 0;
        await pumpUi(
          tester,
          Column(
            children: [
              SettingsNavTile(
                title: 'Removable disks',
                subtitle: 'SSD · not connected',
                badge: '1 absent',
                onTap: () => taps++,
              ),
            ],
          ),
          dark: dark,
        );

        expect(find.text('Removable disks'), findsOneWidget);
        expect(find.text('SSD · not connected'), findsOneWidget);
        expect(find.text('1 absent'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
        await tester.tap(find.text('Removable disks'));
        expect(taps, 1);
        expect(
          tester.getSize(find.byType(SettingsNavTile)).height,
          greaterThanOrEqualTo(TsSize.touchTarget),
        );
      });

      testWidgets('a switch line toggles from its whole row', (tester) async {
        final log = <bool>[];
        await pumpUi(
          tester,
          Column(
            children: [
              SettingsSwitchTile(
                title: 'Left index',
                subtitle: 'For the left hand',
                value: false,
                onChanged: log.add,
              ),
            ],
          ),
          dark: dark,
        );

        await tester.tap(find.text('Left index'));
        await tester.tap(find.byType(Switch));

        expect(log, [true, true]);
      });

      testWidgets('a segmented line shows the choice and reports another', (
        tester,
      ) async {
        final log = <String>[];
        await pumpUi(
          tester,
          Column(
            children: [
              SettingsSegmentedTile<String>(
                title: 'Theme',
                choices: const [
                  ('system', 'System'),
                  ('light', 'Light'),
                  ('dark', 'Dark'),
                ],
                selected: 'system',
                onChanged: log.add,
              ),
            ],
          ),
          dark: dark,
        );

        await tester.tap(find.text('Dark'));

        expect(log, ['dark']);
      });
    });
  }

  testWidgets('a disabled switch line is greyed and does nothing', (
    tester,
  ) async {
    var taps = 0;
    await pumpUi(
      tester,
      Column(
        children: [
          SettingsSwitchTile(
            title: 'Wallpaper colours',
            subtitle: 'Android 12 or later',
            value: false,
            enabled: false,
            onChanged: (_) => taps++,
          ),
        ],
      ),
    );

    await tester.tap(find.text('Wallpaper colours'));
    await tester.tap(find.byType(Switch));

    expect(taps, 0);
    expect(find.text('Android 12 or later'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });

  /// @verifies FR-023.10
  testWidgets('TalkBack hears the label, the explanation and the state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpUi(
      tester,
      Column(
        children: [
          SettingsSwitchTile(
            title: 'Pause when unplugged',
            subtitle: 'Recommended',
            value: true,
            onChanged: (_) {},
          ),
          SettingsNavTile(
            title: 'Privacy',
            subtitle: 'Nothing collected',
            onTap: () {},
          ),
        ],
      ),
    );

    expect(
      tester.getSemantics(find.text('Pause when unplugged')),
      matchesSemantics(
        label: 'Pause when unplugged, Recommended',
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(find.bySemanticsLabel('Privacy, Nothing collected'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a section header is a header, in capitals', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpUi(
      tester,
      const Column(children: [SettingsSectionHeader('Library')]),
    );

    expect(find.text('LIBRARY'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('LIBRARY')),
      matchesSemantics(isHeader: true, label: 'LIBRARY'),
    );
    handle.dispose();
  });
}
