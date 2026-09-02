import '../data/curriculum.dart';
import '../models/lesson.dart';
import '../models/unit.dart';

/// A word (or letter) with its English gloss, shown in the teach phase.
class LessonIntroWord {
  final String igbo;
  final String en;

  const LessonIntroWord({required this.igbo, required this.en});
}

/// An Igbo example with its English translation, shown in the teach phase.
class LessonIntroExample {
  final String igbo;
  final String en;

  const LessonIntroExample({required this.igbo, required this.en});
}

/// The teach phase of a lesson: what to study before the exercise round.
class LessonIntro {
  final List<LessonIntroWord> words;
  final List<LessonIntroExample> examples;

  const LessonIntro({required this.words, required this.examples});
}

/// Derives the teach phase for a lesson from content that is already
/// authored, so every lesson gets an introduction without hand-writing 45
/// extra lesson files.
///
/// Words: unit vocab entries that actually appear in the lesson's question
/// text (matched as standalone tokens). Examples: translate questions first
/// (real sentences), falling back to match pair definitions.
LessonIntro buildLessonIntro(Unit unit, Lesson lesson) {
  final questionText = <String>[];
  final examples = <LessonIntroExample>[];

  for (final question in lesson.questions) {
    questionText
      ..add(question.prompt)
      ..addAll(question.options)
      ..addAll(question.acceptedAnswers)
      ..addAll(question.wordBank);
    if (question.answer != null) questionText.add(question.answer!);

    switch (question.type) {
      case QuestionType.translate:
        final translation = question.acceptedAnswers.isNotEmpty
            ? question.acceptedAnswers.first
            : question.answer;
        if (translation != null && translation.isNotEmpty) {
          examples.add(
            LessonIntroExample(igbo: question.prompt, en: translation),
          );
        }
      case QuestionType.matchPairs:
        for (final pair in question.pairs) {
          if (pair.left.isNotEmpty && pair.right.isNotEmpty) {
            examples.add(LessonIntroExample(igbo: pair.left, en: pair.right));
          }
        }
      case QuestionType.mcqIgboToEnglish:
      case QuestionType.mcqEnglishToIgbo:
      case QuestionType.fillBlank:
        break;
    }
  }

  final pooled = questionText.join('\n');

  final matched = <LessonIntroWord>[];
  final seen = <String>{};
  for (final entry in unit.vocab) {
    if (matched.length >= 6) break;
    final key = entry.igbo.trim().toLowerCase();
    if (key.isEmpty || seen.contains(key)) continue;
    if (_containsToken(pooled, key)) {
      seen.add(key);
      matched.add(LessonIntroWord(igbo: entry.igbo, en: entry.en));
    }
  }

  // Fallback: no vocab words surfaced in the question text, so teach the
  // unit's own vocabulary.
  if (matched.isEmpty) {
    for (final entry in unit.vocab) {
      if (matched.length >= 4) break;
      final key = entry.igbo.trim().toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        matched.add(LessonIntroWord(igbo: entry.igbo, en: entry.en));
      }
    }
  }

  return LessonIntro(
    words: matched,
    examples: examples.take(4).toList(growable: false),
  );
}

/// Resolves the unit that owns a lesson (ids look like `u3l2`), or null
/// for ids outside the curriculum (unit quizzes, lesson runners used
/// directly in tests).
Unit? unitForLesson(String lessonId) {
  final match = RegExp(r'^u(\d+)l').firstMatch(lessonId);
  if (match == null) return null;
  final unitId = int.parse(match.group(1)!);
  for (final unit in curriculum) {
    if (unit.id == unitId) return unit;
  }
  return null;
}

/// Convenience for the lesson runner: resolves the owning unit and derives
/// the teach phase.
LessonIntro buildLessonIntroForLesson(Lesson lesson) {
  final unit = unitForLesson(lesson.id);
  if (unit == null) {
    return const LessonIntro(words: [], examples: []);
  }
  return buildLessonIntro(unit, lesson);
}

/// True when [needle] appears in [haystack] as a standalone token (Igbo
/// letters like `a` must not match inside other words).
bool _containsToken(String haystack, String needle) {
  if (needle.contains(' ')) {
    return haystack.toLowerCase().contains(needle);
  }
  final pattern = RegExp(
    '(^|[^\\p{L}\\p{N}])${RegExp.escape(needle)}'
    r'([^\p{L}\p{N}]|$)',
    unicode: true,
    caseSensitive: false,
  );
  return pattern.hasMatch(haystack);
}
