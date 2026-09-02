import '../../models/lesson.dart';
import '../../models/story.dart';
import '../../models/unit.dart';

/// Story 9 (unit 9, home and food): Mbe goes to the sky for a feast.
/// A simple original retelling inspired by the classic tale of Mbe and the
/// feast in heaven.
const Story story09 = Story(
  id: 'story_09',
  unitId: 9,
  titleEn: 'Mbe in the Sky',
  titleIgbo: "Mbe n'Elu",
  sentences: [
    'Mbe gaa elu.',
    "Mbe hụ nri n'elu.",
    'Nri dị mma, daalụ.',
    'Mbe rie nri.',
    'Mbe ṅụọ mmiri.',
    'Mbe bịa ụlọ.',
    'Ụlọ ahụ dị mma.',
  ],
  newWords: [
    VocabEntry(igbo: 'elu', en: 'sky'),
  ],
  questions: [
    LessonQuestion(
      id: 'story09q1',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'Where does Mbe go first?',
      options: ['to the sky', 'to the market', 'to the house', 'to the farm'],
      answer: 'to the sky',
      acceptedAnswers: ['to the sky'],
    ),
    LessonQuestion(
      id: 'story09q2',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'What does Mbe do after eating?',
      options: ['drinks water', 'goes to market', 'sleeps', 'counts'],
      answer: 'drinks water',
      acceptedAnswers: ['drinks water'],
    ),
    LessonQuestion(
      id: 'story09q3',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'What is "ụlọ"?',
      options: ['house', 'water', 'food', 'market'],
      answer: 'house',
      acceptedAnswers: ['house'],
    ),
  ],
);
