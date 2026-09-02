import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/widgets/diacritic_bar.dart';

void main() {
  group('DiacriticBar', () {
    testWidgets('renders all default diacritic characters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DiacriticBar()),
        ),
      );

      for (final char in diacriticCharacters) {
        expect(find.text(char), findsOneWidget);
      }
    });

    testWidgets('inserts character at cursor position via controller',
        (tester) async {
      final controller = TextEditingController(text: 'hllo');
      // Place cursor after 'h' (offset 1)
      controller.selection = const TextSelection.collapsed(offset: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiacriticBar(controller: controller),
          ),
        ),
      );

      // Tap the 'e' character
      await tester.tap(find.text('é'));
      await tester.pump();

      expect(controller.text, 'héllo');
      expect(controller.selection.baseOffset, 2);
    });

    testWidgets('inserts at end when no selection is active', (tester) async {
      final controller = TextEditingController(text: 'hello');
      // Collapsed selection at end
      controller.selection = const TextSelection.collapsed(offset: 5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiacriticBar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.text('ị'));
      await tester.pump();

      expect(controller.text, 'helloị');
    });

    testWidgets('replaces selected text with character', (tester) async {
      final controller = TextEditingController(text: 'hello');
      // Select 'ell'
      controller.selection = const TextSelection(baseOffset: 1, extentOffset: 4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiacriticBar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.text('á'));
      await tester.pump();

      expect(controller.text, 'háo');
      expect(controller.selection.baseOffset, 2);
    });

    testWidgets('calls onCharacterSelected callback', (tester) async {
      String? received;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiacriticBar(
              onCharacterSelected: (c) => received = c,
            ),
          ),
        ),
      );

      await tester.tap(find.text('ọ'));
      await tester.pump();

      expect(received, 'ọ');
    });

    testWidgets('renders custom characters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiacriticBar(characters: ['x', 'y', 'z']),
          ),
        ),
      );

      expect(find.text('x'), findsOneWidget);
      expect(find.text('y'), findsOneWidget);
      expect(find.text('z'), findsOneWidget);
    });
  });

  group('DiacriticBar.insertAtCursor', () {
    test('inserts at collapsed cursor offset', () {
      final controller = TextEditingController(text: 'abc');
      controller.selection = const TextSelection.collapsed(offset: 1);
      DiacriticBar.insertAtCursor(controller, 'X');
      expect(controller.text, 'aXbc');
      expect(controller.selection.baseOffset, 2);
    });

    test('inserts at start', () {
      final controller = TextEditingController(text: 'abc');
      controller.selection = const TextSelection.collapsed(offset: 0);
      DiacriticBar.insertAtCursor(controller, 'Z');
      expect(controller.text, 'Zabc');
      expect(controller.selection.baseOffset, 1);
    });

    test('inserts at end', () {
      final controller = TextEditingController(text: 'abc');
      controller.selection = const TextSelection.collapsed(offset: 3);
      DiacriticBar.insertAtCursor(controller, 'W');
      expect(controller.text, 'abcW');
      expect(controller.selection.baseOffset, 4);
    });

    test('replaces selected range', () {
      final controller = TextEditingController(text: 'abcd');
      controller.selection = const TextSelection(baseOffset: 1, extentOffset: 3);
      DiacriticBar.insertAtCursor(controller, 'XY');
      expect(controller.text, 'aXYd');
      expect(controller.selection.baseOffset, 3);
    });

    test('handles empty controller', () {
      final controller = TextEditingController();
      controller.selection = const TextSelection.collapsed(offset: 0);
      DiacriticBar.insertAtCursor(controller, 'a');
      expect(controller.text, 'a');
    });
  });
}
