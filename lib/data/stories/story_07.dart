import '../../models/lesson.dart';
import '../../models/story.dart';
import '../../models/unit.dart';

/// Story 7 (unit 7, action verbs): Mbe on the road.
const Story story07 = Story(
  id: 'story_07',
  unitId: 7,
  titleEn: 'Mbe on the Road',
  titleIgbo: 'Mbe na Ụzọ',
  sentences: [
    'Ada na Obi bịa ebe a.',
    'Mbe hụ ha.',
    'Mbe gaa ụzọ.',
    'Ada na Obi rie nri.',
    'Ha ṅụọ mmiri.',
    'Mbe bịa, hụ nri.',
    'Ha mee nke ọma, daalụ.',
  ],
  newWords: [
    VocabEntry(igbo: 'ụzọ', en: 'road'),
    VocabEntry(igbo: 'nri', en: 'food'),
    VocabEntry(igbo: 'mmiri', en: 'water'),
  ],
  questions: [
    LessonQuestion(
      id: 'story07q1',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'What does "gaa" mean?',
      options: ['go', 'come', 'eat', 'see'],
      answer: 'go',
      acceptedAnswers: ['go'],
    ),
    LessonQuestion(
      id: 'story07q2',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'What does "rie" mean?',
      options: ['eat', 'drink', 'do', 'go'],
      answer: 'eat',
      acceptedAnswers: ['eat'],
    ),
    LessonQuestion(
      id: 'story07q3',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'The new word "mmiri" means what?',
      options: ['water', 'food', 'road', 'house'],
      answer: 'water',
      acceptedAnswers: ['water'],
    ),
  ],
);
