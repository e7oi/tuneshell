import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/text_link.dart';

void main() {
  Future<List<String>> pump(WidgetTester tester, {String text = 'U2'}) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextLink(
            text: text,
            semanticsLabel: 'Open the artist $text',
            onTap: () => taps.add(text),
          ),
        ),
      ),
    );
    return taps;
  }

  /// @verifies FR-032.5
  group('TextLink', () {
    testWidgets('has a touch area of at least 48 dp in height', (tester) async {
      await pump(tester);

      expect(
        tester.getSize(find.byType(TextLink)).height,
        greaterThanOrEqualTo(TsSize.touchTarget),
      );
    });

    testWidgets('is underlined, so colour alone does not tell it', (
      tester,
    ) async {
      await pump(tester);

      expect(
        tester.widget<Text>(find.text('U2')).style?.decoration,
        TextDecoration.underline,
      );
    });

    testWidgets('is a link for TalkBack, with its own label', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      final node = tester.getSemantics(
        find.bySemanticsLabel('Open the artist U2'),
      );
      expect(node.flagsCollection.isLink, isTrue);
      handle.dispose();
    });

    testWidgets('calls back when tapped', (tester) async {
      final taps = await pump(tester);

      await tester.tap(find.text('U2'));

      expect(taps, ['U2']);
    });
  });
}
