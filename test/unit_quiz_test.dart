import 'package:flutter_test/flutter_test.dart';

import 'package:igboman/data/curriculum.dart';
import 'package:igboman/models/lesson.dart';
import 'package:igboman/services/unit_quiz.dart';

void main() {
  final unit = unit01;

  group('buildUnitQuiz', () {
    test('produces a skipIntro lesson with six questions', () {
      final quiz = buildUnitQuiz(unit);
      expect(quiz.id, 'unit_quiz_1');
      expect(quiz.title, 'Unit 1 Quiz');
      expect(quiz.skipIntro, isTrue);
      expect(quiz.questions.length, 6);
    });

    test('is deterministic: rebuilding yields identical output', () {
      final a = buildUnitQuiz(unit);
      final b = buildUnitQuiz(unit);
      for (var i = 0; i < a.questions.length; i++) {
        expect(a.questions[i].id, b.questions[i].id);
        expect(a.questions[i].prompt, b.questions[i].prompt);
        expect(a.questions[i].options, b.questions[i].options);
        expect(a.questions[i].wordBank, b.questions[i].wordBank);
        expect(a.questions[i].answer, b.questions[i].answer);
      }
    });

    test('covers every question type with valid distractors', () {
      final quiz = buildUnitQuiz(unit);
      final vocabIgbo = unit.vocab.map((v) => v.igbo).toSet();

      final q1 = quiz.questions[0];
      expect(q1.type, QuestionType.mcqEnglishToIgbo);
      expect(q1.options.length, 4);
      expect(q1.options.toSet().length, 4, reason: 'options must be unique');
      expect(q1.options, contains(q1.answer));
      for (final option in q1.options) {
        expect(
          vocabIgbo,
          contains(option),
          reason: 'distractors must be real unit words',
        );
      }

      final q3 = quiz.questions[2];
      expect(q3.options.length, 5, reason: 'harder variant has five options');
      expect(q3.options.toSet().length, 5);

      final q4 = quiz.questions[3];
      expect(q4.type, QuestionType.matchPairs);
      expect(q4.pairs.length, 4);

      final q5 = quiz.questions[4];
      expect(q5.type, QuestionType.fillBlank);
      expect(q5.wordBank.length, 4);
      expect(q5.wordBank, contains(q5.answer));

      final q6 = quiz.questions[5];
      expect(q6.type, QuestionType.translate);
      expect(q6.acceptedAnswers.length, 2);
    });

    test('igbo-to-english direction uses English answers and distractors', () {
      final q2 = buildUnitQuiz(unit).questions[1];
      expect(q2.type, QuestionType.mcqIgboToEnglish);
      expect(q2.answer, isIn(q2.options));
      // The English meanings come from the unit vocab too.
      final vocabEn = unit.vocab.map((v) => v.en).toSet();
      for (final option in q2.options) {
        expect(vocabEn, contains(option));
      }
    });
  });
}
