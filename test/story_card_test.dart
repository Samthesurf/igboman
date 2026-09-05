import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/data/stories.dart';
import 'package:igboman/widgets/prop_spot.dart';
import 'package:igboman/widgets/story_card.dart';

void main() {
  testWidgets('locked card shows lock icon and disabled title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryCard(story: story03, unlocked: false, onTap: () {}),
        ),
      ),
    );

    expect(find.text('Morning Greetings'), findsOneWidget);
    expect(find.text('Ekele Ụtụtụ'), findsOneWidget);
    expect(find.text('Unit 3'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.byIcon(Icons.menu_book), findsNothing);
  });

  testWidgets('unlocked card shows book icon and fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryCard(
            story: story09,
            unlocked: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Mbe in the Sky'), findsOneWidget);
    expect(find.byType(PropSpot), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNothing);

    await tester.tap(find.text('Mbe in the Sky'));
    expect(tapped, isTrue);
  });
}
