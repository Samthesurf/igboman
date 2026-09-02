import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/data/curriculum.dart';
import 'package:igboman/data/stories.dart';
import 'package:igboman/models/lesson.dart';
import 'package:igboman/models/story.dart';
import 'package:igboman/widgets/tappable_text.dart';

/// Recurring cast names are allowed in every story.
const _storyNames = {'ada', 'obi', 'nna', 'mama', 'mbe'};

/// Verb inflection suffixes handled by the tokenizer lookup rules.
const _verbSuffixes = ['ra', 'la', 'rụ', 'lụ', 'ru', 'lu'];

const _emDash = '\u2014';
const _enDash = '\u2013';

/// The whitelist for a story: every word of every vocab entry of units up to
/// and including the story unit, plus the story's own new words, the stop
/// list, and the cast names. Multi-word entries teach their constituent
/// words, so each word of a phrase is allowed.
Set<String> _allowedFor(Story story) {
  final allowed = <String>{};
  for (final unit in curriculum) {
    if (unit.id > story.unitId) {
      break;
    }
    for (final entry in unit.vocab) {
      allowed.addAll(entry.igbo.toLowerCase().split(' '));
    }
  }
  for (final newWord in story.newWords) {
    allowed.addAll(newWord.igbo.toLowerCase().split(' '));
  }
  allowed.addAll(storyStopWords);
  allowed.addAll(_storyNames);
  return allowed;
}

bool _wordAllowed(String word, Set<String> allowed) {
  if (allowed.contains(word)) {
    return true;
  }
  for (final suffix in _verbSuffixes) {
    if (word.endsWith(suffix) && word.length > suffix.length) {
      final base = word.substring(0, word.length - suffix.length);
      if (allowed.contains(base)) {
        return true;
      }
    }
  }
  if (word.startsWith("n'") &&
      word.length > 2 &&
      allowed.contains(word.substring(2))) {
    return true;
  }
  if (word.startsWith('na-') &&
      word.length > 3 &&
      allowed.contains(word.substring(3))) {
    return true;
  }
  return false;
}

void _expectNoDashes(String value, String what) {
  expect(
    value.contains(_emDash) || value.contains(_enDash),
    isFalse,
    reason: '$what must not contain em/en dashes: "$value"',
  );
}

void main() {
  test('there are exactly 7 stories with sequential ids and units', () {
    expect(stories.length, 7);
    for (var i = 0; i < stories.length; i++) {
      final story = stories[i];
      final unitId = i + 3;
      expect(story.id, 'story_${unitId.toString().padLeft(2, '0')}',
          reason: 'story ${story.titleEn} has unexpected id ${story.id}');
      expect(story.unitId, unitId,
          reason: 'story ${story.id} must map to unit $unitId');
      expect(storyForUnit(unitId), same(story));
    }
    expect(storyForUnit(1), isNull);
    expect(storyForUnit(10), isNull);
  });

  test('story stop words cover the locked function-word list', () {
    const expected = {
      'na', 'nke', 'a', 'ahụ', 'ebe', 'mba', 'ee', 'dị', 'bụ', 'ka', 'kwa',
      "n'", 'na-', 'm', 'mụ', 'ị', 'ọ', 'ya', 'anyị', 'unu', 'ha', '-ra',
      '-la', '-rụ', '-lụ', '-ru', '-lu',
    };
    expect(storyStopWords, expected);
  });

  test('every story has 6 to 10 non-empty short sentences', () {
    for (final story in stories) {
      expect(story.sentences.length, inInclusiveRange(6, 10),
          reason: '${story.id} must have 6-10 sentences');
      for (final sentence in story.sentences) {
        expect(sentence.trim().isNotEmpty, isTrue,
            reason: '${story.id} has an empty sentence');
        expect(sentence.length, lessThanOrEqualTo(140),
            reason: '${story.id} has an overlong sentence: "$sentence"');
        _expectNoDashes(sentence, '${story.id} sentence');
      }
    }
  });

  test('every story has 1 to 5 new words with no dashes', () {
    for (final story in stories) {
      expect(story.newWords.length, inInclusiveRange(1, 5),
          reason: '${story.id} must have 1-5 new words');
      for (final newWord in story.newWords) {
        expect(newWord.igbo.trim().isNotEmpty, isTrue);
        expect(newWord.en.trim().isNotEmpty, isTrue);
        _expectNoDashes(newWord.igbo, '${story.id} new word');
        _expectNoDashes(newWord.en, '${story.id} new word meaning');
      }
    }
  });

  test('every story has 2-3 mcqEnglishToIgbo questions with valid options',
      () {
    final seenIds = <String>{};
    for (final story in stories) {
      expect(story.questions.length, inInclusiveRange(2, 3),
          reason: '${story.id} must have 2-3 questions');
      for (final question in story.questions) {
        expect(question.id, startsWith('story${story.unitId.toString().padLeft(2, '0')}q'),
            reason: '${story.id} question id ${question.id} must be story-prefixed');
        expect(seenIds.add(question.id), isTrue,
            reason: 'duplicate question id ${question.id}');
        expect(question.type, QuestionType.mcqEnglishToIgbo,
            reason: '${question.id} must be mcqEnglishToIgbo');
        expect(question.prompt.trim().isNotEmpty, isTrue);
        _expectNoDashes(question.prompt, '${question.id} prompt');
        expect(question.options.length, inInclusiveRange(3, 4),
            reason: '${question.id} must have 3-4 options');
        expect(question.answer, isNotNull);
        expect(question.options, contains(question.answer),
            reason: '${question.id} answer must be one of the options');
        for (final option in question.options) {
          expect(option.trim().isNotEmpty, isTrue);
          _expectNoDashes(option, '${question.id} option');
        }
      }
    }
  });

  test('lexical control: story words come from unit vocab, new words, or '
      'the stop list', () {
    for (final story in stories) {
      final allowed = _allowedFor(story);
      for (var sentenceIndex = 0;
          sentenceIndex < story.sentences.length;
          sentenceIndex++) {
        final sentence = story.sentences[sentenceIndex];
        for (final word in TokenizedText.words(sentence)) {
          expect(
            _wordAllowed(word, allowed),
            isTrue,
            reason: 'story_${story.unitId.toString().padLeft(2, '0')} '
                'sentence ${sentenceIndex + 1}: '
                'word not allowed: $word',
          );
        }
      }
    }
  });

  test('lookup keys resolve for words the raw whitelist did not cover', () {
    for (final story in stories) {
      final allowed = _allowedFor(story);
      for (final sentence in story.sentences) {
        final raws = TokenizedText.words(sentence);
        final keys = TokenizedText.tokenize(sentence);
        for (var i = 0; i < raws.length && i < keys.length; i++) {
          if (_wordAllowed(raws[i], allowed)) {
            continue; // the raw word itself is whitelisted
          }
          expect(_wordAllowed(keys[i], allowed), isTrue,
              reason: '${story.id} lookup key not allowed: ${keys[i]}');
        }
      }
    }
  });
}