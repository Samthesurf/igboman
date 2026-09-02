import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/models/progress.dart';
import 'package:igboman/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ProgressData Model', () {
    test('default constructor provides default values', () {
      const progress = ProgressData();

      expect(progress.schemaVersion, 1);
      expect(progress.xp, 0);
      expect(progress.streakDays, 0);
      expect(progress.lastActiveDay, isNull);
      expect(progress.completedLessonIds, isEmpty);
    });

    test('toJson and fromJson round trip successfully', () {
      final now = DateTime.utc(2026, 9, 2, 12, 0, 0);
      final progress = ProgressData(
        schemaVersion: 1,
        xp: 150,
        streakDays: 4,
        lastActiveDay: now,
        completedLessonIds: const ['u1l1', 'u1l2'],
      );

      final json = progress.toJson();
      final reconstructed = ProgressData.fromJson(json);

      expect(reconstructed.schemaVersion, 1);
      expect(reconstructed.xp, 150);
      expect(reconstructed.streakDays, 4);
      expect(reconstructed.lastActiveDay, now);
      expect(reconstructed.completedLessonIds, ['u1l1', 'u1l2']);
      expect(reconstructed, progress);
    });

    test('fromJson is tolerant to null, missing, extra, and corrupted fields', () {
      expect(ProgressData.fromJson(null), const ProgressData());

      final missing = ProgressData.fromJson(const {});
      expect(missing.schemaVersion, 1);
      expect(missing.xp, 0);
      expect(missing.streakDays, 0);
      expect(missing.lastActiveDay, isNull);
      expect(missing.completedLessonIds, isEmpty);

      final corrupted = ProgressData.fromJson(const {
        'schemaVersion': 'invalid',
        'xp': 'invalid',
        'streakDays': null,
        'lastActiveDay': 'not-a-date',
        'completedLessonIds': 12345,
        'extraUnknownField': 'should be ignored',
      });
      expect(corrupted.schemaVersion, 1);
      expect(corrupted.xp, 0);
      expect(corrupted.streakDays, 0);
      expect(corrupted.lastActiveDay, isNull);
      expect(corrupted.completedLessonIds, isEmpty);
    });

    test('copyWith creates modified copy', () {
      const initial = ProgressData(xp: 10, streakDays: 2);
      final updated = initial.copyWith(xp: 50);

      expect(updated.xp, 50);
      expect(updated.streakDays, 2);
    });
  });

  group('calculateStreak logic', () {
    final today = DateTime.utc(2026, 9, 2, 10, 30);
    final yesterday = DateTime.utc(2026, 9, 1, 14, 0);
    final twoDaysAgo = DateTime.utc(2026, 8, 31, 9, 0);
    final threeDaysAgo = DateTime.utc(2026, 8, 30, 20, 0);
    final fourDaysAgo = DateTime.utc(2026, 8, 29, 8, 0);

    test('no history (lastActiveDay is null) sets streak to 1', () {
      final streak = calculateStreak(
        currentStreak: 0,
        lastActiveDay: null,
        now: today,
      );
      expect(streak, 1);
    });

    test('same-day repeat leaves streak unchanged', () {
      final sameDayEarlier = DateTime.utc(2026, 9, 2, 6, 0);
      final streak = calculateStreak(
        currentStreak: 5,
        lastActiveDay: sameDayEarlier,
        now: today,
      );
      expect(streak, 5);
    });

    test('consecutive day increments streak by 1', () {
      final streak = calculateStreak(
        currentStreak: 3,
        lastActiveDay: yesterday,
        now: today,
      );
      expect(streak, 4);
    });

    test('one-day gap (grace day, two days ago) increments streak by 1', () {
      final streak = calculateStreak(
        currentStreak: 3,
        lastActiveDay: twoDaysAgo,
        now: today,
      );
      expect(streak, 4);
    });

    test('three-day gap resets streak to 1', () {
      final streak = calculateStreak(
        currentStreak: 10,
        lastActiveDay: threeDaysAgo,
        now: today,
      );
      expect(streak, 1);
    });

    test('four-day or larger gap resets streak to 1', () {
      final streak = calculateStreak(
        currentStreak: 10,
        lastActiveDay: fourDaysAgo,
        now: today,
      );
      expect(streak, 1);
    });
  });

  group('ProgressService Persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('load returns fresh defaults when absent', () async {
      final service = const ProgressService();
      final progress = await service.load();

      expect(progress.schemaVersion, 1);
      expect(progress.xp, 0);
      expect(progress.streakDays, 0);
      expect(progress.lastActiveDay, isNull);
      expect(progress.completedLessonIds, isEmpty);
    });

    test('save and load persistence round-trip with igboman_progress_v1 key', () async {
      final service = const ProgressService();
      final now = DateTime.utc(2026, 9, 2, 10, 0);
      final data = ProgressData(
        schemaVersion: 1,
        xp: 90,
        streakDays: 3,
        lastActiveDay: now,
        completedLessonIds: const ['u1l1', 'u1l2', 'u1l3'],
      );

      await service.save(data);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(ProgressService.storageKey), isTrue);
      expect(prefs.getString(ProgressService.storageKey), jsonEncode(data.toJson()));

      final loaded = await service.load();
      expect(loaded.xp, 90);
      expect(loaded.streakDays, 3);
      expect(loaded.lastActiveDay, now);
      expect(loaded.completedLessonIds, ['u1l1', 'u1l2', 'u1l3']);
    });

    test('corrupted JSON returns defaults and is overwritten on next save', () async {
      SharedPreferences.setMockInitialValues({
        ProgressService.storageKey: '{broken json string',
      });

      final service = const ProgressService();
      final loadedCorrupted = await service.load();

      expect(loadedCorrupted.xp, 0);
      expect(loadedCorrupted.streakDays, 0);
      expect(loadedCorrupted.completedLessonIds, isEmpty);

      final freshData = const ProgressData(
        xp: 60,
        streakDays: 2,
        completedLessonIds: ['u1l1'],
      );
      await service.save(freshData);

      final reloaded = await service.load();
      expect(reloaded.xp, 60);
      expect(reloaded.streakDays, 2);
      expect(reloaded.completedLessonIds, ['u1l1']);
    });

    test('non-map JSON payload returns default without crashing', () async {
      SharedPreferences.setMockInitialValues({
        ProgressService.storageKey: '12345',
      });

      final service = const ProgressService();
      final loaded = await service.load();
      expect(loaded, const ProgressData());
    });
  });
}
