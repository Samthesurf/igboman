import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/models/unit.dart';
import 'package:igboman/services/prompt_builder.dart';
import 'package:igboman/services/tutor_service.dart';

const _vocab = [
  VocabEntry(igbo: 'nri', en: 'food'),
  VocabEntry(igbo: 'mmiri', en: 'water'),
  VocabEntry(igbo: 'ụlọ', en: 'house'),
];

TutorContext _context({
  String learnerName = 'Sam',
  int completedUnits = 1,
  List<VocabEntry> vocab = _vocab,
  String? storyContext,
}) {
  return TutorContext(
    learnerName: learnerName,
    completedUnits: completedUnits,
    whitelistVocab: vocab,
    storyContext: storyContext,
  );
}

void main() {
  group('buildSystemPrompt', () {
    test('names the persona Ada', () {
      final prompt = buildSystemPrompt(_context());
      expect(prompt, contains('Ada'));
    });

    test('mentions standard Igbo (Igbo Izugbe)', () {
      final prompt = buildSystemPrompt(_context());
      expect(prompt, contains('Igbo Izugbe'));
    });

    test('lists whitelist vocab entries verbatim', () {
      final prompt = buildSystemPrompt(_context());
      expect(prompt, contains('nri: food'));
      expect(prompt, contains('mmiri: water'));
      expect(prompt, contains('ụlọ: house'));
      expect(prompt, contains('Available vocabulary'));
    });

    test('enforces the one-question-at-a-time rule', () {
      final prompt = buildSystemPrompt(_context());
      expect(prompt, contains('ONE question at a time'));
    });

    test('forbids lectures', () {
      final prompt = buildSystemPrompt(_context());
      expect(prompt, contains('Never deliver a lecture'));
    });

    test('handles an empty whitelist', () {
      final prompt = buildSystemPrompt(_context(vocab: const []));
      expect(prompt, contains('Available vocabulary (igbo: english):'));
      expect(prompt, isNot(contains('nri: food')));
    });

    test('adds story instructions when storyContext is set', () {
      final prompt = buildSystemPrompt(
        _context(storyContext: 'Nwoke ahụ gara ahịa.'),
      );
      expect(prompt, contains('Talk about the story given below.'));
      expect(prompt, contains('2-3 simple questions'));
      expect(prompt, contains('Quote the story text'));
      expect(prompt, contains('Nwoke ahụ gara ahịa.'));
    });

    test('omits story section when storyContext is null', () {
      final prompt = buildSystemPrompt(_context());
      expect(prompt, isNot(contains('Talk about the story')));
      expect(prompt, isNot(contains('Story:')));
    });
  });

  group('trimHistory', () {
    List<TutorTurn> pairs(int count) {
      return [
        for (var i = 0; i < count; i++) ...[
          TutorTurn(role: 'user', text: 'u$i'),
          TutorTurn(role: 'tutor', text: 't$i'),
        ],
      ];
    }

    test('returns empty for empty history', () {
      expect(trimHistory(const []), isEmpty);
    });

    test('keeps short histories intact', () {
      final history = pairs(2);
      expect(trimHistory(history), history);
    });

    test('keeps the last N turns and drops the oldest', () {
      final history = pairs(8); // 16 turns
      final trimmed = trimHistory(history, maxTurns: 6);
      expect(trimmed.length, 6);
      expect(trimmed.first.text, 'u5');
      expect(trimmed.last.text, 't7');
    });

    test('preserves order', () {
      final history = pairs(5);
      final trimmed = trimHistory(history, maxTurns: 4);
      expect(
        trimmed.map((t) => t.text).toList(),
        history.sublist(history.length - trimmed.length).map((t) => t.text),
      );
    });

    test('kept window starts on a user turn', () {
      final history = pairs(6);
      final trimmed = trimHistory(history, maxTurns: 4);
      expect(trimmed.first.role, 'user');
      expect(trimmed.length, lessThanOrEqualTo(4));
    });

    test('zero maxTurns returns empty', () {
      expect(trimHistory(pairs(3), maxTurns: 0), isEmpty);
    });
  });

  group('buildSessionGreeting', () {
    test('is non-empty and contains Igbo text', () {
      for (final units in [0, 1, 3, 5, 9]) {
        final greeting = buildSessionGreeting(
          _context(completedUnits: units, storyContext: null),
        );
        expect(greeting, isNotEmpty);
        expect(
          greeting,
          anyOf(
            contains('Ndewo'),
            contains('kedu'),
            contains('nke'),
            contains('biko'),
          ),
        );
      }
    });

    test('uses the learner name', () {
      final greeting = buildSessionGreeting(_context(learnerName: 'Sam'));
      expect(greeting, contains('Sam'));
    });

    test('low level gets a simple opening', () {
      final greeting = buildSessionGreeting(_context(completedUnits: 1));
      expect(greeting, contains('one simple question'));
    });

    test('higher level gets a richer welcome', () {
      final low = buildSessionGreeting(_context(completedUnits: 1));
      final high = buildSessionGreeting(_context(completedUnits: 8));
      expect(high.length, greaterThan(low.length));
      expect(high, contains('real chat in Igbo'));
    });

    test('story greeting references the story', () {
      final greeting = buildSessionGreeting(
        _context(completedUnits: 8, storyContext: 'Nwoke ahụ gara ahịa.'),
      );
      expect(greeting, contains('story'));
    });
  });
}