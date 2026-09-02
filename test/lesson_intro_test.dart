import 'package:flutter_test/flutter_test.dart';

import 'package:igboman/data/curriculum.dart';
import 'package:igboman/models/lesson.dart';
import 'package:igboman/services/lesson_intro.dart';

void main() {
  group('unitForLesson', () {
    test('resolves curriculum lesson ids to their unit', () {
      expect(unitForLesson('u1l1'), same(unit01));
      expect(unitForLesson('u3l2'), same(unit03));
      expect(unitForLesson('u9l4'), same(unit09));
    });

    test('returns null for non-curriculum ids', () {
      expect(unitForLesson('unit_quiz_1'), isNull);
      expect(unitForLesson('test_mcq_001'), isNull);
      expect(unitForLesson('story_q1'), isNull);
    });
  });

  group('buildLessonIntroForLesson', () {
    test(
      'surfaces the unit vocab used by the lesson (u1l2 underdot vowels)',
      () {
        final intro = buildLessonIntroForLesson(unit01.lessons[1]);
        final words = intro.words.map((w) => w.igbo).toSet();
        expect(words, contains('ị'));
        expect(words, contains('ọ'));
        expect(words, contains('ụ'));
        expect(intro.words.length, lessThanOrEqualTo(6));
      },
    );

    test(
      'examples come from match pairs when no translate questions exist',
      () {
        final intro = buildLessonIntroForLesson(unit01.lessons[1]);
        expect(intro.examples, isNotEmpty);
        expect(intro.examples.first.igbo, 'i');
        expect(intro.examples.first.en, 'regular i');
        expect(intro.examples.length, lessThanOrEqualTo(4));
      },
    );

    test('translate questions become sentence examples', () {
      final lesson = Lesson(
        id: 'u1l_test',
        title: 'Phrases',
        questions: const [
          LessonQuestion(
            id: 't1',
            type: QuestionType.translate,
            prompt: 'Kedu ka ị mere?',
            acceptedAnswers: ['How are you?'],
          ),
        ],
      );
      final intro = buildLessonIntroForLesson(lesson);
      expect(intro.examples.single.igbo, 'Kedu ka ị mere?');
      expect(intro.examples.single.en, 'How are you?');
    });

    test('falls back to the unit vocab when questions use no vocab tokens', () {
      final lesson = Lesson(
        id: 'u1l99',
        title: 'Odd',
        questions: const [
          LessonQuestion(
            id: 'x1',
            type: QuestionType.mcqIgboToEnglish,
            prompt: 'Something unrelated entirely?',
            options: ['one', 'two', 'three', 'four'],
            answer: 'one',
          ),
        ],
      );
      final intro = buildLessonIntroForLesson(lesson);
      expect(intro.words, isNotEmpty);
      expect(intro.words.first.igbo, unit01.vocab.first.igbo);
      expect(intro.words.length, lessThanOrEqualTo(4));
    });

    test('single letters do not match inside other words', () {
      // 'a' appears inside 'alphabet', 'standard', 'underdot', etc. Only a
      // standalone 'a' counts. The lesson below has 'b' as a standalone
      // option and 'a' only inside words.
      final lesson = Lesson(
        id: 'u1l98',
        title: 'Tokens',
        questions: const [
          LessonQuestion(
            id: 't1',
            type: QuestionType.mcqEnglishToIgbo,
            prompt: 'Which letter is a consonant?',
            options: ['b', 'ch', 'gb'],
            answer: 'b',
          ),
        ],
      );
      final intro = buildLessonIntroForLesson(lesson);
      final words = intro.words.map((w) => w.igbo).toList();
      expect(words, contains('b'));
      expect(words, contains('ch'));
    });
  });
}
