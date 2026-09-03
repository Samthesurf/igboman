import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/widgets/streak_celebration.dart';

void main() {
  group('StreakCelebrationDialog and Confetti', () {
    testWidgets('renders Streak Restored title and streak count', (
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

      expect(find.text('Streak Restored!'), findsOneWidget);
      expect(find.textContaining('6 day streak'), findsOneWidget);
      expect(find.byType(TastefulConfetti), findsOneWidget);
      expect(
        find.byKey(const Key('streakCelebrationContinue')),
        findsOneWidget,
      );
    });

    testWidgets('renders Streak Extended title when not restored', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StreakCelebrationDialog(streakDays: 10, isRestored: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Streak Extended!'), findsOneWidget);
      expect(find.textContaining('10 day streak'), findsOneWidget);
    });

    testWidgets('tapping continue triggers callback', (tester) async {
      var continued = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakCelebrationDialog(
              streakDays: 3,
              isRestored: true,
              onContinue: () => continued = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('streakCelebrationContinue')));
      await tester.pump();

      expect(continued, isTrue);
    });

    test('isStreakRestored returns true on grace day gap', () {
      final now = DateTime.utc(2026, 9, 3, 12);
      final lastActiveTwoDaysAgo = DateTime.utc(2026, 9, 1, 10);
      final lastActiveYesterday = DateTime.utc(2026, 9, 2, 10);
      final lastActiveToday = DateTime.utc(2026, 9, 3, 8);

      expect(
        isStreakRestored(lastActiveDay: lastActiveTwoDaysAgo, now: now),
        isTrue,
      );
      expect(
        isStreakRestored(lastActiveDay: lastActiveYesterday, now: now),
        isFalse,
      );
      expect(
        isStreakRestored(lastActiveDay: lastActiveToday, now: now),
        isFalse,
      );
      expect(isStreakRestored(lastActiveDay: null, now: now), isFalse);
    });

    testWidgets('TastefulConfetti renders without errors and animates', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, height: 300, child: TastefulConfetti()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(TastefulConfetti), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
