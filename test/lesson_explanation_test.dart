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

const _explanationLesson = Lesson(
  id: 'test_explanation_lesson',
  title: 'Explanation Test Lesson',
  skipIntro: true,
  questions: [
    LessonQuestion(
      id: 'qe1',
      type: QuestionType.mcqIgboToEnglish,
      prompt: 'What does "Dalu" mean?',
      options: ['Thank you', 'Water', 'House', 'Come'],
      answer: 'Thank you',
      acceptedAnswers: ['Thank you'],
      explanation:
          'Dalu is commonly used across Igboland to express gratitude.',
    ),
    LessonQuestion(
      id: 'qe2',
      type: QuestionType.mcqIgboToEnglish,
      prompt: 'What does "Mmiri" mean?',
      options: ['Fire', 'Water', 'Earth', 'Wind'],
      answer: 'Water',
      acceptedAnswers: ['Water'],
      // No explicit explanation: generated fallback
    ),
  ],
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LessonScreen short explanations after answers', () {
    testWidgets(
      'correct answer displays explicit explanation in feedback card',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const LessonScreen(lesson: _explanationLesson)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Thank you'));
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pump();

        expect(find.byKey(const Key('answerExplanation')), findsOneWidget);
        expect(
          find.text(
            'Dalu is commonly used across Igboland to express gratitude.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('wrong answer displays corrective explanation', (tester) async {
      await tester.pumpWidget(
        _wrap(const LessonScreen(lesson: _explanationLesson)),
      );
      await tester.pumpAndSettle();

      // Tap wrong answer
      await tester.tap(find.text('Water'));
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(find.byKey(const Key('answerExplanation')), findsOneWidget);
      expect(find.textContaining('Thank you'), findsWidgets);
    });

    testWidgets(
      'generates helpful explanation when question has no explicit explanation',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const LessonScreen(lesson: _explanationLesson)),
        );
        await tester.pumpAndSettle();

        // Complete Q1
        await tester.tap(find.text('Thank you'));
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Q2 has no explicit explanation
        await tester.tap(find.text('Water'));
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pump();

        expect(find.byKey(const Key('answerExplanation')), findsOneWidget);
        expect(find.textContaining('Water'), findsWidgets);
      },
    );
  });
}
