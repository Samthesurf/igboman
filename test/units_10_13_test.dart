import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/data/curriculum.dart';
import 'package:igboman/models/lesson.dart';

void main() {
  const newUnitIds = [10, 11, 12, 13];

  group('Units 10 to 13 structure', () {
    test('units 10 to 13 are registered with sequential ids', () {
      for (final id in newUnitIds) {
        final unit = unitById(id);
        expect(unit.id, id, reason: 'Unit $id must exist in the curriculum');
        expect(unit.titleIgbo.trim(), isNotEmpty);
        expect(unit.titleEn.trim(), isNotEmpty);
      }
      expect(curriculum.length, 13);
    });

    test('every new unit has exactly 5 lessons and 5 questions per lesson', () {
      for (final id in newUnitIds) {
        final unit = unitById(id);
        expect(unit.lessons.length, 5, reason: 'Unit $id must have 5 lessons');
        for (final lesson in unit.lessons) {
          expect(
            lesson.questions.length,
            5,
            reason: 'Lesson ${lesson.id} must have exactly 5 questions',
          );
          expect(
            RegExp(
              '^u$id'
              r'l\d+q\d+$',
            ).hasMatch(lesson.questions.first.id),
            isTrue,
            reason:
                'Lesson ${lesson.id} question ids must follow u<unit>l<lesson>q<question>',
          );
        }
      }
    });

    test('every new unit has 12 to 15 unique non-empty vocab entries', () {
      for (final id in newUnitIds) {
        final unit = unitById(id);
        expect(
          unit.vocab.length,
          inInclusiveRange(12, 15),
          reason: 'Unit $id vocab count must be 12 to 15',
        );
        final igboSet = <String>{};
        for (final entry in unit.vocab) {
          expect(
            entry.igbo.trim(),
            isNotEmpty,
            reason: 'Unit $id has an empty igbo vocab entry',
          );
          expect(
            entry.en.trim(),
            isNotEmpty,
            reason: 'Unit $id vocab entry "${entry.igbo}" has empty english',
          );
          expect(
            igboSet.contains(entry.igbo),
            isFalse,
            reason: 'Unit $id has duplicate vocab "${entry.igbo}"',
          );
          igboSet.add(entry.igbo);
        }
      }
    });
  });

  group('Units 10 to 13 question invariants', () {
    test('every lesson has at least one MCQ and every unit has matchPairs, fillBlank and translate', () {
      for (final id in newUnitIds) {
        final unit = unitById(id);
        final unitTypes = <QuestionType>{};
        for (final lesson in unit.lessons) {
          final lessonTypes = lesson.questions.map((q) => q.type).toSet();
          expect(
            lessonTypes.any(
              (t) =>
                  t == QuestionType.mcqIgboToEnglish ||
                  t == QuestionType.mcqEnglishToIgbo,
            ),
            isTrue,
            reason: 'Lesson ${lesson.id} must contain at least one MCQ',
          );
          unitTypes.addAll(lessonTypes);
        }
        expect(
          unitTypes,
          contains(QuestionType.matchPairs),
          reason: 'Unit $id must contain at least one matchPairs question',
        );
        expect(
          unitTypes,
          contains(QuestionType.fillBlank),
          reason: 'Unit $id must contain at least one fillBlank question',
        );
        expect(
          unitTypes,
          contains(QuestionType.translate),
          reason: 'Unit $id must contain at least one translate question',
        );
      }
    });

    test(
      'MCQ questions have exactly 4 unique options including the answer',
      () {
        for (final id in newUnitIds) {
          for (final lesson in unitById(id).lessons) {
            for (final q in lesson.questions) {
              if (q.type == QuestionType.mcqIgboToEnglish ||
                  q.type == QuestionType.mcqEnglishToIgbo) {
                expect(
                  q.options.length,
                  4,
                  reason: 'MCQ ${q.id} must have exactly 4 options',
                );
                expect(
                  q.options.toSet().length,
                  4,
                  reason: 'MCQ ${q.id} options must be unique',
                );
                expect(
                  q.answer,
                  isNotNull,
                  reason: 'MCQ ${q.id} needs an answer',
                );
                expect(
                  q.options,
                  contains(q.answer),
                  reason: 'MCQ ${q.id} options must contain the answer',
                );
                for (final opt in q.options) {
                  expect(
                    opt.trim(),
                    isNotEmpty,
                    reason: 'MCQ ${q.id} has an empty option',
                  );
                }
              }
            }
          }
        }
      },
    );

    test(
      'fillBlank questions have 4 distinct wordBank words including the answer',
      () {
        for (final id in newUnitIds) {
          for (final lesson in unitById(id).lessons) {
            for (final q in lesson.questions) {
              if (q.type == QuestionType.fillBlank) {
                expect(
                  q.prompt,
                  contains('___'),
                  reason:
                      'FillBlank ${q.id} prompt must contain three underscores',
                );
                expect(
                  q.wordBank.length,
                  4,
                  reason: 'FillBlank ${q.id} wordBank must have 4 entries',
                );
                expect(
                  q.wordBank.toSet().length,
                  4,
                  reason: 'FillBlank ${q.id} wordBank must be distinct',
                );
                expect(
                  q.answer,
                  isNotNull,
                  reason: 'FillBlank ${q.id} needs an answer',
                );
                expect(
                  q.wordBank,
                  contains(q.answer),
                  reason: 'FillBlank ${q.id} wordBank must contain the answer',
                );
              }
            }
          }
        }
      },
    );

    test('matchPairs questions have 4 non-empty unique pairs', () {
      for (final id in newUnitIds) {
        for (final lesson in unitById(id).lessons) {
          for (final q in lesson.questions) {
            if (q.type == QuestionType.matchPairs) {
              expect(
                q.pairs.length,
                4,
                reason: 'MatchPairs ${q.id} must have exactly 4 pairs',
              );
              final lefts = <String>{};
              final rights = <String>{};
              for (final pair in q.pairs) {
                expect(
                  pair.left.trim(),
                  isNotEmpty,
                  reason: 'MatchPairs ${q.id} has an empty left side',
                );
                expect(
                  pair.right.trim(),
                  isNotEmpty,
                  reason: 'MatchPairs ${q.id} has an empty right side',
                );
                lefts.add(pair.left);
                rights.add(pair.right);
              }
              expect(
                lefts.length,
                4,
                reason: 'MatchPairs ${q.id} left sides must be unique',
              );
              expect(
                rights.length,
                4,
                reason: 'MatchPairs ${q.id} right sides must be unique',
              );
            }
          }
        }
      }
    });

    test('translate questions have a non-empty prompt and acceptedAnswers containing the answer', () {
      for (final id in newUnitIds) {
        for (final lesson in unitById(id).lessons) {
          for (final q in lesson.questions) {
            if (q.type == QuestionType.translate) {
              expect(
                q.prompt.trim(),
                isNotEmpty,
                reason: 'Translate ${q.id} prompt must not be empty',
              );
              expect(
                q.answer,
                isNotNull,
                reason: 'Translate ${q.id} needs an answer',
              );
              expect(
                q.acceptedAnswers,
                isNotEmpty,
                reason: 'Translate ${q.id} acceptedAnswers must not be empty',
              );
              expect(
                q.acceptedAnswers,
                contains(q.answer),
                reason:
                    'Translate ${q.id} acceptedAnswers must contain the answer',
              );
              expect(
                q.acceptedAnswers.length,
                inInclusiveRange(1, 4),
                reason: 'Translate ${q.id} should have 1 to 4 accepted answers',
              );
              for (final acc in q.acceptedAnswers) {
                expect(
                  acc.trim(),
                  isNotEmpty,
                  reason: 'Translate ${q.id} has an empty accepted answer',
                );
              }
            }
          }
        }
      }
    });
  });

  group('Units 10 to 13 dash scan', () {
    test('NO em dashes (U+2014) or en dashes (U+2013) anywhere in new unit strings', () {
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

      for (final id in newUnitIds) {
        final unit = unitById(id);
        assertNoDash(unit.titleIgbo, 'unit $id titleIgbo');
        assertNoDash(unit.titleEn, 'unit $id titleEn');
        for (final vocab in unit.vocab) {
          assertNoDash(vocab.igbo, 'unit $id vocab igbo');
          assertNoDash(vocab.en, 'unit $id vocab en');
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
    });
  });
}
