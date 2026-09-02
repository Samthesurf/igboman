import 'dart:math' as math;

import '../models/lesson.dart';
import '../models/unit.dart';

/// Builds the end-of-unit assessment: a harder quiz drawn from the unit's
/// vocabulary and lesson content.
///
/// The quiz reuses the [Lesson] model (and therefore the whole lesson runner
/// UI, XP and replay logic) but is flagged [Lesson.skipIntro] so it jumps
/// straight into the questions. Generation is deterministic: the same unit
/// always yields the same quiz, so widget tests and replays are stable.
Lesson buildUnitQuiz(Unit unit) {
  final vocab = unit.vocab;

  // Deterministic pick helpers seeded by the unit id.
  int pick(int index, int modulus) {
    final base = (unit.id * 31 + index * 7);
    return base % modulus;
  }

  math.Random rng(int index) => math.Random(unit.id * 1000 + index);

  final questions = <LessonQuestion>[];

  // 1. English to Igbo, with distractors that are real unit words
  //    (harder than pulling distractors from thin air).
  {
    final correctIndex = pick(0, vocab.length);
    final correct = vocab[correctIndex];
    final distractors = <String>[];
    var offset = 1;
    while (distractors.length < 3) {
      final candidate = vocab[(correctIndex + offset) % vocab.length];
      if (candidate.igbo != correct.igbo &&
          !distractors.contains(candidate.igbo)) {
        distractors.add(candidate.igbo);
      }
      offset++;
    }
    final options = [correct.igbo, ...distractors]..shuffle(rng(1));
    questions.add(
      LessonQuestion(
        id: 'quiz_${unit.id}_q1',
        type: QuestionType.mcqEnglishToIgbo,
        prompt: 'What is the Igbo for "${correct.en}"?',
        options: options,
        answer: correct.igbo,
        acceptedAnswers: [correct.igbo],
      ),
    );
  }

  // 2. Igbo to English.
  {
    final correctIndex = pick(1, vocab.length);
    final correct = vocab[correctIndex];
    final distractors = <String>[];
    var offset = 1;
    while (distractors.length < 3) {
      final candidate = vocab[(correctIndex + offset) % vocab.length];
      if (candidate.en != correct.en && !distractors.contains(candidate.en)) {
        distractors.add(candidate.en);
      }
      offset++;
    }
    questions.add(
      LessonQuestion(
        id: 'quiz_${unit.id}_q2',
        type: QuestionType.mcqIgboToEnglish,
        prompt: 'What does "${correct.igbo}" mean?',
        options: [correct.en, ...distractors]..shuffle(rng(2)),
        answer: correct.en,
        acceptedAnswers: [correct.en],
      ),
    );
  }

  // 3. A five-option English to Igbo question: the harder variant.
  {
    final correctIndex = pick(2, vocab.length);
    final correct = vocab[correctIndex];
    final distractors = <String>[];
    var offset = 1;
    while (distractors.length < 4) {
      final candidate = vocab[(correctIndex + offset) % vocab.length];
      if (candidate.igbo != correct.igbo &&
          !distractors.contains(candidate.igbo)) {
        distractors.add(candidate.igbo);
      }
      offset++;
    }
    questions.add(
      LessonQuestion(
        id: 'quiz_${unit.id}_q3',
        type: QuestionType.mcqEnglishToIgbo,
        prompt: 'Which Igbo word means "${correct.en}"?',
        options: [correct.igbo, ...distractors]..shuffle(rng(3)),
        answer: correct.igbo,
        acceptedAnswers: [correct.igbo],
      ),
    );
  }

  // 4. Match pairs across the vocabulary.
  {
    final start = pick(3, vocab.length);
    final pairs = <MatchPair>[];
    for (var i = 0; i < 4; i++) {
      final entry = vocab[(start + i) % vocab.length];
      pairs.add(MatchPair(left: entry.igbo, right: entry.en));
    }
    questions.add(
      LessonQuestion(
        id: 'quiz_${unit.id}_q4',
        type: QuestionType.matchPairs,
        prompt: 'Match each Igbo word to its meaning',
        pairs: pairs,
      ),
    );
  }

  // 5. Fill the blank.
  {
    final correctIndex = pick(4, vocab.length);
    final correct = vocab[correctIndex];
    final distractors = <String>[];
    var offset = 1;
    while (distractors.length < 3) {
      final candidate = vocab[(correctIndex + offset) % vocab.length];
      if (candidate.igbo != correct.igbo &&
          !distractors.contains(candidate.igbo)) {
        distractors.add(candidate.igbo);
      }
      offset++;
    }
    questions.add(
      LessonQuestion(
        id: 'quiz_${unit.id}_q5',
        type: QuestionType.fillBlank,
        prompt: 'The Igbo word for "${correct.en}" is ___',
        wordBank: [correct.igbo, ...distractors]..shuffle(rng(5)),
        answer: correct.igbo,
        acceptedAnswers: [correct.igbo],
      ),
    );
  }

  // 6. Type the Igbo word.
  {
    final correctIndex = pick(5, vocab.length);
    final correct = vocab[correctIndex];
    questions.add(
      LessonQuestion(
        id: 'quiz_${unit.id}_q6',
        type: QuestionType.translate,
        prompt: 'Type the Igbo word for "${correct.en}"',
        acceptedAnswers: [correct.igbo, correct.igbo.toLowerCase()],
      ),
    );
  }

  return Lesson(
    id: 'unit_quiz_${unit.id}',
    title: 'Unit ${unit.id} Quiz',
    questions: questions,
    skipIntro: true,
  );
}
