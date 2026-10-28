import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/widgets/tuneshell_logo.dart';

import 'support.dart';

void main() {
  /// @verifies FR-030.5
  for (final dark in themes) {
    group('TuneShellLogo in ${themeName(dark: dark)}', () {
      testWidgets('shows the brand image at the requested size, whatever '
          'the theme', (tester) async {
        await pumpUi(tester, const Center(child: TuneShellLogo(size: 96)));
        await tester.pump();

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.width, 96);
        expect(image.height, 96);
        expect(
          (image.image as AssetImage).assetName,
          'assets/brand/emblem.png',
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('is left out of the semantics tree', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpUi(tester, const Center(child: TuneShellLogo()));

        expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
        handle.dispose();
      });
    });
  }
}
