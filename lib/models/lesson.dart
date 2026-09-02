enum QuestionType {
  mcqIgboToEnglish,
  mcqEnglishToIgbo,
  matchPairs,
  fillBlank,
  translate,
}

class MatchPair {
  final String left;
  final String right;

  const MatchPair({required this.left, required this.right});
}

class LessonQuestion {
  final String id;
  final QuestionType type;
  final String prompt;
  final List<String> options;
  final String? answer;
  final List<String> acceptedAnswers;
  final List<MatchPair> pairs;
  final List<String> wordBank;
  final bool toneLenient;

  const LessonQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    this.options = const [],
    this.answer,
    this.acceptedAnswers = const [],
    this.pairs = const [],
    this.wordBank = const [],
    this.toneLenient = false,
  });
}

class Lesson {
  final String id;
  final String title;
  final List<LessonQuestion> questions;

  /// When true the lesson is an assessment (e.g. a unit quiz) and starts
  /// directly on the questions, skipping the teach phase.
  final bool skipIntro;

  const Lesson({
    required this.id,
    required this.title,
    required this.questions,
    this.skipIntro = false,
  });
}
