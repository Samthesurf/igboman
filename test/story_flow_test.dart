import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:igboman/models/lesson.dart';
import 'package:igboman/models/progress.dart';
import 'package:igboman/models/story.dart';
import 'package:igboman/models/unit.dart';
import 'package:igboman/screens/story_screen.dart';
import 'package:igboman/state/app_state.dart';

// ---------------------------------------------------------------------------
// Tiny in-repo fake story (not part of the shipped stories list)
// ---------------------------------------------------------------------------

const _fakeStory = Story(
  id: 'story_test',
  unitId: 3,
  titleEn: 'Tiny Tale',
  titleIgbo: 'Akụkọ Nta',
  sentences: [
    'Ada hụ mmiri',
    'Mbe rie nri',
  ],
  newWords: [
    VocabEntry(igbo: 'mmiri', en: 'water'),
  ],
  questions: [
    LessonQuestion(
      id: 'story_testq1',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'What does mmiri mean?',
      options: ['water', 'food', 'sky', 'road'],
      answer: 'water',
      acceptedAnswers: ['water'],
    ),
    LessonQuestion(
      id: 'story_testq2',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'Who sees water?',
      options: ['Ada', 'Obi', 'Mbe', 'Nna'],
      answer: 'Ada',
      acceptedAnswers: ['Ada'],
    ),
  ],
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _Launcher extends StatelessWidget {
  const _Launcher({required this.story});

  final Story story;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => StoryScreen(story: story),
            ),
          ),
          child: const Text('open story'),
        ),
      ),
    );
  }
}

Widget _wrap(AppState appState) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: MaterialApp(home: _Launcher(story: _fakeStory)),
  );
}

AppState _freshState() => AppState(initial: const ProgressData());

Future<void> _openStory(WidgetTester tester) async {
  await tester.tap(find.text('open story'));
  await tester.pumpAndSettle();
}

Future<void> _runThroughStory(WidgetTester tester) async {
  // Phase 1: new words -> read
  await tester.tap(find.text('Start reading'));
  await tester.pumpAndSettle();

  // Phase 2: read -> questions
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  // Phase 3: question 1 (correct)
  await tester.tap(find.text('water'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Check'));
  await tester.pumpAndSettle();
  expect(find.text('Correct!'), findsOneWidget);
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  // Phase 3: question 2 (correct) -> completion
  await tester.tap(find.text('Ada'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Check'));
  await tester.pumpAndSettle();
  expect(find.text('Correct!'), findsOneWidget);
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('story flow: chips, reading, glosses, questions, completion',
      (tester) async {
    final appState = _freshState();
    await tester.pumpWidget(_wrap(appState));
    await _openStory(tester);

    // Phase 1: new words
    expect(find.text('New words'), findsOneWidget);
    expect(find.text('mmiri'), findsOneWidget); // chip
    expect(find.text('mmiri (water)'), findsOneWidget);
    expect(find.text('Start reading'), findsOneWidget);

    // Phase 2: reading shows both sentences
    await tester.tap(find.text('Start reading'));
    await tester.pumpAndSettle();
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('mmiri'), findsOneWidget);
    expect(find.text('Mbe'), findsOneWidget);

    // Tapping a glossed word shows the gloss card
    await tester.tap(find.text('mmiri'));
    await tester.pumpAndSettle();
    expect(find.text('mmiri = water'), findsOneWidget);

    // Tapping the x dismisses it
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('mmiri = water'), findsNothing);

    // Tapping an unknown word shows the new-word hint
    await tester.tap(find.text('hụ'));
    await tester.pumpAndSettle();
    expect(find.text('hụ: New word!'), findsOneWidget);

    // Phase 3 + completion
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('What does mmiri mean?'), findsOneWidget);

    await tester.tap(find.text('water'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Correct!'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Who sees water?'), findsOneWidget);
    await tester.tap(find.text('Ada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Correct!'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Completion screen (title shows in the app bar and the completion card)
    expect(find.text('Akụkọ!'), findsOneWidget);
    expect(find.text('Tiny Tale'), findsNWidgets(2));
    expect(find.text('Talk about it'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    // XP awarded once and story marked complete
    expect(appState.xp, 40);
    expect(appState.isStoryCompleted('story_test'), isTrue);
    expect(appState.completedStoryIds, ['story_test']);
  });

  testWidgets('wrong answer reveals correct option in terracotta', (tester) async {
    final appState = _freshState();
    await tester.pumpWidget(_wrap(appState));
    await _openStory(tester);
    await tester.tap(find.text('Start reading'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Pick a wrong option first
    await tester.tap(find.text('food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();

    expect(find.text('Not quite'), findsOneWidget);
    expect(find.textContaining('Answer: water'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  });

  testWidgets('replay awards no extra XP', (tester) async {
    final appState = _freshState();
    await tester.pumpWidget(_wrap(appState));
    await _openStory(tester);

    await _runThroughStory(tester);
    expect(appState.xp, 40);

    // Go back and reopen the story for a replay
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    await _openStory(tester);

    await _runThroughStory(tester);
    expect(appState.xp, 40);
    expect(appState.completedStoryIds, ['story_test']);
  });

  testWidgets('talk sheet shows chat-update note and Back pops', (tester) async {
    final appState = _freshState();
    await tester.pumpWidget(_wrap(appState));
    await _openStory(tester);
    await _runThroughStory(tester);

    // Talk about it opens the flat info sheet
    await tester.tap(find.text('Talk about it'));
    await tester.pumpAndSettle();
    expect(find.text('Story talk comes with the chat update'), findsOneWidget);

    // Dismiss the sheet
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // Back pops the story screen
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Akụkọ!'), findsNothing);
    expect(find.text('open story'), findsOneWidget);
  });
}