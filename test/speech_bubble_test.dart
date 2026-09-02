import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/theme/dimens.dart';
import 'package:igboman/widgets/speech_bubble.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SingleChildScrollView(child: child)),
      ),
    );
  }

  Widget bubble(String text, double factor) {
    return wrap(
      SizedBox(
        width: 400,
        child: SpeechBubble(text: text, maxWidthFactor: factor),
      ),
    );
  }

  /// The bubble body (rounded rect) is what auto-sizes to content; the
  /// widget itself may fill loose parent constraints.
  Finder bubbleBody() {
    return find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).borderRadius ==
              BorderRadius.circular(Radii.chip),
    );
  }

  double bodyWidth(WidgetTester tester) => tester.getSize(bubbleBody()).width;

  testWidgets('renders the given text', (tester) async {
    await tester.pumpWidget(wrap(const SpeechBubble(text: 'Ndewo')));
    await tester.pump();
    expect(find.text('Ndewo'), findsOneWidget);
  });

  testWidgets('shows animated dots while waiting with empty text', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SpeechBubble(waiting: true, text: '')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('speechBubbleTypingDots')), findsOneWidget);
    // No text content while waiting.
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('waiting is ignored when text is non-empty', (tester) async {
    await tester.pumpWidget(
      wrap(const SpeechBubble(waiting: true, text: 'Ndewo')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Ndewo'), findsOneWidget);
    expect(find.byKey(const Key('speechBubbleTypingDots')), findsNothing);
  });

  testWidgets('bubble width grows with content up to maxWidthFactor', (
    tester,
  ) async {
    await tester.pumpWidget(bubble('Short', 0.75));
    final shortWidth = bodyWidth(tester);

    await tester.pumpWidget(
      bubble('This is a considerably longer message', 0.75),
    );
    final longWidth = bodyWidth(tester);
    expect(longWidth, greaterThan(shortWidth));

    // Content beyond the factor stops growing the bubble.
    await tester.pumpWidget(bubble('A very long message ' * 30, 0.75));
    expect(bodyWidth(tester), longWidth);

    // A tighter factor tightens the cap (0.5 * 400 = 200).
    await tester.pumpWidget(bubble('A very long message ' * 30, 0.5));
    final cappedWidth = bodyWidth(tester);
    expect(cappedWidth, lessThanOrEqualTo(200));
    expect(cappedWidth, lessThan(longWidth));
  });

  testWidgets('paints the tail triangle when showTail is true', (tester) async {
    await tester.pumpWidget(wrap(const SpeechBubble(text: 'Ndewo')));
    await tester.pump();
    final tail = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.size.width == Spacing.m &&
          w.size.height == Spacing.s,
    );
    expect(tail, findsOneWidget);
  });

  testWidgets('omits the tail when showTail is false', (tester) async {
    await tester.pumpWidget(
      wrap(const SpeechBubble(text: 'Ndewo', showTail: false)),
    );
    await tester.pump();
    final tail = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.size.width == Spacing.m &&
          w.size.height == Spacing.s,
    );
    expect(tail, findsNothing);
    expect(find.text('Ndewo'), findsOneWidget);
  });
}
