import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/app.dart';
import 'package:igboman/state/app_state.dart';
import 'package:igboman/widgets/avatar_view.dart';
import 'package:igboman/widgets/streak_chip.dart';
import 'package:igboman/widgets/xp_chip.dart';

void main() {
  group('Home Shell and App', () {
    testWidgets('pumps App, displays Igboman title, chips with 0 values and placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(const App());

      // Check title
      expect(find.text('Igboman'), findsOneWidget);

      // Check streak and XP chips with 0
      expect(find.byType(StreakChip), findsOneWidget);
      expect(find.byType(XpChip), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('⚡'), findsOneWidget);

      // Check body placeholder
      expect(find.text('Lessons are coming'), findsOneWidget);
      expect(find.byType(AvatarView), findsOneWidget);
    });

    testWidgets('updating AppState updates streak and xp chips in UI', (WidgetTester tester) async {
      final appState = AppState();
      await tester.pumpWidget(App(appState: appState));

      expect(find.text('0'), findsNWidgets(2));

      appState.streakDays = 5;
      appState.xp = 120;
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
    });
  });

  group('AvatarView', () {
    testWidgets('renders placeholder when assetPath is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarView(initial: 'B'),
          ),
        ),
      );

      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('renders placeholder with default initial A', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarView(),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
    });
  });

  group('Stat Chips', () {
    testWidgets('StreakChip renders explicit streak value', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakChip(streak: 12),
          ),
        ),
      );

      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('XpChip renders explicit xp value', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XpChip(xp: 450),
          ),
        ),
      );

      expect(find.text('⚡'), findsOneWidget);
      expect(find.text('450'), findsOneWidget);
    });
  });
}
