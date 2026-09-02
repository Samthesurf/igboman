import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/dimens.dart';

/// Shared flat action button for Igboman: solid fill, no elevation, and an
/// optional bottom edge strip that collapses while pressed.
///
/// The edge strip defaults to the darker green [AppColors.buttonEdge] when
/// the fill is the secondary (green) color, and is absent otherwise. While
/// the button is pressed the strip animates away (down to 0 height) so the
/// button reads as physically pushed; releasing it restores the strip.
///
/// Disabled buttons use the disabled fill and text colors and show no edge.
class FlatButton extends StatefulWidget {
  const FlatButton({
    super.key,
    required this.label,
    this.icon,
    required this.enabled,
    required this.color,
    this.edgeColor,
    this.height = ControlSizes.buttonHeight,
    this.onTap,
  });

  final String label;

  /// Optional leading icon shown before the label.
  final IconData? icon;

  final bool enabled;
  final Color color;

  /// Explicit edge color; when null the default edge rule applies (green
  /// fill gets [AppColors.buttonEdge], other fills get no edge).
  final Color? edgeColor;

  final double height;
  final VoidCallback? onTap;

  @override
  State<FlatButton> createState() => _FlatButtonState();
}

class _FlatButtonState extends State<FlatButton> {
  bool _pressed = false;

  Color? get _effectiveEdgeColor {
    final explicit = widget.edgeColor;
    if (explicit != null) return explicit;
    if (widget.color == AppColors.secondary) return AppColors.buttonEdge;
    return null;
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
  }

  void _restoreEdge() {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  void _onTap() {
    if (widget.enabled) widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final fill = enabled ? widget.color : AppColors.disabledFill;
    final labelColor = enabled ? AppColors.onSecondary : AppColors.disabledText;
    final edgeColor = enabled ? _effectiveEdgeColor : null;
    final edgeHeight = _pressed || !enabled ? 0.0 : Spacing.xs;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(Radii.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.button),
        onTapDown: _onTapDown,
        onTapUp: (_) => _restoreEdge(),
        onTapCancel: _restoreEdge,
        onTap: _onTap,
        child: SizedBox(
          width: double.infinity,
          height: widget.height,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: IconSizes.m, color: labelColor),
                        const SizedBox(width: Spacing.s),
                      ],
                      Text(
                        widget.label,
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
              AnimatedContainer(
                duration: kFastAnim,
                width: double.infinity,
                height: edgeHeight,
                decoration: BoxDecoration(
                  color: edgeColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(Radii.button),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
