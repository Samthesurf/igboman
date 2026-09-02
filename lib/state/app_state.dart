import 'package:flutter/foundation.dart';
import '../data/curriculum.dart';
import '../models/progress.dart';
import '../services/progress_service.dart';

/// App state managing user progress, XP, streaks, and unit unlocks.
class AppState extends ChangeNotifier {
  ProgressData _progress;
  final ProgressService _service;

  AppState({
    ProgressData initial = const ProgressData(),
    ProgressService? progressService,
  })  : _progress = initial,
        _service = progressService ?? const ProgressService();

  ProgressData get progress => _progress;

  int get xp => _progress.xp;
  set xp(int value) {
    if (_progress.xp != value) {
      _progress = _progress.copyWith(xp: value);
      notifyListeners();
      _service.save(_progress);
    }
  }

  int get streakDays => _progress.streakDays;
  set streakDays(int value) {
    if (_progress.streakDays != value) {
      _progress = _progress.copyWith(streakDays: value);
      notifyListeners();
      _service.save(_progress);
    }
  }

  List<String> get completedLessonIds => _progress.completedLessonIds;

  /// Returns true if the lesson with [lessonId] has been completed.
  bool isLessonCompleted(String lessonId) {
    return _progress.completedLessonIds.contains(lessonId);
  }

  /// Unit 1 is always unlocked.
  /// Unit N is unlocked when every lesson of unit N-1 is completed.
  bool unitIsUnlocked(int unitId) {
    if (unitId <= 1) {
      return true;
    }
    try {
      final prevUnit = unitById(unitId - 1);
      if (prevUnit.lessons.isEmpty) {
        return false;
      }
      return prevUnit.lessons.every((lesson) => isLessonCompleted(lesson.id));
    } catch (_) {
      return false;
    }
  }

  /// Returns true if all lessons of unit [unitId] are completed.
  bool unitFullyCompleted(int unitId) {
    try {
      final unit = unitById(unitId);
      if (unit.lessons.isEmpty) {
        return false;
      }
      return unit.lessons.every((lesson) => isLessonCompleted(lesson.id));
    } catch (_) {
      return false;
    }
  }

  /// Marks the lesson as completed, applies streak rule, and awards 30 XP completion bonus.
  Future<void> completeLesson(String lessonId, [DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    final updatedStreak = calculateStreak(
      currentStreak: _progress.streakDays,
      lastActiveDay: _progress.lastActiveDay,
      now: currentTime,
    );

    final alreadyCompleted = _progress.completedLessonIds.contains(lessonId);
    final completed = alreadyCompleted
        ? _progress.completedLessonIds
        : [..._progress.completedLessonIds, lessonId];
    final bonus = alreadyCompleted ? 0 : 30;

    _progress = _progress.copyWith(
      completedLessonIds: completed,
      streakDays: updatedStreak,
      lastActiveDay: currentTime,
      xp: _progress.xp + bonus,
    );

    notifyListeners();
    await _service.save(_progress);
  }

  /// Awards XP and persists the updated progress.
  Future<void> awardXp(int amount) async {
    if (amount == 0) return;
    _progress = _progress.copyWith(xp: _progress.xp + amount);
    notifyListeners();
    await _service.save(_progress);
  }
}
