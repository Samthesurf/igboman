import '../../models/lesson.dart';
import '../../models/story.dart';
import '../../models/unit.dart';

/// Story 3 (unit 3, greetings): Ada and Obi greet each other.
const Story story03 = Story(
  id: 'story_03',
  unitId: 3,
  titleEn: 'Morning Greetings',
  titleIgbo: 'Ekele Ụtụtụ',
  sentences: [
    'Ada: Ndewo, Obi!',
    'Obi: Ndewo, Ada! Aha m bụ Obi.',
    'Ada: Ụtụtụ ọma! Kedu ka ị mere?',
    'Obi: Ọ dị mma, daalụ. Ị nọ nke ọma?',
    'Ada: Ee, m dị mma, daalụ.',
    'Obi: Ka ọ dị! Ehihie ọma!',
    'Ada: Ka ọ dị! Abalị ọma!',
  ],
  newWords: [
    VocabEntry(igbo: 'aha', en: 'name'),
  ],
  questions: [
    LessonQuestion(
      id: 'story03q1',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'What does Ada say to greet Obi first?',
      options: ['Hello', 'Goodbye', 'Thank you', 'Please'],
      answer: 'Hello',
      acceptedAnswers: ['Hello'],
    ),
    LessonQuestion(
      id: 'story03q2',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'How does Obi answer when Ada asks how he is?',
      options: ['It is fine', 'Good morning', 'Good night', 'Goodbye'],
      answer: 'It is fine',
      acceptedAnswers: ['It is fine'],
    ),
    LessonQuestion(
      id: 'story03q3',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'The new word "aha" means what?',
      options: ['name', 'morning', 'house', 'water'],
      answer: 'name',
      acceptedAnswers: ['name'],
    ),
  ],
);
