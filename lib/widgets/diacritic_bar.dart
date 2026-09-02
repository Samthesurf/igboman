import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/dimens.dart';

const List<String> diacriticCharacters = [
  'ị',
  'ọ',
  'ụ',
  'ṅ',
  'á',
  'à',
  'é',
  'è',
  'í',
  'ì',
  'ó',
  'ò',
  'ú',
  'ù',
];

class DiacriticBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onCharacterSelected;
  final List<String> characters;

  const DiacriticBar({
    super.key,
    this.controller,
    this.onCharacterSelected,
    this.characters = diacriticCharacters,
  });

  static void insertAtCursor(TextEditingController controller, String char) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, char);
    final newOffset = start + char.length;

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  void _handleTap(String char) {
    if (controller != null) {
      insertAtCursor(controller!, char);
    }
    onCharacterSelected?.call(char);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: characters.map((char) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
            child: Material(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(Radii.chip),
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.chip),
                onTap: () => _handleTap(char),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: ControlSizes.chipHeight,
                    minHeight: ControlSizes.chipHeight,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.s,
                    vertical: Spacing.xs,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    char,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: TypeScale.body,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
