import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:igboman/models/progress.dart';
import 'package:igboman/screens/home_screen.dart';
import 'package:igboman/screens/lesson_screen.dart';
import 'package:igboman/screens/stories_screen.dart';
import 'package:igboman/state/app_state.dart';
import 'package:igboman/widgets/story_card.dart';

Widget _wrap(AppState appState) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: const MaterialApp(home: HomeScreen()),
  );
}

AppState _freshState() => AppState(initial: const ProgressData());

/// Tall surface so every unit card and the Stories card are laid out.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Unit map home screen', () {
    testWidgets('locked units show a lock and taps do not navigate', (
      tester,
    ) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_wrap(_freshState()));
      await tester.pump();

      // Unit 1 is unlocked, units 2 through 9 are locked.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsNWidgets(8));
      expect(find.byType(LessonScreen), findsNothing);

      // Tap the locked unit 2 card.
      await tester.tap(find.text('Tones and Pitch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Finish the previous unit first'), findsOneWidget);
      expect(find.byType(LessonScreen), findsNothing);
    });

    testWidgets('tapping an unlocked unit opens its next lesson', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_freshState()));
      await tester.pump();

      await tester.tap(find.text('Mkpụrụ Edemede'));
      await tester.pumpAndSettle();

      expect(find.byType(LessonScreen), findsOneWidget);
      expect(find.text('Alphabet Basics'), findsOneWidget);
    });

    testWidgets('completed unit shows a green check badge', (tester) async {
      _useTallSurface(tester);
      final appState = AppState(
        initial: const ProgressData(
          completedLessonIds: ['u1l1', 'u1l2', 'u1l3', 'u1l4', 'u1l5'],
        ),
      );
      await tester.pumpWidget(_wrap(appState));
      await tester.pump();

      // Unit 1 fully completed: check badge. Unit 2 now unlocked.
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNWidgets(2));
      expect(find.byIcon(Icons.lock), findsNWidgets(7));
    });

    testWidgets('progress bar reflects the completed lesson fraction', (
      tester,
    ) async {
      _useTallSurface(tester);
      final appState = AppState(
        initial: const ProgressData(completedLessonIds: ['u1l1', 'u1l2']),
      );
      await tester.pumpWidget(_wrap(appState));
      await tester.pump();

      final bars = tester
          .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .toList();
      final fractions = bars
          .map((bar) => bar.widthFactor)
          .whereType<double>()
          .toList();

      // Unit 1: 2 of 5 lessons complete.
      expect(fractions, contains(closeTo(0.4, 0.001)));
      // All other units have no progress.
      expect(fractions.where((f) => f == 0.0).length, 8);
    });

    testWidgets('bottom navigation bar shows on mobile widths', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(_freshState()));
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.byKey(const Key('homeSideRail')), findsNothing);

      // Switch to the Chat tab.
      await tester.tap(find.text('Chat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('chatStartButton')), findsOneWidget);
    });

    testWidgets('side rail shows on desktop widths', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(_freshState()));
      await tester.pump();

      expect(find.byKey(const Key('homeSideRail')), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Stories card opens the stories screen', (tester) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_wrap(_freshState()));
      await tester.pump();

      await tester.tap(find.byKey(const Key('storiesCard')));
      await tester.pumpAndSettle();

      expect(find.byType(StoriesScreen), findsOneWidget);
      expect(find.byType(StoryCard), findsWidgets);
    });
  });
}
