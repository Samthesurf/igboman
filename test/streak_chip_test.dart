import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:igboman/models/progress.dart';
import 'package:igboman/state/app_state.dart';
import 'package:igboman/widgets/streak_chip.dart';

Widget _wrap(Widget child, [AppState? appState]) {
  final state =
      appState ?? AppState(initial: const ProgressData(streakDays: 5));
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StreakChip interactive widget', () {
    testWidgets('renders streak count and flame icon', (tester) async {
      await tester.pumpWidget(_wrap(const StreakChip(streak: 7)));
      await tester.pump();

      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('tapping streak chip opens streak details sheet', (
      tester,
    ) async {
      final appState = AppState(
        initial: ProgressData(streakDays: 4, lastActiveDay: DateTime.now()),
      );

      await tester.pumpWidget(_wrap(const StreakChip(), appState));
      await tester.pump();

      // Tap streak chip
      await tester.tap(find.byType(StreakChip));
      await tester.pumpAndSettle();

      // Should find the streak details sheet
      expect(find.byKey(const Key('streakDetailsSheet')), findsOneWidget);
      expect(find.text('Streak Details'), findsOneWidget);
      expect(find.textContaining('4 Day Streak'), findsOneWidget);
    });

    testWidgets('streak details sheet displays 7-day calendar strip', (
      tester,
    ) async {
      final appState = AppState(
        initial: ProgressData(streakDays: 3, lastActiveDay: DateTime.now()),
      );

      await tester.pumpWidget(_wrap(const StreakChip(), appState));
      await tester.pump();

      await tester.tap(find.byType(StreakChip));
      await tester.pumpAndSettle();

      // Calendar strip with day markers
      expect(find.byKey(const Key('streakCalendarStrip')), findsOneWidget);
      // Day indicators for week days
      expect(find.text('Mon'), findsWidgets);
      expect(find.text('Sun'), findsWidgets);
    });

    testWidgets('streak details sheet shows grace window explanation', (
      tester,
    ) async {
      final appState = AppState(
        initial: ProgressData(streakDays: 5, lastActiveDay: DateTime.now()),
      );

      await tester.pumpWidget(_wrap(const StreakChip(), appState));
      await tester.pump();

      await tester.tap(find.byType(StreakChip));
      await tester.pumpAndSettle();

      expect(find.textContaining('grace window'), findsOneWidget);
    });

    testWidgets('streak details sheet dismiss button closes the sheet', (
      tester,
    ) async {
      final appState = AppState(
        initial: ProgressData(streakDays: 2, lastActiveDay: DateTime.now()),
      );

      await tester.pumpWidget(_wrap(const StreakChip(), appState));
      await tester.pump();

      await tester.tap(find.byType(StreakChip));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('streakDetailsSheet')), findsOneWidget);

      // Tap dismiss button
      await tester.tap(find.byKey(const Key('closeStreakDetailsButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('streakDetailsSheet')), findsNothing);
    });
  });
}
