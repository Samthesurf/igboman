import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igboman/theme/app_theme.dart';

void main() {
  group('AppTheme and AppColors', () {
    test('AppColors palette matches specification', () {
      expect(AppColors.primary, const Color(0xFFA9744F));
      expect(AppColors.secondary, const Color(0xFF008751));
      expect(AppColors.background, const Color(0xFFFBF6EF));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.onPrimary, const Color(0xFFFFFFFF));
    });

    test('buildAppTheme configures Material 3, NotoSans font, and colors', () {
      final theme = buildAppTheme();

      expect(theme.useMaterial3, isTrue);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'NotoSans');
      expect(theme.textTheme.headlineMedium?.fontFamily, 'NotoSans');
      expect(theme.colorScheme.primary, const Color(0xFFA9744F));
      expect(theme.colorScheme.secondary, const Color(0xFF008751));
      expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
      expect(theme.colorScheme.onPrimary, const Color(0xFFFFFFFF));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFBF6EF));
    });
  });
}
