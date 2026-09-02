import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/data/alphabet.dart';
import 'package:igboman/data/curriculum.dart';
import 'package:igboman/models/lesson.dart';

void main() {
  group('Alphabet and Orthography Data', () {
    test('igboLetters36 has exactly 36 entries and contains special characters and digraphs', () {
      expect(igboLetters36.length, 36);
      expect(
        igboLetters36.toSet().length,
        36,
        reason: 'All letters should be unique',
      );
      expect(igboLetters36, containsAll(['ị', 'ọ', 'ụ', 'ṅ']));

      for (final digraph in igboDigraphs) {
        expect(
          igboLetters36,
          contains(digraph),
          reason: 'Digraph $digraph should be in igboLetters36',
        );
      }
    });

    test('igboVowels8 has exactly 8 entries and all are in igboLetters36', () {
      expect(igboVowels8.length, 8);
      expect(igboVowels8.toSet().length, 8);
      expect(igboLetters36, containsAll(igboVowels8));
    });

    test('igboDigraphs has 9 entries and igboLettersEasy has 23 entries', () {
      expect(igboDigraphs.length, 9);
      expect(igboLettersEasy.length, 23);
      expect(igboLetters36, containsAll(igboLettersEasy));
    });
  });

  group('Curriculum Structure and Units', () {
    test('curriculum has exactly 13 units with ids 1 through 13 in sequential order', () {
      expect(curriculum.length, 13);
      for (var i = 0; i < curriculum.length; i++) {
        expect(curriculum[i].id, i + 1);
      }
    });

    test(
      'unitById returns the corresponding unit and throws for invalid id',
      () {
        for (var i = 1; i <= 13; i++) {
          final unit = unitById(i);
          expect(unit.id, i);
        }
        expect(() => unitById(0), throwsArgumentError);
        expect(() => unitById(14), throwsArgumentError);
      },
    );

    test('every unit has 4 to 6 lessons and valid titles', () {
      for (final unit in curriculum) {
        expect(
          unit.titleIgbo.trim(),
          isNotEmpty,
          reason: 'Unit ${unit.id} titleIgbo must not be empty',
        );
        expect(
          unit.titleEn.trim(),
          isNotEmpty,
          reason: 'Unit ${unit.id} titleEn must not be empty',
        );
        expect(
          unit.lessons.length,
          inInclusiveRange(4, 6),
          reason: 'Unit ${unit.id} should have between 4 and 6 lessons',
        );
      }
    });

    test('every lesson has 4 to 8 questions and short English title', () {
      for (final unit in curriculum) {
        for (final lesson in unit.lessons) {
          expect(
            lesson.title.trim(),
            isNotEmpty,
            reason:
                'Lesson ${lesson.id} in Unit ${unit.id} title must not be empty',
          );
          expect(
            lesson.questions.length,
            inInclusiveRange(4, 8),
            reason:
                'Lesson ${lesson.id} in Unit ${unit.id} should have between 4 and 8 questions',
          );
        }
      }
    });

    test('question IDs are globally unique and follow u<unit>l<lesson>q<question> pattern', () {
      final questionIds = <String>{};
      final idPattern = RegExp(r'^u\d+l\d+q\d+$');

      for (final unit in curriculum) {
        for (final lesson in unit.lessons) {
          for (final question in lesson.questions) {
            expect(
              idPattern.hasMatch(question.id),
              isTrue,
              reason:
                  'Question ID ${question.id} must match format u<unit>l<lesson>q<question>',
            );
            expect(
              questionIds.contains(question.id),
              isFalse,
              reason: 'Question ID ${question.id} is duplicated',
            );
            questionIds.add(question.id);
          }
        }
      }
    });
  });

  group('Question Quality and Invariants', () {
    test('MCQ questions satisfy all constraints', () {
      for (final unit in curriculum) {
        for (final lesson in unit.lessons) {
          for (final question in lesson.questions) {
            if (question.type == QuestionType.mcqIgboToEnglish ||
                question.type == QuestionType.mcqEnglishToIgbo) {
              expect(
                question.options.length,
                inInclusiveRange(3, 4),
                reason: 'MCQ ${question.id} must have 3 to 4 options',
              );
              expect(
                question.options.toSet().length,
                question.options.length,
                reason: 'MCQ ${question.id} must not have duplicate options',
              );
              expect(
                question.answer,
                isNotNull,
                reason: 'MCQ ${question.id} answer must not be null',
              );
              expect(
                question.options,
                contains(question.answer),
                reason: 'MCQ ${question.id} options must contain its answer',
              );
            }
          }
        }
      }
    });

    test('matchPairs questions satisfy all constraints', () {
      for (final unit in curriculum) {
        for (final lesson in unit.lessons) {
          for (final question in lesson.questions) {
            if (question.type == QuestionType.matchPairs) {
              expect(
                question.pairs.length,
                inInclusiveRange(3, 5),
                reason: 'MatchPairs ${question.id} must have 3 to 5 pairs',
              );

              final rightValues = <String>{};
              final leftValues = <String>{};
              for (final pair in question.pairs) {
                expect(
                  pair.left.trim(),
                  isNotEmpty,
                  reason:
                      'MatchPairs ${question.id} pair left side must not be empty',
                );
                expect(
                  pair.right.trim(),
                  isNotEmpty,
                  reason:
                      'MatchPairs ${question.id} pair right side must not be empty',
                );
                expect(
                  rightValues.contains(pair.right),
                  isFalse,
                  reason:
                      'MatchPairs ${question.id} right value "${pair.right}" must be unique',
                );
                rightValues.add(pair.right);
                leftValues.add(pair.left);
              }
            }
          }
        }
      }
    });

    test('fillBlank questions satisfy all constraints', () {
      for (final unit in curriculum) {
        for (final lesson in unit.lessons) {
          for (final question in lesson.questions) {
            if (question.type == QuestionType.fillBlank) {
              expect(
                question.prompt,
                contains('___'),
                reason: 'FillBlank ${question.id} prompt must contain "___"',
              );
              expect(
                question.wordBank.length,
                inInclusiveRange(3, 4),
                reason:
                    'FillBlank ${question.id} wordBank must have 3 to 4 words',
              );
              expect(
                question.wordBank.toSet().length,
                question.wordBank.length,
                reason:
                    'FillBlank ${question.id} wordBank must not contain duplicates',
              );
              expect(
                question.answer,
                isNotNull,
                reason: 'FillBlank ${question.id} answer must not be null',
              );
              expect(
                question.wordBank,
                contains(question.answer),
                reason:
                    'FillBlank ${question.id} wordBank must contain the answer',
              );
            }
          }
        }
      }
    });

    test('translate questions satisfy all constraints', () {
      const tonalMinimalPairWords = {'ákwà', 'àkwà', 'mmà', 'mmá'};

      for (final unit in curriculum) {
        for (final lesson in unit.lessons) {
          for (final question in lesson.questions) {
            if (question.type == QuestionType.translate) {
              expect(
                question.answer,
                isNotNull,
                reason: 'Translate ${question.id} answer must not be null',
              );
              expect(
                question.acceptedAnswers,
                isNotEmpty,
                reason:
                    'Translate ${question.id} acceptedAnswers must not be empty',
              );
              expect(
                question.acceptedAnswers,
                contains(question.answer),
                reason:
                    'Translate ${question.id} acceptedAnswers must contain answer',
              );

              // Check if English->Igbo minimal pair requires toneLenient == false
              final isEnglishToIgbo = question.prompt.toLowerCase().contains(
                'igbo for',
              );
              if (isEnglishToIgbo &&
                  tonalMinimalPairWords.any(
                    (w) => question.answer!.contains(w),
                  )) {
                expect(
                  question.toneLenient,
                  isFalse,
                  reason:
                      'Translate ${question.id} with minimal pair answer must have toneLenient false',
                );
              }
            }
          }
        }
      }
    });

    test('Unit 1 uses only mcq, matchPairs, fillBlank (no translate)', () {
      for (final lesson in unit01.lessons) {
        for (final question in lesson.questions) {
          expect(
            question.type,
            isNot(QuestionType.translate),
            reason: 'Unit 1 question ${question.id} must not be translate',
          );
        }
      }
    });

    test('Units 3 to 13 contain at least one translate question', () {
      for (var id = 3; id <= 13; id++) {
        final unit = unitById(id);
        final hasTranslate = unit.lessons.any(
          (lesson) =>
              lesson.questions.any((q) => q.type == QuestionType.translate),
        );
        expect(
          hasTranslate,
          isTrue,
          reason: 'Unit $id must contain translate questions',
        );
      }
    });
  });

  group('Vocabulary and Orthography Integrity', () {
    test('every VocabEntry has non-empty igbo and en', () {
      for (final unit in curriculum) {
        expect(
          unit.vocab.length,
          inInclusiveRange(8, 15),
          reason: 'Unit ${unit.id} vocab count should be between 8 and 15',
        );
        for (final entry in unit.vocab) {
          expect(
            entry.igbo.trim(),
            isNotEmpty,
            reason: 'Unit ${unit.id} vocab entry igbo must not be empty',
          );
          expect(
            entry.en.trim(),
            isNotEmpty,
            reason: 'Unit ${unit.id} vocab entry en must not be empty',
          );
        }
      }
    });

    test('spot checks for specific vocab and lesson contents', () {
      expect(
        unit03.vocab.any((v) => v.igbo == 'ndewo'),
        isTrue,
        reason: 'Unit 3 vocab must contain ndewo',
      );
      expect(
        unit04.vocab.any((v) => v.igbo == 'otu'),
        isTrue,
        reason: 'Unit 4 vocab must contain otu',
      );
      expect(
        unit04.vocab.any((v) => v.igbo == 'iri'),
        isTrue,
        reason: 'Unit 4 vocab must contain iri',
      );

      final unit1HasGb = unit01.lessons.any(
        (lesson) => lesson.questions.any(
          (q) =>
              q.prompt.contains('gb') ||
              q.options.contains('gb') ||
              q.answer == 'gb' ||
              q.pairs.any((p) => p.left == 'gb' || p.right == 'gb'),
        ),
      );
      expect(
        unit1HasGb,
        isTrue,
        reason: 'Unit 1 must contain a question referencing the gb digraph',
      );
    });

    test(
      'NO em dashes (U+2014) or en dashes (U+2013) anywhere in content strings',
      () {
        const emDash = '\u2014';
        const enDash = '\u2013';

        void assertNoDash(String str, String location) {
          expect(
            str.contains(emDash),
            isFalse,
            reason: 'Found em dash in $location: "$str"',
          );
          expect(
            str.contains(enDash),
            isFalse,
            reason: 'Found en dash in $location: "$str"',
          );
        }

        for (final letter in igboLetters36) {
          assertNoDash(letter, 'igboLetters36');
        }
        for (final vowel in igboVowels8) {
          assertNoDash(vowel, 'igboVowels8');
        }
        for (final digraph in igboDigraphs) {
          assertNoDash(digraph, 'igboDigraphs');
        }
        for (final letter in igboLettersEasy) {
          assertNoDash(letter, 'igboLettersEasy');
        }

        for (final unit in curriculum) {
          assertNoDash(unit.titleIgbo, 'unit ${unit.id} titleIgbo');
          assertNoDash(unit.titleEn, 'unit ${unit.id} titleEn');

          for (final vocab in unit.vocab) {
            assertNoDash(vocab.igbo, 'unit ${unit.id} vocab igbo');
            assertNoDash(vocab.en, 'unit ${unit.id} vocab en');
          }

          for (final lesson in unit.lessons) {
            assertNoDash(lesson.title, 'lesson ${lesson.id} title');

            for (final q in lesson.questions) {
              assertNoDash(q.prompt, 'question ${q.id} prompt');
              if (q.answer != null) {
                assertNoDash(q.answer!, 'question ${q.id} answer');
              }
              for (final opt in q.options) {
                assertNoDash(opt, 'question ${q.id} option');
              }
              for (final acc in q.acceptedAnswers) {
                assertNoDash(acc, 'question ${q.id} acceptedAnswer');
              }
              for (final wb in q.wordBank) {
                assertNoDash(wb, 'question ${q.id} wordBank');
              }
              for (final p in q.pairs) {
                assertNoDash(p.left, 'question ${q.id} pair left');
                assertNoDash(p.right, 'question ${q.id} pair right');
              }
            }
          }
        }
      },
    );
  });
}
