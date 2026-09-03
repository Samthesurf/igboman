import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import 'flat_button.dart';

class StreakChip extends StatelessWidget {
  const StreakChip({super.key, this.streak});

  final int? streak;

  void _openDetails(BuildContext context, int streakValue) {
    DateTime? lastActive;
    try {
      lastActive = context.read<AppState>().progress.lastActiveDay;
    } catch (_) {
      lastActive = DateTime.now();
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StreakDetailsSheet(
        streakDays: streakValue,
        lastActiveDay: lastActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int value = streak ?? 0;
    if (streak == null) {
      try {
        value = context.watch<AppState>().streakDays;
      } catch (_) {
        value = 0;
      }
    }

    return GestureDetector(
      key: const Key('streakChipTap'),
      onTap: () => _openDetails(context, value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.s,
          vertical: Spacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.secondary, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
                fontFamily: 'NotoSans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet displaying streak statistics and a 7-day calendar strip.
class StreakDetailsSheet extends StatelessWidget {
  const StreakDetailsSheet({
    super.key,
    required this.streakDays,
    this.lastActiveDay,
  });

  final int streakDays;
  final DateTime? lastActiveDay;

  bool _isActiveToday() {
    if (lastActiveDay == null) return false;
    final now = DateTime.now();
    return now.year == lastActiveDay!.year &&
        now.month == lastActiveDay!.month &&
        now.day == lastActiveDay!.day;
  }

  @override
  Widget build(BuildContext context) {
    final activeToday = _isActiveToday();
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Mon, 7 = Sun

    return Container(
      key: const Key('streakDetailsSheet'),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.card),
          topRight: Radius.circular(Radii.card),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                const SizedBox(width: Spacing.s),
                const Text(
                  'Streak Details',
                  style: TextStyle(
                    fontSize: TypeScale.title,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'NotoSans',
                  ),
                ),
                const Spacer(),
                IconButton(
                  key: const Key('closeStreakDetailsButton'),
                  icon: const Icon(Icons.close, size: IconSizes.m),
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            // Highlight card
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: AppColors.warnBg,
                borderRadius: BorderRadius.circular(Radii.card),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Text(
                    '$streakDays Day Streak',
                    style: const TextStyle(
                      fontSize: TypeScale.headline,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    activeToday
                        ? 'Streak active today! Keep your run going strong.'
                        : 'Complete a lesson today to keep your streak alive!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: TypeScale.bodySmall,
                      color: AppColors.textSecondary,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            // Calendar strip
            Container(
              key: const Key('streakCalendarStrip'),
              padding: const EdgeInsets.all(Spacing.m),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(Radii.card),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: TypeScale.caption,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                  const SizedBox(height: Spacing.s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DayPip(
                        label: 'Mon',
                        dayIndex: 1,
                        currentWeekday: currentWeekday,
                        streakDays: streakDays,
                        activeToday: activeToday,
                      ),
                      _DayPip(
                        label: 'Tue',
                        dayIndex: 2,
                        currentWeekday: currentWeekday,
                        streakDays: streakDays,
                        activeToday: activeToday,
                      ),
                      _DayPip(
                        label: 'Wed',
                        dayIndex: 3,
                        currentWeekday: currentWeekday,
                        streakDays: streakDays,
                        activeToday: activeToday,
                      ),
                      _DayPip(
                        label: 'Thu',
                        dayIndex: 4,
                        currentWeekday: currentWeekday,
                        streakDays: streakDays,
                        activeToday: activeToday,
                      ),
                      _DayPip(
                        label: 'Fri',
                        dayIndex: 5,
                        currentWeekday: currentWeekday,
                        streakDays: streakDays,
                        activeToday: activeToday,
                      ),
                      _DayPip(
                        label: 'Sat',
                        dayIndex: 6,
                        currentWeekday: currentWeekday,
                        streakDays: streakDays,
                        activeToday: activeToday,
                      ),
                      _DayPip(
                        label: 'Sun',
                        dayIndex: 7,
                        currentWeekday: currentWeekday,
                        streakDays: streakDays,
                        activeToday: activeToday,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            // Grace window info
            Container(
              padding: const EdgeInsets.all(Spacing.m),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(Radii.card),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: IconSizes.m,
                    color: AppColors.secondary,
                  ),
                  SizedBox(width: Spacing.s),
                  Expanded(
                    child: Text(
                      'A 1-day grace window protects your streak if life gets busy.',
                      style: TextStyle(
                        fontSize: TypeScale.caption,
                        color: AppColors.textPrimary,
                        fontFamily: 'NotoSans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
            FlatButton(
              label: 'Got it',
              enabled: true,
              color: AppColors.secondary,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayPip extends StatelessWidget {
  const _DayPip({
    required this.label,
    required this.dayIndex,
    required this.currentWeekday,
    required this.streakDays,
    required this.activeToday,
  });

  final String label;
  final int dayIndex;
  final int currentWeekday;
  final int streakDays;
  final bool activeToday;

  @override
  Widget build(BuildContext context) {
    final isToday = dayIndex == currentWeekday;
    final isPast = dayIndex < currentWeekday;
    final daysAgo = currentWeekday - dayIndex;
    final wasActive = isToday ? activeToday : (isPast && daysAgo < streakDays);

    Color pipColor = AppColors.surface;
    Color borderColor = AppColors.cardBorder;
    Color textColor = AppColors.textSecondary;

    if (wasActive) {
      pipColor = AppColors.secondary;
      borderColor = AppColors.secondary;
      textColor = AppColors.onSecondary;
    } else if (isToday) {
      pipColor = AppColors.warnBg;
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: TypeScale.caption,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? AppColors.primary : AppColors.textSecondary,
            fontFamily: 'NotoSans',
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: pipColor,
            borderRadius: BorderRadius.circular(Radii.chip),
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: wasActive
              ? const Icon(
                  Icons.check,
                  size: IconSizes.s,
                  color: AppColors.onSecondary,
                )
              : Text(
                  '$dayIndex',
                  style: TextStyle(
                    fontSize: TypeScale.caption,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'NotoSans',
                  ),
                ),
        ),
      ],
    );
  }
}
