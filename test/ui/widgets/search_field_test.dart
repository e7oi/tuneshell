import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/search_field.dart';

void main() {
  Widget host({
    String text = '',
    ValueChanged<String>? onChanged,
    VoidCallback? onClose,
    ThemeData? theme,
  }) => MaterialApp(
    theme: theme,
    home: Scaffold(
      body: SearchField(
        text: text,
        hint: 'Rechercher une piste',
        clearLabel: 'Effacer',
        backLabel: 'Fermer la recherche',
        onChanged: onChanged ?? (_) {},
        onClose: onClose ?? () {},
      ),
    ),
  );

  group('FR-027 search field', () {
    /// @verifies FR-027
    testWidgets('shows the hint when empty and no clear button', (
      tester,
    ) async {
      await tester.pumpWidget(host());

      expect(find.text('Rechercher une piste'), findsOneWidget);
      expect(find.byTooltip('Effacer'), findsNothing);
    });

    /// @verifies FR-027
    testWidgets('reports each change of the text', (tester) async {
      final seen = <String>[];
      await tester.pumpWidget(host(onChanged: seen.add));

      await tester.enterText(find.byType(TextField), 'ab');
      await tester.enterText(find.byType(TextField), 'abc');

      expect(seen, ['ab', 'abc']);
    });

    /// @verifies FR-027
    testWidgets('starts with the text it is given', (tester) async {
      await tester.pumpWidget(host(text: 'jazz'));

      expect(find.text('jazz'), findsOneWidget);
      expect(find.byTooltip('Effacer'), findsOneWidget);
    });

    /// @verifies FR-027
    testWidgets('the clear button empties the text and keeps the field', (
      tester,
    ) async {
      final seen = <String>[];
      await tester.pumpWidget(host(text: 'jazz', onChanged: seen.add));

      await tester.tap(find.byTooltip('Effacer'));
      await tester.pump();

      expect(seen, ['']);
      expect(find.byType(TextField), findsOneWidget);
    });

    /// @verifies FR-027
    testWidgets('the back arrow closes the search', (tester) async {
      var closed = 0;
      await tester.pumpWidget(host(onClose: () => closed++));

      await tester.tap(find.byTooltip('Fermer la recherche'));

      expect(closed, 1);
    });

    /// @verifies FR-027
    testWidgets('the buttons are at least 48 dp', (tester) async {
      await tester.pumpWidget(host(text: 'a'));

      for (final tooltip in ['Effacer', 'Fermer la recherche']) {
        final size = tester.getSize(find.byTooltip(tooltip));
        expect(size.width, greaterThanOrEqualTo(TsSize.touchTarget));
        expect(size.height, greaterThanOrEqualTo(TsSize.touchTarget));
      }
    });

    /// @verifies FR-027
    testWidgets('an empty field takes focus, a restored one does not', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).autofocus,
        isTrue,
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host(text: 'jazz'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).autofocus,
        isFalse,
      );
    });

    /// @verifies FR-027
    testWidgets('the search key closes the keyboard and keeps the text', (
      tester,
    ) async {
      await tester.pumpWidget(host());
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'abc');

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isFalse,
      );
      expect(find.text('abc'), findsOneWidget);
    });

    /// @verifies FR-027
    testWidgets('the field is labelled for TalkBack', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host());

      expect(find.bySemanticsLabel('Rechercher une piste'), findsWidgets);
      handle.dispose();
    });

    /// @verifies FR-027
    testWidgets('works in dark theme and at 200 % text', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: host(theme: ThemeData.dark()),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
