import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFFA9744F);
  static const Color secondary = Color(0xFF008751);
  static const Color background = Color(0xFFFBF6EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF2D241E);
  static const Color onSurface = Color(0xFF2D241E);
  static const Color textPrimary = Color(0xFF2D241E);
  static const Color textSecondary = Color(0xFF6B5E55);
  static const Color cardBorder = Color(0xFFE8DFD5);

  // Feedback and state tokens (v3 design system)
  static const Color error = Color(0xFFC75B39); // flat terracotta for wrong answers
  static const Color successBg = Color(0xFFEAF3EE); // light green tint
  static const Color warnBg = Color(0xFFF6EDE3); // light brown tint
  static const Color disabledFill = Color(0xFFE8DFD5);
  static const Color disabledText = Color(0xFF9E9085);
  static const Color buttonEdge = Color(0xFF006B42); // darker green, flat button edge
}

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSans',
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'NotoSans'),
      headlineMedium: TextStyle(color: AppColors.textPrimary, fontFamily: 'NotoSans'),
      headlineSmall: TextStyle(color: AppColors.textPrimary, fontFamily: 'NotoSans'),
      titleLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'NotoSans'),
      titleMedium: TextStyle(color: AppColors.textPrimary, fontFamily: 'NotoSans'),
      titleSmall: TextStyle(color: AppColors.textPrimary, fontFamily: 'NotoSans'),
      bodyLarge: TextStyle(color: AppColors.textPrimary, fontFamily: 'NotoSans'),
      bodyMedium: TextStyle(color: AppColors.textPrimary, fontFamily: 'NotoSans'),
      bodySmall: TextStyle(color: AppColors.textSecondary, fontFamily: 'NotoSans'),
    ),
  );
}
