import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';

/// Comic-style speech bubble with a flat tail pointing downward toward the
/// avatar.
///
/// The bubble is a rounded rectangle (radius [Radii.chip]) with a small
/// triangle tail below it, painted in the same color as the bubble body.
/// Width auto-sizes to its content up to [maxWidthFactor] of the available
/// width (via ConstrainedBox + IntrinsicWidth).
///
/// While [waiting] is true and [text] is empty, three small bouncing green
/// dots are shown instead of text.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.waiting = false,
    this.showTail = true,
    this.color,
    this.maxWidthFactor = 0.75,
  });

  /// The bubble content. When empty and [waiting] is true, typing dots show.
  final String text;

  /// When true and [text] is empty, animated typing dots are shown.
  final bool waiting;

  /// Whether to paint the tail triangle below the bubble body.
  final bool showTail;

  /// Bubble fill color; defaults to surface white.
  final Color? color;

  /// Maximum bubble width as a fraction of the available width.
  final double maxWidthFactor;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = color ?? AppColors.surface;
    final showDots = waiting && text.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * maxWidthFactor;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.s,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(Radii.chip),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: showDots
                    ? const _TypingDots()
                    : Text(
                        text,
                        style: const TextStyle(
                          fontSize: TypeScale.body,
                          color: AppColors.textPrimary,
                          fontFamily: 'NotoSans',
                          height: TypeScale.bodyLineHeight,
                        ),
                      ),
              ),
            ),
            if (showTail)
              CustomPaint(
                size: const Size(Spacing.m, Spacing.s),
                painter: _TailPainter(bubbleColor),
              ),
          ],
        );
      },
    );
  }
}

/// Small downward-pointing triangle tail, filled with the bubble color.
class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.color != color;
}

/// Three small green dots that bounce in a staggered wave while waiting.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450), // 3 * kFastAnim
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(int index) {
    final anim = _controller.drive(
      CurveTween(
        curve: Interval(index / 3, index / 3 + 1 / 3, curve: Curves.easeInOut),
      ),
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = anim.value.clamp(0.0, 1.0);
        final bounce = v <= 0.5 ? v * 2 : (1 - v) * 2;
        return Transform.translate(
          offset: Offset(0, -Spacing.xs * (1 - bounce)),
          child: Opacity(opacity: 0.3 + 0.7 * bounce, child: child),
        );
      },
      child: Container(
        width: Spacing.s,
        height: Spacing.s,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(Spacing.xs),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('speechBubbleTypingDots'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(0),
        const SizedBox(width: Spacing.xs),
        _dot(1),
        const SizedBox(width: Spacing.xs),
        _dot(2),
      ],
    );
  }
}
