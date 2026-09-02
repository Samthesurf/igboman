import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';

/// Shared flat action button for Igboman: solid fill, no elevation, no edge.
///
/// Disabled buttons use the disabled fill and text colors.
class FlatButton extends StatelessWidget {
  const FlatButton({
    super.key,
    required this.label,
    this.icon,
    required this.enabled,
    required this.color,
    this.height = ControlSizes.buttonHeight,
    this.onTap,
  });

  final String label;

  /// Optional leading icon shown before the label.
  final IconData? icon;

  final bool enabled;
  final Color color;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor = enabled ? AppColors.onSecondary : AppColors.disabledText;

    return Material(
      color: enabled ? color : AppColors.disabledFill,
      borderRadius: BorderRadius.circular(Radii.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.button),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: IconSizes.m, color: labelColor),
                  const SizedBox(width: Spacing.s),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: TypeScale.body,
                    fontWeight: FontWeight.bold,
                    color: labelColor,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
