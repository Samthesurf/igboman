import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:igboman/models/lesson.dart';
import 'package:igboman/models/progress.dart';
import 'package:igboman/screens/lesson_screen.dart';
import 'package:igboman/state/app_state.dart';
import 'package:igboman/widgets/coach_comment.dart';
import 'package:igboman/widgets/prop_spot.dart';

Widget _wrap(Widget child, AppState appState) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

AppState _freshState() => AppState(initial: const ProgressData());

const _reviewLesson = Lesson(
  id: 'test_review_001',
  title: 'Review Test',
  questions: [
    LessonQuestion(
      id: 'q1',
      type: QuestionType.mcqIgboToEnglish,
      prompt: 'What does "Nna" mean?',
      options: ['Father', 'Mother', 'Child', 'Grandmother'],
      answer: 'Father',
      acceptedAnswers: ['Father'],
    ),
    LessonQuestion(
      id: 'q2',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'How do you say "water" in Igbo?',
      options: ['Mmiri', 'Nni', 'Ulo', 'Oji'],
      answer: 'Mmiri',
      acceptedAnswers: ['Mmiri'],
    ),
  ],
);

/// Answers Q1 correctly and Q2 wrongly, then settles on completion.
Future<void> _playMixed(WidgetTester tester) async {
  await tester.pumpWidget(
    _wrap(LessonScreen(lesson: _reviewLesson), _freshState()),
  );
  await tester.pump();

  await tester.tap(find.text('Father'));
  await tester.pump();
  await tester.tap(find.text('Check'));
  await tester.pump();
  await tester.tap(find.text('Continue'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  await tester.tap(find.text('Nni'));
  await tester.pump();
  await tester.tap(find.text('Check'));
  await tester.pump();
  await tester.tap(find.text('Continue'));
  await tester.pump();
  // Settle the burst confetti and the streaming coach line.
  await tester.pump(const Duration(seconds: 3));
}

/// Answers every question correctly, then settles on completion.
Future<void> _playPerfect(WidgetTester tester) async {
  await tester.pumpWidget(
    _wrap(LessonScreen(lesson: _reviewLesson), _freshState()),
  );
  await tester.pump();

  await tester.tap(find.text('Father'));
  await tester.pump();
  await tester.tap(find.text('Check'));
  await tester.pump();
  await tester.tap(find.text('Continue'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  await tester.tap(find.text('Mmiri'));
  await tester.pump();
  await tester.tap(find.text('Check'));
  await tester.pump();
  await tester.tap(find.text('Continue'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

bool _showsAny(WidgetTester tester, List<String> snippets) {
  for (final s in snippets) {
    if (find.textContaining(s).evaluate().isNotEmpty) return true;
  }
  return false;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('pickCoachComment tiers', () {
    test('perfect score picks a perfect line', () {
      final comment = pickCoachComment(
        correct: 4,
        total: 4,
        random: math.Random(0),
      );
      expect(
        comment.phrase.contains('Flawless run') ||
            comment.phrase.contains('Perfect!'),
        isTrue,
      );
    });

    test('most right picks a good line', () {
      final comment = pickCoachComment(
        correct: 2,
        total: 3,
        random: math.Random(0),
      );
      expect(
        comment.phrase.contains('Strong run') ||
            comment.phrase.contains('Good work'),
        isTrue,
      );
    });

    test('poor score picks a poor line', () {
      final comment = pickCoachComment(
        correct: 0,
        total: 2,
        random: math.Random(0),
      );
      expect(
        comment.phrase.contains('You can do better') ||
            comment.phrase.contains('Tough round'),
        isTrue,
      );
    });

    test('asset is always a roster portrait', () {
      const roster = [
        'assets/images/ada.jpg',
        'assets/images/kid.jpg',
        'assets/images/nna.jpg',
        'assets/images/mama.jpg',
        'assets/images/mbe.jpg',
      ];
      for (var seed = 0; seed < 10; seed++) {
        final comment = pickCoachComment(
          correct: seed % 3,
          total: 3,
          random: math.Random(seed),
        );
        expect(roster.contains(comment.assetPath), isTrue);
        expect(comment.phrase.isNotEmpty, isTrue);
      }
    });
  });

  group('completion coach comment', () {
    testWidgets('poor run streams a do-better line', (tester) async {
      await _playMixed(tester);

      expect(find.text('Excellent!'), findsOneWidget);
      expect(find.byKey(const Key('coachComment')), findsOneWidget);
      expect(_showsAny(tester, ['You can do better', 'Tough round']), isTrue);
    });

    testWidgets('perfect run streams a praise line', (tester) async {
      await _playPerfect(tester);

      expect(find.byKey(const Key('coachComment')), findsOneWidget);
      expect(_showsAny(tester, ['Flawless run', 'Perfect!']), isTrue);
    });
  });

  group('review screen', () {
    testWidgets('review lists right and wrong answers', (tester) async {
      await _playMixed(tester);

      await tester.scrollUntilVisible(
        find.byKey(const Key('reviewButton')),
        200,
      );
      await tester.tap(find.byKey(const Key('reviewButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reviewScreen')), findsOneWidget);
      expect(find.text('1 of 2 correct'), findsOneWidget);
      final prop = tester.widget<PropSpot>(find.byKey(const Key('reviewProp')));
      expect(PropArt.names.contains(prop.name), isTrue);
      expect(find.text('What does "Nna" mean?'), findsOneWidget);
      expect(find.text('How do you say "water" in Igbo?'), findsOneWidget);
      expect(find.text('You: Father'), findsOneWidget);
      expect(find.text('You: Nni'), findsOneWidget);
      expect(find.text('Right: Mmiri'), findsOneWidget);
      expect(find.text('Right: Father'), findsNothing);

      final scope = find.byKey(const Key('reviewScreen'));
      expect(
        find.descendant(of: scope, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: scope, matching: find.byIcon(Icons.close)),
        findsOneWidget,
      );
    });
  });
}
