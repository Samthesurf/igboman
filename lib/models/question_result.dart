/// One answered question, kept for the end-of-lesson review screen.
class QuestionResult {
  /// The question prompt as shown during the lesson.
  final String prompt;

  /// What the learner answered, in display form.
  final String userAnswer;

  /// The accepted answer, in display form.
  final String correctAnswer;

  /// True when the learner got it right (tone notes still count).
  final bool isCorrect;

  const QuestionResult({
    required this.prompt,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });
}
