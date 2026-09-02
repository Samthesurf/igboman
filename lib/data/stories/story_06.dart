import '../../models/lesson.dart';
import '../../models/story.dart';
import '../../models/unit.dart';

/// Story 6 (unit 6, family): Ada and Obi's family.
const Story story06 = Story(
  id: 'story_06',
  unitId: 6,
  titleEn: "Ada's Family",
  titleIgbo: 'Ezinụlọ Ada',
  sentences: [
    'Ada bụ nwa nwanyị.',
    'Obi bụ nwoke, ọkpara.',
    'Nna Ada bụ nwoke; nne Ada bụ nwanyị.',
    'Ụmụaka abụọ bụ Ada na Obi.',
    'Ha bụ nwanne.',
    'Ezinụlọ a dị mma.',
    'Nne na nna ha dị mma.',
  ],
  newWords: [
    VocabEntry(igbo: 'ezinụlọ', en: 'family'),
  ],
  questions: [
    LessonQuestion(
      id: 'story06q1',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'Who is "nne"?',
      options: ['mother', 'father', 'child', 'sibling'],
      answer: 'mother',
      acceptedAnswers: ['mother'],
    ),
    LessonQuestion(
      id: 'story06q2',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'What does "ụmụaka" mean?',
      options: ['children', 'parents', 'siblings', 'woman'],
      answer: 'children',
      acceptedAnswers: ['children'],
    ),
    LessonQuestion(
      id: 'story06q3',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'The new word "ezinụlọ" means what?',
      options: ['family', 'market', 'house', 'friend'],
      answer: 'family',
      acceptedAnswers: ['family'],
    ),
  ],
);
