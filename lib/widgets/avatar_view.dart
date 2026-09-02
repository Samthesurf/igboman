import 'package:flutter/material.dart';
import 'package:igboman/theme/app_theme.dart';

class AvatarView extends StatelessWidget {
  const AvatarView({
    super.key,
    this.assetPath,
    this.initial = 'A',
    this.size = 48.0,
    this.borderRadius = 12.0,
  });

  final String? assetPath;
  final String initial;
  final double size;
  final double borderRadius;

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.45,
          fontFamily: 'NotoSans',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null || path.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      ),
    );
  }
}
