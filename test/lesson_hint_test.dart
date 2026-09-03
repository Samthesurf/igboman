import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:igboman/models/lesson.dart';
import 'package:igboman/models/progress.dart';
import 'package:igboman/screens/lesson_screen.dart';
import 'package:igboman/state/app_state.dart';

Widget _wrap(Widget child, [AppState? appState]) {
  final state = appState ?? AppState(initial: const ProgressData());
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

const _hintLesson = Lesson(
  id: 'test_hint_lesson',
  title: 'Hint Test Lesson',
  skipIntro: true,
  questions: [
    LessonQuestion(
      id: 'qh1',
      type: QuestionType.mcqIgboToEnglish,
      prompt: 'What does "Biko" mean?',
      options: ['Please', 'Thank you', 'Yes', 'No'],
      answer: 'Please',
      acceptedAnswers: ['Please'],
      hint: 'Used when making a polite request in Igbo.',
    ),
    LessonQuestion(
      id: 'qh2',
      type: QuestionType.translate,
      prompt: 'Translate "Good morning"',
      answer: 'Ututu oma',
      acceptedAnswers: ['Ututu oma'],
      // No explicit hint: falls back to contextual clue
    ),
  ],
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LessonScreen press-to-open dismissible hints', () {
    testWidgets('hint is hidden by default and opens on tap', (tester) async {
      await tester.pumpWidget(_wrap(const LessonScreen(lesson: _hintLesson)));
      await tester.pumpAndSettle();

      // Hint button is visible
      expect(find.byKey(const Key('hintButton')), findsOneWidget);
      // Hint card is NOT visible initially
      expect(find.byKey(const Key('hintCard')), findsNothing);

      // Tap hint button
      await tester.tap(find.byKey(const Key('hintButton')));
      await tester.pump();

      // Hint card is now visible with the custom hint
      expect(find.byKey(const Key('hintCard')), findsOneWidget);
      expect(
        find.text('Used when making a polite request in Igbo.'),
        findsOneWidget,
      );
    });

    testWidgets('hint card can be dismissed via dismiss button', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LessonScreen(lesson: _hintLesson)));
      await tester.pumpAndSettle();

      // Open hint
      await tester.tap(find.byKey(const Key('hintButton')));
      await tester.pump();
      expect(find.byKey(const Key('hintCard')), findsOneWidget);

      // Dismiss hint
      expect(find.byKey(const Key('hintDismissButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('hintDismissButton')));
      await tester.pump();

      // Hint card is gone
      expect(find.byKey(const Key('hintCard')), findsNothing);
      // Can open it again if desired
      expect(find.byKey(const Key('hintButton')), findsOneWidget);
    });

    testWidgets(
      'provides intelligent contextual hint when question has no explicit hint',
      (tester) async {
        await tester.pumpWidget(_wrap(const LessonScreen(lesson: _hintLesson)));
        await tester.pumpAndSettle();

        // Answer first question
        await tester.tap(find.text('Please'));
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Second question (no explicit hint)
        expect(find.byKey(const Key('hintButton')), findsOneWidget);
        await tester.tap(find.byKey(const Key('hintButton')));
        await tester.pump();

        expect(find.byKey(const Key('hintCard')), findsOneWidget);
        // Contextual clue for translation
        expect(find.textContaining('tone marks'), findsOneWidget);
      },
    );
  });
}
