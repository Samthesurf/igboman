import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/services/answer_checker.dart';

void main() {
  group('AnswerChecker.normalize', () {
    test('trims leading and trailing whitespace', () {
      expect(AnswerChecker.normalize('  hello  '), 'hello');
    });

    test('collapses consecutive whitespace to single space', () {
      expect(AnswerChecker.normalize('hello   world'), 'hello world');
    });

    test('converts to lowercase', () {
      expect(AnswerChecker.normalize('Hello World'), 'hello world');
    });

    test('strips surrounding punctuation', () {
      expect(AnswerChecker.normalize('.hello.'), 'hello');
      expect(AnswerChecker.normalize('"hello"'), 'hello');
      expect(AnswerChecker.normalize('hello!'), 'hello');
    });

    test('normalizes decomposed underdot i to precomposed ị', () {
      // i + combining underdot (U+0323)
      expect(AnswerChecker.normalize('i\u0323'), '\u1ecb');
    });

    test('normalizes decomposed underdot o to precomposed ọ', () {
      expect(AnswerChecker.normalize('o\u0323'), '\u1ecd');
    });

    test('normalizes decomposed underdot u to precomposed ụ', () {
      expect(AnswerChecker.normalize('u\u0323'), '\u1ef5');
    });

    test('normalizes decomposed n dot above to precomposed ṅ', () {
      expect(AnswerChecker.normalize('n\u0307'), '\u1e45');
    });
  });

  group('AnswerChecker.check - exact match', () {
    test('exact match returns correct: true, toneNote: false', () {
      final result = AnswerChecker.check(
        userInput: 'Nnoo',
        acceptedAnswers: ['nnoo'],
      );
      expect(result, const AnswerCheckResult(correct: true, toneNote: false));
    });

    test('case-insensitive match', () {
      final result = AnswerChecker.check(
        userInput: 'WATER',
        acceptedAnswers: ['water'],
      );
      expect(result.correct, isTrue);
    });

    test('match with punctuation stripped', () {
      final result = AnswerChecker.check(
        userInput: '"hello!"',
        acceptedAnswers: ['hello'],
      );
      expect(result.correct, isTrue);
    });

    test('whitespace-normalized match', () {
      final result = AnswerChecker.check(
        userInput: '  Nna    m  ',
        acceptedAnswers: ['nna m'],
      );
      expect(result.correct, isTrue);
    });

    test('wrong answer returns correct: false', () {
      final result = AnswerChecker.check(
        userInput: 'wrong',
        acceptedAnswers: ['right'],
      );
      expect(result, const AnswerCheckResult(correct: false, toneNote: false));
    });

    test('empty input against non-empty accepted answers returns false', () {
      final result = AnswerChecker.check(
        userInput: '',
        acceptedAnswers: ['hello'],
      );
      expect(result.correct, isFalse);
    });

    test('matches against multiple accepted answers', () {
      final result = AnswerChecker.check(
        userInput: 'bye',
        acceptedAnswers: ['goodbye', 'bye', 'farewell'],
      );
      expect(result.correct, isTrue);
    });
  });

  group('AnswerChecker.check - tone marks (strict mode)', () {
    test('wrong tone mark in strict mode returns false', () {
      // "oma" vs "oma" with acute -> still exact
      final result = AnswerChecker.check(
        userInput: 'oma',
        acceptedAnswers: ['oma'],
        toneLenient: false,
      );
      expect(result.correct, isTrue);
    });

    test('missing acute tone mark in strict mode returns false', () {
      final result = AnswerChecker.check(
        userInput: 'oma',
        acceptedAnswers: ['omá'],
        toneLenient: false,
      );
      expect(result.correct, isFalse);
      expect(result.toneNote, isFalse);
    });
  });

  group('AnswerChecker.check - tone marks (lenient mode)', () {
    test('missing tone mark in lenient mode returns correct with toneNote', () {
      final result = AnswerChecker.check(
        userInput: 'oma',
        acceptedAnswers: ['omá'],
        toneLenient: true,
      );
      expect(result.correct, isTrue);
      expect(result.toneNote, isTrue);
    });

    test('correct tone mark in lenient mode returns correct without toneNote', () {
      final result = AnswerChecker.check(
        userInput: 'omá',
        acceptedAnswers: ['omá'],
        toneLenient: true,
      );
      expect(result.correct, isTrue);
      expect(result.toneNote, isFalse);
    });

    test('wrong letter in lenient mode returns false even with lenient', () {
      final result = AnswerChecker.check(
        userInput: 'xyz',
        acceptedAnswers: ['omá'],
        toneLenient: true,
      );
      expect(result.correct, isFalse);
    });

    test('grave accent stripped in lenient mode', () {
      final result = AnswerChecker.check(
        userInput: 'oma',
        acceptedAnswers: ['omà'],
        toneLenient: true,
      );
      expect(result.correct, isTrue);
      expect(result.toneNote, isTrue);
    });
  });

  group('AnswerChecker - underdot NEVER lenient', () {
    test('underdot ị vs i is wrong even in lenient mode', () {
      final result = AnswerChecker.check(
        userInput: 'isi',
        acceptedAnswers: ['isi\u1ecb'], // ị
        toneLenient: true,
      );
      expect(result.correct, isFalse);
      expect(result.toneNote, isFalse);
    });

    test('underdot ọ vs o is wrong even in lenient mode', () {
      final result = AnswerChecker.check(
        userInput: 'ulo',
        acceptedAnswers: ['ul\u1ecd'], // ụlọ
        toneLenient: true,
      );
      expect(result.correct, isFalse);
    });

    test('underdot ụ vs u is wrong even in lenient mode', () {
      final result = AnswerChecker.check(
        userInput: 'ulo',
        acceptedAnswers: ['\u1ef5lo'], // ụlo
        toneLenient: true,
      );
      expect(result.correct, isFalse);
    });

    test('correct underdots with wrong tone accepted in lenient mode', () {
      // isi\u1ecb (ị) with grave vs accepted with acute
      final result = AnswerChecker.check(
        userInput: 'is\u00ec\u1ecb', // ì + ị (grave on i, underdot on terminal i)
        acceptedAnswers: ['is\u00ed\u1ecb'], // í + ị (acute on i, underdot)
        toneLenient: true,
      );
      expect(result.correct, isTrue);
      expect(result.toneNote, isTrue);
    });
  });
}
