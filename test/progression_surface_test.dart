import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:igboman/models/lesson.dart';
import 'package:igboman/models/progress.dart';
import 'package:igboman/screens/lesson_screen.dart';
import 'package:igboman/state/app_state.dart';

Widget _wrap(Widget child, [AppState? appState]) {
  final state =
      appState ?? AppState(initial: const ProgressData(streakDays: 3));
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

const _progressionLesson = Lesson(
  id: 'test_progression_lesson',
  title: 'Progression Run Test',
  skipIntro: true,
  questions: [
    LessonQuestion(
      id: 'qp1',
      type: QuestionType.mcqIgboToEnglish,
      prompt: 'Select "Water"',
      options: ['Mmiri', 'Oku', 'Ala', 'Ikuku'],
      answer: 'Mmiri',
      acceptedAnswers: ['Mmiri'],
    ),
    LessonQuestion(
      id: 'qp2',
      type: QuestionType.mcqIgboToEnglish,
      prompt: 'Select "Fire"',
      options: ['Oku', 'Mmiri', 'Ala', 'Ikuku'],
      answer: 'Oku',
      acceptedAnswers: ['Oku'],
    ),
  ],
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Richer progression and lesson surfaces', () {
    testWidgets(
      'displays arcade-style run track and milestone checkpoints in lesson app bar',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const LessonScreen(lesson: _progressionLesson)),
        );
        await tester.pumpAndSettle();

        // Run track exists
        expect(find.byKey(const Key('lessonRunTrack')), findsOneWidget);
        // Checkpoint step counter
        expect(find.text('Question 1 of 2'), findsOneWidget);
      },
    );

    testWidgets(
      'consecutive correct answers build run combo multiplier badge',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const LessonScreen(lesson: _progressionLesson)),
        );
        await tester.pumpAndSettle();

        // Q1: correct
        await tester.tap(find.text('Mmiri'));
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pump();

        // Combo badge appears
        expect(find.byKey(const Key('runComboBadge')), findsOneWidget);
        expect(find.textContaining('Combo x1'), findsOneWidget);

        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Q2: correct
        await tester.tap(find.text('Oku'));
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pump();

        // Combo escalated
        expect(find.byKey(const Key('runComboBadge')), findsOneWidget);
        expect(find.textContaining('Combo x2'), findsOneWidget);
      },
    );

    testWidgets(
      'completion screen renders rich run stats card and milestone progress',
      (tester) async {
        final appState = AppState(
          initial: ProgressData(streakDays: 4, lastActiveDay: DateTime.now()),
        );
        await tester.pumpWidget(
          _wrap(const LessonScreen(lesson: _progressionLesson), appState),
        );
        await tester.pumpAndSettle();

        // Complete Q1
        await tester.tap(find.text('Mmiri'));
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Complete Q2
        await tester.tap(find.text('Oku'));
        await tester.pump();
        await tester.tap(find.text('Check'));
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Completion screen rich surfaces
        expect(find.byKey(const Key('runCompleteBanner')), findsNothing);
        expect(find.byKey(const Key('runStatsCard')), findsOneWidget);
        expect(find.byKey(const Key('milestoneProgressBar')), findsOneWidget);
        expect(find.text('Run Conquered!'), findsNothing);
        expect(find.text('Perfect'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      },
    );
  });
}
