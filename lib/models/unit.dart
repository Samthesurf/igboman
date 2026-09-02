import 'lesson.dart';

class VocabEntry {
  final String igbo;
  final String en;

  const VocabEntry({
    required this.igbo,
    required this.en,
  });
}

class Unit {
  final int id;
  final String titleIgbo;
  final String titleEn;
  final List<Lesson> lessons;
  final List<VocabEntry> vocab;

  const Unit({
    required this.id,
    required this.titleIgbo,
    required this.titleEn,
    required this.lessons,
    required this.vocab,
  });
}
