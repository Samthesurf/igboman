import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:igboman/models/lesson.dart';
import 'package:igboman/models/progress.dart';
import 'package:igboman/screens/home_screen.dart';
import 'package:igboman/screens/lesson_screen.dart';
import 'package:igboman/state/app_state.dart';
import 'package:igboman/widgets/streak_celebration.dart';
import 'package:igboman/widgets/streak_chip.dart';

Widget _wrapHome(AppState appState) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: const MaterialApp(home: HomeScreen()),
  );
}

Widget _wrap(Widget child, [AppState? appState]) {
  final state = appState ?? AppState(initial: const ProgressData());
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

AppState _freshState() => AppState(initial: const ProgressData());

const _runLesson = Lesson(
  id: 'test_run_001',
  title: 'Run Test',
  skipIntro: true,
  questions: [
    LessonQuestion(
      id: 'qr1',
      type: QuestionType.mcqIgboToEnglish,
      prompt: 'Select "Water"',
      options: ['Mmiri', 'Oku', 'Ala', 'Ikuku'],
      answer: 'Mmiri',
      acceptedAnswers: ['Mmiri'],
    ),
  ],
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Temple-run journey map', () {
    testWidgets('renders winding path with header and current badge', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapHome(_freshState()));
      await tester.pump();

      expect(find.byKey(const Key('journeyPath')), findsOneWidget);
      expect(find.byKey(const Key('journeyHeader')), findsOneWidget);
      expect(find.text('THE GREAT RUN'), findsOneWidget);
      expect(find.text('0 of 13 realms cleared'), findsOneWidget);
      expect(find.text('13 realms ahead. Keep running!'), findsOneWidget);
      expect(find.byKey(const Key('currentRunBadge')), findsOneWidget);
      expect(find.text('YOU ARE HERE'), findsOneWidget);
    });

    testWidgets('header counts cleared realms', (tester) async {
      final appState = AppState(
        initial: const ProgressData(
          completedLessonIds: ['u1l1', 'u1l2', 'u1l3', 'u1l4', 'u1l5'],
        ),
      );
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrapHome(appState));
      await tester.pump();

      expect(find.text('1 of 13 realms cleared'), findsOneWidget);
    });

    testWidgets('tapping an unlocked unit still opens its lesson', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapHome(_freshState()));
      await tester.pump();

      await tester.tap(find.text('Mkpụrụ Edemede'));
      await tester.pumpAndSettle();

      expect(find.byType(LessonScreen), findsOneWidget);
    });
  });

  group('Lesson run momentum', () {
    testWidgets('momentum HUD shows position and invites a combo', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LessonScreen(lesson: _runLesson)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('runQuestionEntrance')), findsOneWidget);
      expect(find.byKey(const Key('runMomentumBadge')), findsOneWidget);
      expect(find.text('Q1 of 1'), findsOneWidget);
      expect(find.text('Build a combo!'), findsOneWidget);
    });

    testWidgets('correct answer lights up combo heat', (tester) async {
      await tester.pumpWidget(_wrap(const LessonScreen(lesson: _runLesson)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mmiri'));
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(find.byKey(const Key('runComboBadge')), findsOneWidget);
      expect(find.textContaining('Heat x1'), findsOneWidget);
    });

    testWidgets('completion fires confetti and flawless banner', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LessonScreen(lesson: _runLesson)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mmiri'));
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('runCompleteBanner')), findsOneWidget);
      expect(find.byKey(const Key('perfectRunBanner')), findsOneWidget);
      expect(find.byKey(const Key('completionConfetti')), findsOneWidget);
      expect(find.byKey(const Key('runStatsCard')), findsOneWidget);
      expect(find.byKey(const Key('milestoneProgressBar')), findsOneWidget);
    });
  });

  group('Bolder streak celebrations', () {
    testWidgets('celebration dialog shows badge and milestone strip', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakCelebrationDialog(streakDays: 6, isRestored: true),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('streakCelebrationBadge')), findsOneWidget);
      expect(find.byKey(const Key('streakMilestoneBadge')), findsOneWidget);
      expect(
        find.byKey(const Key('streakCelebrationContinue')),
        findsOneWidget,
      );
      expect(find.byType(TastefulConfetti), findsOneWidget);
    });

    testWidgets('details sheet shows flame banner and momentum footer', (
      tester,
    ) async {
      final appState = AppState(
        initial: ProgressData(streakDays: 4, lastActiveDay: DateTime.now()),
      );
      await tester.pumpWidget(_wrap(const StreakChip(), appState));
      await tester.pump();

      await tester.tap(find.byType(StreakChip));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('streakFlameBadge')), findsOneWidget);
      expect(find.byKey(const Key('streakMomentumFooter')), findsOneWidget);
      expect(find.byKey(const Key('streakCalendarStrip')), findsOneWidget);
      expect(find.text('Streak Details'), findsOneWidget);
    });
  });
}
