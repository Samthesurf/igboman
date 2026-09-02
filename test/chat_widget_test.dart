import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:igboman/models/progress.dart';
import 'package:igboman/screens/chat_screen.dart';
import 'package:igboman/services/tutor_service.dart';
import 'package:igboman/state/app_state.dart';

// ---------------------------------------------------------------------------
// FakeTutorService: never touches the network.
// ---------------------------------------------------------------------------

class FakeTutorService implements TutorService {
  int calls = 0;
  final List<List<TutorTurn>> histories = [];
  final List<TutorContext> contexts = [];

  Stream<String> Function(List<TutorTurn> history, TutorContext context)?
  onChat;

  @override
  Stream<String> chat({
    required List<TutorTurn> history,
    required TutorContext context,
  }) {
    calls += 1;
    histories.add(List.of(history));
    contexts.add(context);
    final handler = onChat;
    if (handler != null) {
      return handler(history, context);
    }
    return Stream.fromIterable(const ['Nde', 'wo!']);
  }

  @override
  void dispose() {}
}

/// Streams chunks with a delay before the first one, then a delay between
/// chunks, then a short delay before completing so the intermediate states
/// are observable.
Stream<String> delayedChunks() async* {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  yield 'Nde';
  await Future<void>.delayed(const Duration(milliseconds: 150));
  yield 'wo!';
  await Future<void>.delayed(const Duration(milliseconds: 150));
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget buildScreen(
  FakeTutorService fake,
  AppState appState, {
  int maxExchanges = 6,
}) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: MaterialApp(
      home: ChatScreen(tutor: fake, maxExchanges: maxExchanges),
    ),
  );
}

AppState freshState() => AppState(initial: const ProgressData());

/// Sends [message] with the default instant fake and pumps until the reply
/// has settled into the transcript.
Future<void> settleExchange(WidgetTester tester, String message) async {
  await tester.enterText(find.byKey(const Key('chatInput')), message);
  await tester.pump();
  await tester.tap(find.byKey(const Key('chatSendButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('greeting appears immediately without any API call', (
    tester,
  ) async {
    final fake = FakeTutorService();
    await tester.pumpWidget(buildScreen(fake, freshState()));

    expect(find.textContaining('Ndewo'), findsOneWidget);
    expect(find.byKey(const Key('chatProgressChip')), findsOneWidget);
    expect(find.text('0/6'), findsOneWidget);
    // No chat call until the learner sends something.
    expect(fake.calls, 0);
    expect(fake.histories, isEmpty);
  });

  testWidgets('sending a message calls chat with user turn and context', (
    tester,
  ) async {
    final fake = FakeTutorService();
    await tester.pumpWidget(buildScreen(fake, freshState()));
    await tester.pump();

    await settleExchange(tester, 'Biko');
    await tester.pump(const Duration(milliseconds: 250));

    expect(fake.calls, 1);
    final history = fake.histories.single;
    expect(history.length, 1);
    expect(history.single.role, 'user');
    expect(history.single.text, 'Biko');
    // The greeting is UI-only and is NOT part of the API history.
    expect(history.every((t) => t.text.contains('Ndewo')), isFalse);

    final ctx = fake.contexts.single;
    expect(ctx.learnerName, 'you');
    expect(ctx.completedUnits, 0);
    expect(ctx.whitelistVocab, isNotEmpty);
    expect(ctx.storyContext, isNull);
  });

  testWidgets(
    'streamed chunks grow the pinned bubble and settle to transcript',
    (tester) async {
      final fake = FakeTutorService()..onChat = (h, c) => delayedChunks();
      await tester.pumpWidget(buildScreen(fake, freshState()));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('chatInput')), 'Biko');
      await tester.pump();
      await tester.tap(find.byKey(const Key('chatSendButton')));
      await tester.pump();

      // Dots before the first chunk arrives.
      expect(find.byKey(const Key('speechBubbleTypingDots')), findsOneWidget);

      // First chunk appears in the pinned bubble.
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.descendant(
          of: find.byKey(const Key('chatPinnedBubble')),
          matching: find.text('Nde'),
        ),
        findsOneWidget,
      );

      // Bubble keeps growing with the second chunk.
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.descendant(
          of: find.byKey(const Key('chatPinnedBubble')),
          matching: find.text('Ndewo!'),
        ),
        findsOneWidget,
      );

      // Stream ends: text settles into the transcript, pinned bubble resets.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Ndewo!'), findsOneWidget);
      expect(find.byKey(const Key('chatPinnedBubble')), findsNothing);
      expect(find.text('1/6'), findsOneWidget);
    },
  );

  testWidgets('waiting dots show before the first chunk arrives', (
    tester,
  ) async {
    final fake = FakeTutorService()..onChat = (h, c) => delayedChunks();
    await tester.pumpWidget(buildScreen(fake, freshState()));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('chatInput')), 'Biko');
    await tester.pump();
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await tester.pump();

    expect(find.byKey(const Key('chatPinnedBubble')), findsOneWidget);
    expect(find.byKey(const Key('speechBubbleTypingDots')), findsOneWidget);

    // After the first chunk the dots are replaced by text.
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('speechBubbleTypingDots')), findsNothing);
    expect(find.text('Nde'), findsOneWidget);

    // Let the stream finish cleanly.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets(
    'error shows terracotta message and Retry re-sends successfully',
    (tester) async {
      final fake = FakeTutorService();
      var attempts = 0;
      fake.onChat = (h, c) {
        attempts += 1;
        if (attempts == 1) {
          return Stream<String>.error(
            const TutorException('Ada could not respond. Please try again.'),
          );
        }
        return Stream.fromIterable(const ['Nde', 'wo!']);
      };
      await tester.pumpWidget(buildScreen(fake, freshState()));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('chatInput')), 'Biko');
      await tester.pump();
      await tester.tap(find.byKey(const Key('chatSendButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(fake.calls, 1);
      expect(
        find.text('Ada could not respond. Please try again.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('chatRetryButton')), findsOneWidget);

      // Retry re-sends the same history and succeeds.
      await tester.tap(find.byKey(const Key('chatRetryButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(fake.calls, 2);
      expect(
        fake.histories[1].map((t) => t.text).toList(),
        fake.histories[0].map((t) => t.text).toList(),
      );
      expect(find.text('Ndewo!'), findsOneWidget);
      expect(find.byKey(const Key('chatErrorBubble')), findsNothing);
    },
  );

  testWidgets('session ends after maxExchanges, awards XP once, Done pops', (
    tester,
  ) async {
    final appState = freshState();
    final fake = FakeTutorService();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatScreen(tutor: fake, maxExchanges: 2),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(appState.xp, 0);
    expect(find.byKey(const Key('chatInput')), findsOneWidget);

    await settleExchange(tester, 'Biko');
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('1/2'), findsOneWidget);
    expect(find.byKey(const Key('chatInput')), findsOneWidget);

    await settleExchange(tester, 'Daalụ');
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('2/2'), findsOneWidget);

    // Input is replaced by the two end buttons.
    expect(find.byKey(const Key('chatInput')), findsNothing);
    expect(find.text('Practice again'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(appState.xp, 20);

    // Done pops back to the previous screen.
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('Practice again resets the session without extra XP', (
    tester,
  ) async {
    final appState = freshState();
    final fake = FakeTutorService();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatScreen(tutor: fake, maxExchanges: 2),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await settleExchange(tester, 'Biko');
    await tester.pump(const Duration(milliseconds: 250));
    await settleExchange(tester, 'Daalụ');
    await tester.pump(const Duration(milliseconds: 250));
    expect(appState.xp, 20);
    expect(find.text('Practice again'), findsOneWidget);

    // Practice again: fresh greeting, input restored, no new API call.
    final callsBeforeReset = fake.calls;
    await tester.tap(find.text('Practice again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(fake.calls, callsBeforeReset);
    expect(find.byKey(const Key('chatInput')), findsOneWidget);
    expect(find.text('0/2'), findsOneWidget);
    expect(find.textContaining('Ndewo'), findsOneWidget);

    // A second full session still awards no extra XP.
    await settleExchange(tester, 'Nde');
    await tester.pump(const Duration(milliseconds: 250));
    await settleExchange(tester, 'Eeh');
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Practice again'), findsOneWidget);
    expect(appState.xp, 20);
  });
}
