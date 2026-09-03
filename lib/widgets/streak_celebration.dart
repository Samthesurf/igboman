import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import 'flat_button.dart';

/// Returns true if the session activity represents a streak restoration
/// via the 2-day gap grace day rule.
bool isStreakRestored({
  required DateTime? lastActiveDay,
  required DateTime now,
}) {
  if (lastActiveDay == null) return false;

  final todayUtc = DateTime.utc(now.year, now.month, now.day);
  final lastUtc = DateTime.utc(
    lastActiveDay.year,
    lastActiveDay.month,
    lastActiveDay.day,
  );
  final dayDiff = todayUtc.difference(lastUtc).inDays;
  return dayDiff == 2;
}

/// A lightweight, tasteful confetti widget rendering flat rectangular pieces.
/// Pure Flutter CustomPainter without external packages or gradients.
class TastefulConfetti extends StatefulWidget {
  const TastefulConfetti({super.key});

  @override
  State<TastefulConfetti> createState() => _TastefulConfettiState();
}

class _TastefulConfettiState extends State<TastefulConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ConfettiPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ConfettiParticle {
  final double xRatio;
  final double yOffset;
  final double speed;
  final double width;
  final double height;
  final double rotationSpeed;
  final Color color;

  const _ConfettiParticle({
    required this.xRatio,
    required this.yOffset,
    required this.speed,
    required this.width,
    required this.height,
    required this.rotationSpeed,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  static final List<_ConfettiParticle> _particles = _initParticles();

  static List<_ConfettiParticle> _initParticles() {
    const palette = [
      AppColors.secondary,
      AppColors.primary,
      AppColors.disabledFill,
      AppColors.error,
      AppColors.secondary,
      AppColors.primary,
    ];

    final list = <_ConfettiParticle>[];
    for (var i = 0; i < 28; i++) {
      final rand = math.Random(i * 17);
      list.add(
        _ConfettiParticle(
          xRatio: (i * 0.035 + rand.nextDouble() * 0.04).clamp(0.05, 0.95),
          yOffset: rand.nextDouble(),
          speed: 0.6 + rand.nextDouble() * 0.8,
          width: 8.0,
          height: (i % 2 == 0) ? 12.0 : 8.0,
          rotationSpeed: 2.0 + rand.nextDouble() * 4.0,
          color: palette[i % palette.length],
        ),
      );
    }
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = ((progress * p.speed + p.yOffset) % 1.0) * size.height;
      final x =
          p.xRatio * size.width + math.sin(progress * 6.28 + p.yOffset) * 12;

      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotationSpeed * math.pi);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.width, height: p.height),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A celebratory dialog showing the restored or extended streak with confetti.
class StreakCelebrationDialog extends StatelessWidget {
  const StreakCelebrationDialog({
    super.key,
    required this.streakDays,
    this.isRestored = true,
    this.onContinue,
  });

  final int streakDays;
  final bool isRestored;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final title = isRestored ? 'Streak Restored!' : 'Streak Extended!';
    final description = isRestored
        ? 'Your streak was saved by the grace window! Keep the momentum going.'
        : 'Another day, another victory! Your run continues.';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(Spacing.lg),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(
              maxWidth: ControlSizes.contentMaxWidth,
            ),
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: AppColors.secondary, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flame badge
                Container(
                  width: AvatarSizes.hero,
                  height: AvatarSizes.hero,
                  decoration: BoxDecoration(
                    color: AppColors.warnBg,
                    borderRadius: BorderRadius.circular(Radii.hero),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🔥', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: TypeScale.headline,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'NotoSans',
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.m,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                  child: Text(
                    '$streakDays day streak',
                    style: const TextStyle(
                      fontSize: TypeScale.body,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.m),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: TypeScale.bodySmall,
                    color: AppColors.textSecondary,
                    fontFamily: 'NotoSans',
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                FlatButton(
                  key: const Key('streakCelebrationContinue'),
                  label: 'Keep Running',
                  enabled: true,
                  color: AppColors.secondary,
                  onTap: () {
                    if (onContinue != null) {
                      onContinue!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: TastefulConfetti()),
          ),
        ],
      ),
    );
  }
}

/// Helper function to display the streak celebration dialog.
Future<void> showStreakCelebration(
  BuildContext context, {
  required int streakDays,
  bool isRestored = true,
  VoidCallback? onContinue,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => StreakCelebrationDialog(
      streakDays: streakDays,
      isRestored: isRestored,
      onContinue: onContinue,
    ),
  );
}
