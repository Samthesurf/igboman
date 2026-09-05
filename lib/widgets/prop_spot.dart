import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';

/// Named Igbo prop illustrations (storybook style) used as small accents
/// around the app: yam, lion, palm, kolanut, ogene.
abstract final class PropArt {
  static const List<String> names = ['yam', 'lion', 'palm', 'kolanut', 'ogene'];

  static String path(String name) => 'assets/images/props/$name.jpg';

  /// Deterministic pick so lists (stories, strips) vary without state.
  static String forIndex(int index) => path(names[index % names.length]);
}

/// A small rounded prop illustration. Keeps the beige storybook backdrop,
/// so it reads as a sticker rather than a photo.
class PropSpot extends StatelessWidget {
  const PropSpot({super.key, required this.name, this.size = AvatarSizes.card});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.chip),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.chip),
        child: Image.asset(
          PropArt.path(name),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
