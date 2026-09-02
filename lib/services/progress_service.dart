import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress.dart';

/// Calculates the updated streak value according to the streak rules:
/// - lastActiveDay == today: streak unchanged
/// - lastActiveDay == yesterday: streak + 1
/// - lastActiveDay == two days ago (grace day): streak + 1
/// - otherwise (gap >= 3 days or no history): streak = 1
int calculateStreak({
  required int currentStreak,
  required DateTime? lastActiveDay,
  required DateTime now,
}) {
  if (lastActiveDay == null) {
    return 1;
  }

  final todayUtc = DateTime.utc(now.year, now.month, now.day);
  final lastUtc = DateTime.utc(
    lastActiveDay.year,
    lastActiveDay.month,
    lastActiveDay.day,
  );
  final dayDiff = todayUtc.difference(lastUtc).inDays;

  if (dayDiff <= 0) {
    return currentStreak > 0 ? currentStreak : 1;
  } else if (dayDiff == 1) {
    return currentStreak + 1;
  } else if (dayDiff == 2) {
    return currentStreak + 1;
  } else {
    return 1;
  }
}

/// Service managing persistence of user progress in SharedPreferences.
///
/// Stores a single versioned JSON payload under key [storageKey].
///
/// Streak rule on any lesson completion:
/// - lastActiveDay == today: streak unchanged
/// - lastActiveDay == yesterday: streak + 1
/// - lastActiveDay == two days ago (grace day): streak + 1
/// - otherwise (gap >= 3 days or no history): streak = 1
/// lastActiveDay always becomes today.
class ProgressService {
  static const String storageKey = 'igboman_progress_v1';

  final SharedPreferences? prefs;

  const ProgressService({this.prefs});

  Future<SharedPreferences> _getPrefs() async {
    final p = prefs;
    if (p != null) {
      return p;
    }
    return SharedPreferences.getInstance();
  }

  /// Loads saved progress data or returns fresh defaults if absent or corrupted.
  Future<ProgressData> load() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) {
        return const ProgressData();
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ProgressData.fromJson(decoded);
      }
      return const ProgressData();
    } catch (_) {
      return const ProgressData();
    }
  }

  /// Saves the given progress data as a JSON string payload.
  Future<void> save(ProgressData data) async {
    final prefs = await _getPrefs();
    final jsonString = jsonEncode(data.toJson());
    await prefs.setString(storageKey, jsonString);
  }
}
