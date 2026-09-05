import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import 'avatar_view.dart';

/// A roster character reacting to a finished run.
class CoachComment {
  final String assetPath;
  final String phrase;

  const CoachComment({required this.assetPath, required this.phrase});
}

const List<String> _rosterAssets = [
  'assets/images/ada.jpg',
  'assets/images/kid.jpg',
  'assets/images/nna.jpg',
  'assets/images/mama.jpg',
  'assets/images/mbe.jpg',
];

const List<String> _perfectLines = [
  'Flawless run! Every answer correct. The village is proud of you.',
  'Perfect! Not a single miss. Keep this fire burning.',
];

const List<String> _goodLines = [
  'Strong run! A few slipped away. Review your answers and run it back.',
  'Good work. Review the ones you missed and you will be unstoppable.',
];

const List<String> _poorLines = [
  'You can do better. Review your answers, then try again.',
  'Tough round. Review your answers and come back stronger.',
];

/// Picks a random roster character and a phrase tiered by performance:
/// perfect when every answer is right, good when most are right, else poor.
CoachComment pickCoachComment({
  required int correct,
  required int total,
  math.Random? random,
}) {
  final rng = random ?? math.Random();
  final asset = _rosterAssets[rng.nextInt(_rosterAssets.length)];
  final List<String> pool;
  if (total > 0 && correct == total) {
    pool = _perfectLines;
  } else if (total == 0 || correct * 2 > total) {
    pool = _goodLines;
  } else {
    pool = _poorLines;
  }
  return CoachComment(assetPath: asset, phrase: pool[rng.nextInt(pool.length)]);
}

/// The coach comment row: roster avatar on the left, a speech bubble on
/// the right with its tail pointing at the speaker, and the phrase
/// streaming in letter by letter.
class CoachCommentView extends StatelessWidget {
  const CoachCommentView({super.key, required this.comment});

  final CoachComment comment;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('coachComment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarView(
          assetPath: comment.assetPath,
          initial: 'C',
          size: AvatarSizes.chat,
        ),
        const SizedBox(width: Spacing.m),
        Expanded(child: _SideBubble(text: comment.phrase)),
      ],
    );
  }
}

/// Speech bubble with the tail on its left edge, pointing at the avatar.
class _SideBubble extends StatelessWidget {
  const _SideBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(
          size: const Size(Spacing.s, Spacing.md),
          painter: _LeftTailPainter(AppColors.surface),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.s,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.chip),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: _StreamingText(text: text),
          ),
        ),
      ],
    );
  }
}

/// Small left-pointing triangle tail, filled with the bubble color.
class _LeftTailPainter extends CustomPainter {
  const _LeftTailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LeftTailPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Reveals [text] letter by letter on a short timer so static lines feel
/// spoken. Settles on the full text, so tests can pump past it.
class _StreamingText extends StatefulWidget {
  const _StreamingText({required this.text});

  final String text;

  @override
  State<_StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<_StreamingText> {
  static const _step = Duration(milliseconds: 18);

  int _shown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_step, (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant _StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      setState(() => _shown = 0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_shown >= widget.text.length) {
      _timer?.cancel();
      return;
    }
    setState(() => _shown += 1);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      key: const Key('coachCommentText'),
      widget.text.substring(0, _shown.clamp(0, widget.text.length)),
      style: const TextStyle(
        fontSize: TypeScale.body,
        color: AppColors.textPrimary,
        fontFamily: 'NotoSans',
        height: TypeScale.bodyLineHeight,
      ),
    );
  }
}
