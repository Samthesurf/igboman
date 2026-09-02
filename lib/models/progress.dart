import 'package:flutter/foundation.dart';

@immutable
class ProgressData {
  final int schemaVersion;
  final int xp;
  final int streakDays;
  final DateTime? lastActiveDay;
  final List<String> completedLessonIds;
  final List<String> completedStoryIds;

  const ProgressData({
    this.schemaVersion = 1,
    this.xp = 0,
    this.streakDays = 0,
    this.lastActiveDay,
    this.completedLessonIds = const [],
    this.completedStoryIds = const [],
  });

  ProgressData copyWith({
    int? schemaVersion,
    int? xp,
    int? streakDays,
    DateTime? lastActiveDay,
    List<String>? completedLessonIds,
    List<String>? completedStoryIds,
  }) {
    return ProgressData(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDay: lastActiveDay ?? this.lastActiveDay,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      completedStoryIds: completedStoryIds ?? this.completedStoryIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'xp': xp,
      'streakDays': streakDays,
      'lastActiveDay': lastActiveDay?.toIso8601String(),
      'completedLessonIds': completedLessonIds,
      'completedStoryIds': completedStoryIds,
    };
  }

  factory ProgressData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProgressData();
    }

    int schemaVersion = 1;
    final rawSchema = json['schemaVersion'];
    if (rawSchema is num) {
      schemaVersion = rawSchema.toInt();
    } else if (rawSchema is String) {
      schemaVersion = int.tryParse(rawSchema) ?? 1;
    }

    int xp = 0;
    final rawXp = json['xp'];
    if (rawXp is num) {
      xp = rawXp.toInt();
    } else if (rawXp is String) {
      xp = int.tryParse(rawXp) ?? 0;
    }

    int streakDays = 0;
    final rawStreak = json['streakDays'];
    if (rawStreak is num) {
      streakDays = rawStreak.toInt();
    } else if (rawStreak is String) {
      streakDays = int.tryParse(rawStreak) ?? 0;
    }

    DateTime? lastActiveDay;
    final rawLastActiveDay = json['lastActiveDay'];
    if (rawLastActiveDay is String) {
      try {
        lastActiveDay = DateTime.parse(rawLastActiveDay);
      } catch (_) {
        lastActiveDay = null;
      }
    }

    List<String> completedLessonIds = const [];
    final rawCompleted = json['completedLessonIds'];
    if (rawCompleted is List) {
      completedLessonIds = rawCompleted
          .whereType<String>()
          .toList(growable: false);
    }

    // Tolerant read: older save files predate stories, so a missing or
    // malformed field defaults to an empty list. Schema version stays 1.
    List<String> completedStoryIds = const [];
    final rawStories = json['completedStoryIds'];
    if (rawStories is List) {
      completedStoryIds = rawStories
          .whereType<String>()
          .toList(growable: false);
    }

    return ProgressData(
      schemaVersion: schemaVersion,
      xp: xp,
      streakDays: streakDays,
      lastActiveDay: lastActiveDay,
      completedLessonIds: completedLessonIds,
      completedStoryIds: completedStoryIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressData &&
        other.schemaVersion == schemaVersion &&
        other.xp == xp &&
        other.streakDays == streakDays &&
        other.lastActiveDay == lastActiveDay &&
        listEquals(other.completedLessonIds, completedLessonIds) &&
        listEquals(other.completedStoryIds, completedStoryIds);
  }

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        xp,
        streakDays,
        lastActiveDay,
        Object.hashAll(completedLessonIds),
        Object.hashAll(completedStoryIds),
      );
}
