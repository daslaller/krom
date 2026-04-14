import 'dart:ui';

/// Monochrome chrome — color lives in code, not in the shell.
abstract final class KromColors {
  // Backgrounds
  static const background = Color(0xFF1E1E1E);
  static const surface = Color(0xFF252526);
  static const surfaceHover = Color(0xFF2A2A2B);
  static const surfaceActive = Color(0xFF37373D);

  // Borders
  static const border = Color(0xFF333333);

  // Text
  static const text = Color(0xFFCCCCCC);
  static const textSecondary = Color(0xFF858585);
  static const textDisabled = Color(0xFF5A5A5A);

  // Single accent
  static const accent = Color(0xFF5B8DD9);

  // Gutter
  static const gutter = Color(0xFF1E1E1E);

  // Tab bar
  static const tabBarBg = Color(0xFF181818);
  static const tabActive = Color(0xFF1E1E1E);
  static const tabInactive = Color(0xFF181818);

  // Selection
  static const selection = Color(0x40FFFFFF);
}
