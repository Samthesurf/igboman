import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:igboman/data/curriculum.dart';
import 'package:igboman/data/stories.dart';
import 'package:igboman/models/progress.dart';
import 'package:igboman/screens/stories_screen.dart';
import 'package:igboman/screens/story_screen.dart';
import 'package:igboman/state/app_state.dart';
import 'package:igboman/widgets/prop_spot.dart';
import 'package:igboman/widgets/story_card.dart';

// ---------------------------------------------------------------------------
// Stories list: every shipped story renders as a card, stays locked until
// its unit is unlocked, and opens the reader when tapped.
// ---------------------------------------------------------------------------

Widget _wrap(AppState appState) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: const MaterialApp(home: StoriesScreen()),
  );
}

AppState _freshState() => AppState(initial: const ProgressData());

/// Completed lessons for units 1 through [throughUnit], which unlocks
/// unit [throughUnit] + 1 and every story whose unit is at or below it.
AppState _stateThrough(int throughUnit) {
  final completed = <String>[];
  for (final unit in curriculum) {
    if (unit.id > throughUnit) break;
    for (final lesson in unit.lessons) {
      completed.add(lesson.id);
    }
  }
  return AppState(initial: ProgressData(completedLessonIds: completed));
}

/// Pads the test surface so all seven cards are laid out without scrolling.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('renders one card per story, locked from a fresh state', (
    tester,
  ) async {
    _useTallSurface(tester);
    await tester.pumpWidget(_wrap(_freshState()));
    await tester.pump();

    expect(find.byType(StoriesScreen), findsOneWidget);
    expect(find.byType(StoryCard), findsNWidgets(stories.length));
    expect(find.byIcon(Icons.lock), findsNWidgets(stories.length));

    // Rated stories start at unit 3, so a fresh state (unit 1 only) locks
    // every card; tapping one must not open the reader.
    await tester.tap(find.byType(StoryCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(StoryScreen), findsNothing);
  });

  testWidgets('unlocked story opens the reader, locked cards stay inert', (
    tester,
  ) async {
    _useTallSurface(tester);
    // Completing units 1-4 unlocks units 3, 4 and 5 stories.
    await tester.pumpWidget(_wrap(_stateThrough(4)));
    await tester.pump();

    final unlocked = find.byType(PropSpot);
    expect(unlocked, findsNWidgets(3));
    expect(find.byIcon(Icons.lock), findsNWidgets(stories.length - 3));

    // Open the first unlocked story (the unit 3 tale).
    await tester.tap(unlocked.first);
    await tester.pumpAndSettle();
    expect(find.byType(StoryScreen), findsOneWidget);
    expect(find.text('New words'), findsOneWidget);
  });

  testWidgets('StoriesList embeds in the home tab without its own scaffold', (
    tester,
  ) async {
    _useTallSurface(tester);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: _freshState(),
        child: const MaterialApp(home: Scaffold(body: StoriesList())),
      ),
    );
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(StoryCard), findsNWidgets(stories.length));
  });
}
