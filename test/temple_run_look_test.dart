import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:igboman/models/lesson.dart';
import 'package:igboman/models/progress.dart';
import 'package:igboman/screens/home_screen.dart';
import 'package:igboman/screens/lesson_screen.dart';
import 'package:igboman/state/app_state.dart';
import 'package:igboman/theme/app_theme.dart';
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

const _twoQuestionLesson = Lesson(
  id: 'test_run_002',
  title: 'Run Test Two',
  skipIntro: true,
  questions: [
    LessonQuestion(
      id: 'q1',
      type: QuestionType.mcqIgboToEnglish,
      prompt: 'Select "Water"',
      options: ['Mmiri', 'Oku'],
      answer: 'Mmiri',
      acceptedAnswers: ['Mmiri'],
    ),
    LessonQuestion(
      id: 'q2',
      type: QuestionType.mcqIgboToEnglish,
      prompt: 'Select "Fire"',
      options: ['Oku', 'Mmiri'],
      answer: 'Oku',
      acceptedAnswers: ['Oku'],
    ),
  ],
);

bool _containsEmoji(String value) {
  for (final rune in value.runes) {
    if ((rune >= 0x1F300 && rune <= 0x1FAFF) ||
        (rune >= 0x1F000 && rune <= 0x1F2FF) ||
        (rune >= 0x1F1E6 && rune <= 0x1F1FF) ||
        (rune >= 0x2600 && rune <= 0x27BF) ||
        (rune >= 0x2B00 && rune <= 0x2BFF) ||
        rune == 0xFE0F) {
      return true;
    }
  }
  return false;
}

String? _textOf(Text text) {
  if (text.data != null) return text.data;
  final span = text.textSpan;
  if (span == null) return null;
  final buffer = StringBuffer();
  void visit(InlineSpan s) {
    if (s is TextSpan) {
      if (s.text != null) buffer.write(s.text);
      final children = s.children;
      if (children != null) {
        for (final child in children) {
          visit(child);
        }
      }
    }
  }

  visit(span);
  return buffer.toString();
}

List<String> _emojiStrings(WidgetTester tester) {
  final bad = <String>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final value = _textOf(text);
    if (value != null && _containsEmoji(value)) bad.add(value);
  }
  return bad;
}

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

    testWidgets('completion fires confetti with divided stats', (tester) async {
      await tester.pumpWidget(_wrap(const LessonScreen(lesson: _runLesson)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mmiri'));
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('runCompleteBanner')), findsNothing);
      expect(find.byKey(const Key('perfectRunBanner')), findsNothing);
      expect(find.byKey(const Key('completionConfetti')), findsOneWidget);
      expect(find.byKey(const Key('runStatsCard')), findsOneWidget);
      expect(find.byKey(const Key('milestoneProgressBar')), findsOneWidget);
      expect(find.byKey(const Key('streakStatValue')), findsOneWidget);
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

  group('No-emoji UI', () {
    testWidgets('home journey shows icons and no emoji codepoints', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 4200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrapHome(_freshState()));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('journeyHeader')),
          matching: find.byIcon(Icons.directions_run),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('currentRunBadge')),
          matching: find.byIcon(Icons.directions_run),
        ),
        findsOneWidget,
      );
      expect(_emojiStrings(tester), isEmpty);
    });

    testWidgets('lesson, chips and celebration show no emoji codepoints', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LessonScreen(lesson: _runLesson)));
      await tester.pumpAndSettle();
      expect(_emojiStrings(tester), isEmpty);

      final appState = AppState(
        initial: ProgressData(streakDays: 4, lastActiveDay: DateTime.now()),
      );
      await tester.pumpWidget(_wrap(const StreakChip(), appState));
      await tester.pump();
      await tester.tap(find.byType(StreakChip));
      await tester.pumpAndSettle();
      expect(_emojiStrings(tester), isEmpty);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakCelebrationDialog(streakDays: 6, isRestored: true),
          ),
        ),
      );
      await tester.pump();
      expect(_emojiStrings(tester), isEmpty);
    });
  });

  group('Trail continuity', () {
    testWidgets('one connector per gap and none past the last realm', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 4200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrapHome(_freshState()));
      await tester.pump();

      for (var i = 1; i <= 12; i++) {
        expect(
          find.byKey(Key('trailSegment_$i')),
          findsOneWidget,
          reason: 'missing trail connector $i',
        );
      }
      expect(find.byKey(const Key('trailSegment_0')), findsNothing);
      expect(find.byKey(const Key('trailSegment_13')), findsNothing);
    });

    testWidgets('journey banner uses the white to light-green flow', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapHome(_freshState()));
      await tester.pump();

      final header = tester.widget<Container>(
        find.byKey(const Key('journeyHeader')),
      );
      final decoration = header.decoration! as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
      expect(gradient.colors, [AppColors.surface, AppColors.successBg]);
    });
  });

  group('Question micro-transition', () {
    testWidgets('passing a question keeps chrome stable and swaps content', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LessonScreen(lesson: _twoQuestionLesson)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select "Water"'), findsOneWidget);
      expect(find.byKey(const Key('lessonRunTrack')), findsOneWidget);

      await tester.tap(find.text('Mmiri'));
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Select "Fire"'), findsOneWidget);
      expect(find.text('Select "Water"'), findsNothing);
      expect(find.text('Run Test Two'), findsOneWidget);
      expect(find.byKey(const Key('lessonRunTrack')), findsOneWidget);
      expect(find.byKey(const Key('runQuestionEntrance')), findsOneWidget);
    });
  });
}
