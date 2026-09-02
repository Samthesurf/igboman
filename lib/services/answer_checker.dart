import 'package:flutter/foundation.dart';

/// Result of checking a user answer against accepted answers.
@immutable
class AnswerCheckResult {
  final bool correct;
  final bool toneNote;

  const AnswerCheckResult({
    required this.correct,
    this.toneNote = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnswerCheckResult &&
          runtimeType == other.runtimeType &&
          correct == other.correct &&
          toneNote == other.toneNote;

  @override
  int get hashCode => Object.hash(correct, toneNote);

  @override
  String toString() =>
      'AnswerCheckResult(correct: $correct, toneNote: $toneNote)';
}

/// Service for checking and validating Igbo and English answers.
abstract final class AnswerChecker {
  /// Normalizes user input and accepted answers:
  /// - trims whitespace
  /// - collapses consecutive whitespace into a single space
  /// - converts to lowercase (case-insensitive)
  /// - normalizes decomposed underdot/dot characters to precomposed
  /// - strips leading and trailing punctuation
  static String normalize(String input) {
    var s = input.trim().toLowerCase();

    // Normalize decomposed combining underdots and dots to precomposed forms
    s = s
        .replaceAll('i\u0323', '\u1ecb')
        .replaceAll('o\u0323', '\u1ecd')
        .replaceAll('u\u0323', '\u1ef5')
        .replaceAll('n\u0307', '\u1e45');

    // Collapse consecutive whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ');

    // Strip surrounding punctuation
    s = s.replaceAll(
      RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true),
      '',
    );

    return s;
  }

  /// Strips acute and grave tone marks while preserving underdots and ṅ.
  /// Underdot characters (ị, ọ, ụ) and ṅ are distinct alphabet letters and are NEVER stripped.
  static String stripToneMarks(String input) {
    var s = normalize(input);

    const precomposedToneMap = {
      'á': 'a',
      'à': 'a',
      'é': 'e',
      'è': 'e',
      'í': 'i',
      'ì': 'i',
      'ó': 'o',
      'ò': 'o',
      'ú': 'u',
      'ù': 'u',
      'ń': 'n',
      'ǹ': 'n',
      'ḿ': 'm',
    };

    precomposedToneMap.forEach((k, v) {
      s = s.replaceAll(k, v);
    });

    // Remove combining acute, grave, macron, caron, and circumflex tone marks
    s = s.replaceAll(
      RegExp(r'[\u0300\u0301\u0302\u0304\u030C\u030B\u030D]'),
      '',
    );

    return s;
  }

  /// Checks [userInput] against [acceptedAnswers].
  ///
  /// - [toneLenient] = false: exact match after normalization; diacritics and tone marks significant.
  /// - [toneLenient] = true: additionally ignores acute/grave tone marks before comparing.
  ///
  /// Returns [AnswerCheckResult] where [toneNote] is true if the answer was only
  /// wrong due to tone marks under lenient mode (soft pass with reduced XP).
  /// Underdot errors are NEVER lenient.
  static AnswerCheckResult check({
    required String userInput,
    required List<String> acceptedAnswers,
    bool toneLenient = false,
  }) {
    final userNorm = normalize(userInput);
    final acceptedNorms = acceptedAnswers.map(normalize).toList();

    if (userNorm.isEmpty &&
        acceptedNorms.isNotEmpty &&
        acceptedNorms.every((a) => a.isNotEmpty)) {
      return const AnswerCheckResult(correct: false, toneNote: false);
    }

    // 1. Exact match after normalization
    if (acceptedNorms.contains(userNorm)) {
      return const AnswerCheckResult(correct: true, toneNote: false);
    }

    // 2. Tone mark comparison
    final userToneStripped = stripToneMarks(userNorm);
    final acceptedToneStripped = acceptedNorms.map(stripToneMarks).toList();

    if (acceptedToneStripped.contains(userToneStripped)) {
      if (toneLenient) {
        // Soft pass: answer letters and underdots are correct, only tone marks differed/omitted
        return const AnswerCheckResult(correct: true, toneNote: true);
      } else {
        // Tone marks are required strictly for this question
        return const AnswerCheckResult(correct: false, toneNote: false);
      }
    }

    // 3. Underdot error or wrong letters/words
    return const AnswerCheckResult(correct: false, toneNote: false);
  }
}

/// Helper function to check answers directly.
AnswerCheckResult checkAnswer({
  required String userInput,
  required List<String> acceptedAnswers,
  bool toneLenient = false,
}) {
  return AnswerChecker.check(
    userInput: userInput,
    acceptedAnswers: acceptedAnswers,
    toneLenient: toneLenient,
  );
}
