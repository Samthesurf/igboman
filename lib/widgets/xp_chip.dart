import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:igboman/state/app_state.dart';
import 'package:igboman/theme/app_theme.dart';
import 'package:igboman/theme/dimens.dart';

class XpChip extends StatelessWidget {
  const XpChip({super.key, this.xp});

  final int? xp;

  @override
  Widget build(BuildContext context) {
    final value = xp ?? context.watch<AppState>().xp;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      ),
    );
  }
}
