import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:igboman/data/curriculum.dart';
import 'package:igboman/models/progress.dart';
import 'package:igboman/screens/lesson_screen.dart';
import 'package:igboman/services/unit_quiz.dart';
import 'package:igboman/state/app_state.dart';

// ---------------------------------------------------------------------------
// Teach phase: real curriculum lessons open with an intro (new words +
// examples) and only reach the questions after Start.
// ---------------------------------------------------------------------------

void main() {
  Widget wrap(Widget child) {
    return ChangeNotifierProvider<AppState>.value(
      value: AppState(initial: const ProgressData()),
      child: MaterialApp(home: child),
    );
  }

  testWidgets('curriculum lesson opens with the teach phase', (tester) async {
    await tester.pumpWidget(wrap(LessonScreen(lesson: unit01.lessons[0])));
    await tester.pump();
    await tester.pump();

    expect(find.text('Study first'), findsOneWidget);
    expect(find.text('New words'), findsOneWidget);
    expect(find.byKey(const Key('lessonStartButton')), findsOneWidget);

    // No bundled audio yet: no speaker buttons.
    expect(find.byIcon(Icons.volume_up), findsNothing);
  });

  testWidgets('Start advances from the teach phase to the questions', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(LessonScreen(lesson: unit01.lessons[0])));
    await tester.pump();
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('lessonStartButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lessonStartButton')));
    await tester.pumpAndSettle();

    expect(find.text('Study first'), findsNothing);
    expect(
      find.text('How many letters are in the standard Igbo alphabet (Ọnwụ)?'),
      findsOneWidget,
    );
  });

  testWidgets('unit quiz lessons skip the teach phase', (tester) async {
    await tester.pumpWidget(wrap(LessonScreen(lesson: buildUnitQuiz(unit01))));
    await tester.pump();
    await tester.pump();

    expect(find.text('Study first'), findsNothing);
    expect(find.text('New words'), findsNothing);
    expect(find.byKey(const Key('lessonStartButton')), findsNothing);
    // First quiz question is visible immediately.
    expect(find.textContaining('What is the Igbo for'), findsWidgets);
  });
}
