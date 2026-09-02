/// Design tokens for Igboman: spacing, radius, sizing, type scale.
///
/// Every layout value in the app must reference these tokens; hardcoded
/// literals are flagged by the spacing audit test. All spacing values are
/// multiples of 4 (calculated grid), so layouts stay rhythmically aligned.
library;


abstract final class Spacing {
  static const double xs = 4; // 4
  static const double s = 8; // 8
  static const double m = 12; // 12
  static const double md = 16; // 16
  static const double lg = 24; // 24
  static const double xl = 32; // 32
  static const double xxl = 40; // 40
  static const double xxxl = 48; // 48
  static const double huge = 64; // 64
}

abstract final class Radii {
  static const double chip = 8;
  static const double button = 12;
  static const double card = 16;
  static const double hero = 24;
}

abstract final class IconSizes {
  static const double s = 16;
  static const double m = 20;
  static const double md = 24;
  static const double lg = 32;
}

abstract final class AvatarSizes {
  static const double chat = 48;
  static const double card = 64;
  static const double hero = 96;
  static const double mini = 32;
}

abstract final class ControlSizes {
  static const double buttonHeight = 48;
  static const double chipHeight = 32;
  static const double progressBarS = 8;
  static const double progressBarMd = 12;
  static const double minTouchTarget = 48;
  static const double contentMaxWidth = 600;
}

abstract final class TypeScale {
  static const double display = 32;
  static const double headline = 24;
  static const double title = 20;
  static const double body = 16;
  static const double bodySmall = 14;
  static const double label = 14;
  static const double caption = 12;

  static const double bodyLineHeight = 1.5;
  static const double labelLetterSpacing = 0.3;
}

const Duration kFastAnim = Duration(milliseconds: 150);
const Duration kMedAnim = Duration(milliseconds: 300);