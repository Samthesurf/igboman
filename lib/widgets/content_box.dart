import 'package:flutter/material.dart';
import '../theme/dimens.dart';

/// Centers content on large screens and caps its width, keeping minimum
/// horizontal gutters on all breakpoints.
class ContentBox extends StatelessWidget {
  const ContentBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ControlSizes.contentMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: child,
        ),
      ),
    );
  }
}