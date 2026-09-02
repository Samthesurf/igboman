import '../../models/lesson.dart';
import '../../models/story.dart';
import '../../models/unit.dart';

/// Story 4 (unit 4, numbers): Ada and Obi count together.
const Story story04 = Story(
  id: 'story_04',
  unitId: 4,
  titleEn: 'Counting with Obi',
  titleIgbo: 'Ịgụ Ọnụ',
  sentences: [
    'Ada: Obi, gụọ otu, abụọ, atọ!',
    'Obi: Mụ, anọ, ise, isii!',
    'Ada: Ọ bụ isii?',
    'Obi: Mba, ọ bụ asaa!',
    'Ada: Ee, asaa! Nke a bụ iri?',
    'Obi: Mba! Ọ bụ iri abụọ.',
    'Ada: Daalụ, Obi! Mụ dị mma.',
  ],
  newWords: [
    VocabEntry(igbo: 'gụọ', en: 'count'),
  ],
  questions: [
    LessonQuestion(
      id: 'story04q1',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'How many is "abụọ"?',
      options: ['Two', 'Three', 'Four', 'Five'],
      answer: 'Two',
      acceptedAnswers: ['Two'],
    ),
    LessonQuestion(
      id: 'story04q2',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'What does "isii" mean?',
      options: ['Six', 'Seven', 'Five', 'Eight'],
      answer: 'Six',
      acceptedAnswers: ['Six'],
    ),
    LessonQuestion(
      id: 'story04q3',
      type: QuestionType.mcqEnglishToIgbo,
      prompt: 'What does "iri abụọ" mean?',
      options: ['Twenty', 'Twelve', 'Two', 'Eleven'],
      answer: 'Twenty',
      acceptedAnswers: ['Twenty'],
    ),
  ],
);
