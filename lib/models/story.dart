import 'lesson.dart';
import 'unit.dart';

/// A graded Igbo reader: a short story tied to a curriculum unit.
///
/// Each story is gated to the vocabulary of its unit and earlier units.
/// [newWords] introduces a small set (1-5) of new words that are glossed
/// for the reader. [questions] are English comprehension questions checked
/// after reading.
class Story {
  final String id;
  final int unitId;
  final String titleEn;
  final String titleIgbo;
  final List<String> sentences;
  final List<VocabEntry> newWords;
  final List<LessonQuestion> questions;

  const Story({
    required this.id,
    required this.unitId,
    required this.titleEn,
    required this.titleIgbo,
    required this.sentences,
    required this.newWords,
    required this.questions,
  });
}
