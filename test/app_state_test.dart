import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/data/curriculum.dart';
import 'package:igboman/models/progress.dart';
import 'package:igboman/services/progress_service.dart';
import 'package:igboman/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppState Streak Rules', () {
    final day1 = DateTime.utc(2026, 9, 1, 10, 0);
    final day1Later = DateTime.utc(2026, 9, 1, 18, 0);
    final day2 = DateTime.utc(2026, 9, 2, 9, 0);
    final day3 = DateTime.utc(2026, 9, 3, 11, 0);
    final day4 = DateTime.utc(2026, 9, 4, 15, 0);

    test('initial lesson completion starts streak at 1', () async {
      final state = AppState();
      await state.completeLesson('u1l1', day1);

      expect(state.streakDays, 1);
      expect(state.xp, 30);
      expect(state.isLessonCompleted('u1l1'), isTrue);
    });

    test('same-day repeat leaves streak unchanged', () async {
      final state = AppState();
      await state.completeLesson('u1l1', day1);
      expect(state.streakDays, 1);

      await state.completeLesson('u1l2', day1Later);
      expect(state.streakDays, 1);
      expect(state.xp, 60);
    });

    test('consecutive day increments streak by 1', () async {
      final state = AppState();
      await state.completeLesson('u1l1', day1);
      expect(state.streakDays, 1);

      await state.completeLesson('u1l2', day2);
      expect(state.streakDays, 2);
    });

    test('one-day gap (grace day) increments streak by 1', () async {
      final state = AppState();
      await state.completeLesson('u1l1', day1);
      expect(state.streakDays, 1);

      // Skip day 2, complete on day 3
      await state.completeLesson('u1l2', day3);
      expect(state.streakDays, 2);
    });

    test('three-day gap resets streak to 1', () async {
      final state = AppState();
      await state.completeLesson('u1l1', day1);
      expect(state.streakDays, 1);

      // Skip day 2 and day 3, complete on day 4
      await state.completeLesson('u1l2', day4);
      expect(state.streakDays, 1);
    });
  });

  group('AppState Unit Unlock and Completion Rules', () {
    test('unit 1 is always unlocked', () {
      final state = AppState();
      expect(state.unitIsUnlocked(1), isTrue);
    });

    test('unit 2 is locked until all unit 1 lessons are completed', () async {
      final state = AppState();
      expect(state.unitIsUnlocked(2), isFalse);
      expect(state.unitFullyCompleted(1), isFalse);

      final unit1Lessons = unit01.lessons.map((l) => l.id).toList();

      // Complete all but the last lesson of unit 1
      for (var i = 0; i < unit1Lessons.length - 1; i++) {
        await state.completeLesson(unit1Lessons[i]);
        expect(state.unitIsUnlocked(2), isFalse);
        expect(state.unitFullyCompleted(1), isFalse);
      }

      // Complete the final lesson of unit 1
      await state.completeLesson(unit1Lessons.last);
      expect(state.unitIsUnlocked(2), isTrue);
      expect(state.unitFullyCompleted(1), isTrue);
      expect(state.unitIsUnlocked(3), isFalse);
    });

    test('unit 3 unlocks only when all unit 2 lessons are completed', () async {
      final state = AppState();
      final unit1Lessons = unit01.lessons.map((l) => l.id).toList();
      final unit2Lessons = unit02.lessons.map((l) => l.id).toList();

      for (final lessonId in unit1Lessons) {
        await state.completeLesson(lessonId);
      }
      expect(state.unitIsUnlocked(2), isTrue);
      expect(state.unitIsUnlocked(3), isFalse);

      for (var i = 0; i < unit2Lessons.length - 1; i++) {
        await state.completeLesson(unit2Lessons[i]);
        expect(state.unitIsUnlocked(3), isFalse);
      }

      await state.completeLesson(unit2Lessons.last);
      expect(state.unitIsUnlocked(3), isTrue);
      expect(state.unitFullyCompleted(2), isTrue);
    });
  });

  group('AppState Story Completion', () {
    test('completeStory marks the story done, bumps streak, awards no XP',
        () async {
      final day1 = DateTime.utc(2026, 9, 1, 10, 0);
      final state = AppState();
      var notifyCount = 0;
      state.addListener(() => notifyCount++);

      await state.completeStory('story_03', day1);

      expect(state.isStoryCompleted('story_03'), isTrue);
      expect(state.completedStoryIds, ['story_03']);
      expect(state.streakDays, 1);
      expect(state.xp, 0, reason: 'story completion itself awards no XP');
      expect(notifyCount, 1);

      final loaded = await const ProgressService().load();
      expect(loaded.completedStoryIds, ['story_03']);
    });

    test('completeStory follows the lesson streak rule and is idempotent',
        () async {
      final day1 = DateTime.utc(2026, 9, 1, 10, 0);
      final day1Later = DateTime.utc(2026, 9, 1, 18, 0);
      final day2 = DateTime.utc(2026, 9, 2, 9, 0);
      final state = AppState();

      await state.completeStory('story_03', day1);
      expect(state.streakDays, 1);

      // same-day second story leaves streak unchanged
      await state.completeStory('story_04', day1Later);
      expect(state.streakDays, 1);

      // next day increments streak
      await state.completeStory('story_05', day2);
      expect(state.streakDays, 2);

      // replaying does not duplicate the id
      await state.completeStory('story_05', day2);
      expect(state.completedStoryIds, ['story_03', 'story_04', 'story_05']);
      expect(state.streakDays, 2);
    });

    test('isStoryCompleted is false for unknown stories', () {
      final state = AppState();
      expect(state.isStoryCompleted('story_03'), isFalse);
      expect(state.completedStoryIds, isEmpty);
    });
  });

  group('AppState XP and Notifications', () {
    test('awardXp increments xp, notifies listeners, and persists', () async {
      final state = AppState();
      var notifyCount = 0;
      state.addListener(() {
        notifyCount++;
      });

      await state.awardXp(50);
      expect(state.xp, 50);
      expect(notifyCount, 1);

      await state.awardXp(25);
      expect(state.xp, 75);
      expect(notifyCount, 2);

      final loaded = await const ProgressService().load();
      expect(loaded.xp, 75);
    });

    test('completeLesson notifies listeners and persists', () async {
      final state = AppState();
      var notifyCount = 0;
      state.addListener(() {
        notifyCount++;
      });

      await state.completeLesson('u1l1');
      expect(state.xp, 30);
      expect(state.isLessonCompleted('u1l1'), isTrue);
      expect(notifyCount, 1);

      final loaded = await const ProgressService().load();
      expect(loaded.xp, 30);
      expect(loaded.completedLessonIds, ['u1l1']);
    });
  });

  group('AppState Injection and Setters', () {
    test('can initialize AppState with injected ProgressData', () {
      const initial = ProgressData(
        xp: 200,
        streakDays: 7,
        completedLessonIds: ['u1l1', 'u1l2'],
      );
      final state = AppState(initial: initial);

      expect(state.xp, 200);
      expect(state.streakDays, 7);
      expect(state.completedLessonIds, ['u1l1', 'u1l2']);
      expect(state.isLessonCompleted('u1l1'), isTrue);
      expect(state.isLessonCompleted('u1l3'), isFalse);
    });

    test('setters update state and notify listeners', () {
      final state = AppState();
      var notifyCount = 0;
      state.addListener(() {
        notifyCount++;
      });

      state.xp = 100;
      expect(state.xp, 100);
      expect(notifyCount, 1);

      state.streakDays = 5;
      expect(state.streakDays, 5);
      expect(notifyCount, 2);
    });
  });
}
