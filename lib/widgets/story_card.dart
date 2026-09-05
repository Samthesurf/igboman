import 'package:flutter/material.dart';

import '../models/story.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';
import 'prop_spot.dart';

/// Flat story card: prop illustration, English title, unit badge, and a
/// lock state driven by the parent (AppState.unitIsUnlocked passed in as
/// [unlocked]). Each unlocked story shows the Igbo prop for its unit.
class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.story,
    required this.unlocked,
    required this.onTap,
  });

  final Story story;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = unlocked
        ? AppColors.textPrimary
        : AppColors.disabledText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            if (unlocked)
              PropSpot(
                key: Key('storyProp_${story.unitId}'),
                name: PropArt.names[story.unitId % PropArt.names.length],
              )
            else
              Container(
                width: AvatarSizes.card,
                height: AvatarSizes.card,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.disabledFill,
                  borderRadius: BorderRadius.circular(Radii.chip),
                ),
                child: const Icon(
                  Icons.lock,
                  color: AppColors.disabledText,
                  size: IconSizes.lg,
                ),
              ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.titleEn,
                    style: TextStyle(
                      fontSize: TypeScale.title,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    story.titleIgbo,
                    style: const TextStyle(
                      fontSize: TypeScale.bodySmall,
                      color: AppColors.textSecondary,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.s),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.s,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: unlocked ? AppColors.warnBg : AppColors.disabledFill,
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Text(
                'Unit ${story.unitId}',
                style: TextStyle(
                  fontSize: TypeScale.caption,
                  fontWeight: FontWeight.bold,
                  color: unlocked ? AppColors.primary : AppColors.disabledText,
                  fontFamily: 'NotoSans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
