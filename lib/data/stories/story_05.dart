import '../../models/lesson.dart';
import '../../models/story.dart';
import '../../models/unit.dart';

/// Story 5 (unit 5, possessives): whose cloth is it?
const Story story05 = Story(
  id: 'story_05',
  unitId: 5,
  titleEn: 'Whose Is It?',
  titleIgbo: 'Nke M',
  sentences: [
    'Ada: Ákwà a bụ nke m.',
    'Obi: Mba! Ọ bụ nke m.',
    'Ada: Ee, ọ bụ nke anyị.',
    'Obi: Nke gị dị mma, daalụ.',
    'Ada: Nke unu dị mma.',
    'Obi: Nke ha bụ ákwà?',
    'Ada: Ee, enyi m, nke ha bụ ákwà.',
  ],
  newWords: [
    VocabEntry(igbo: 'enyi', en: 'friend'),
  ],
  questions: [
    LessonQuestion(
      id: 'story05q1',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'What does "nke m" mean?',
      options: ['mine', 'yours', 'his', 'ours'],
      answer: 'mine',
      acceptedAnswers: ['mine'],
    ),
    LessonQuestion(
      id: 'story05q2',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'What does "nke anyị" mean?',
      options: ['ours', 'mine', 'theirs', 'yours'],
      answer: 'ours',
      acceptedAnswers: ['ours'],
    ),
    LessonQuestion(
      id: 'story05q3',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'The new word "enyi" means what?',
      options: ['friend', 'cloth', 'mother', 'market'],
      answer: 'friend',
      acceptedAnswers: ['friend'],
    ),
  ],
);
