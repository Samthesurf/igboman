import '../../models/lesson.dart';
import '../../models/story.dart';
import '../../models/unit.dart';

/// Story 8 (unit 8, market): a market-day slice of family life.
const Story story08 = Story(
  id: 'story_08',
  unitId: 8,
  titleEn: 'Market Day',
  titleIgbo: 'Ụbọchị Ahịa',
  sentences: [
    'Nna m na-aga ahịa.',
    'Ada na Obi na-abịa ebe a.',
    'Ha zụọ nri.',
    'Nri dị mma.',
    'Ahịa dị mma.',
    'Kedu ka ị mere, Nna m?',
    'Ọ dị mma, daalụ!',
  ],
  newWords: [
    VocabEntry(igbo: 'zụọ', en: 'buy'),
  ],
  questions: [
    LessonQuestion(
      id: 'story08q1',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'Where is Nna going?',
      options: ['market', 'home', 'school', 'farm'],
      answer: 'market',
      acceptedAnswers: ['market'],
    ),
    LessonQuestion(
      id: 'story08q2',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'What do Ada and Obi do at the market?',
      options: ['buy food', 'see water', 'go home', 'count cloth'],
      answer: 'buy food',
      acceptedAnswers: ['buy food'],
    ),
    LessonQuestion(
      id: 'story08q3',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'The new word "zụọ" means what?',
      options: ['buy', 'eat', 'see', 'go'],
      answer: 'buy',
      acceptedAnswers: ['buy'],
    ),
  ],
);
