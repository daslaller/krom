import 'package:flutter/material.dart';
import 'krom_colors.dart';
import 'typography.dart';

abstract final class KromTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: KromColors.background,
      colorScheme: const ColorScheme.dark(
        primary: KromColors.accent,
        surface: KromColors.surface,
      ),
      cardColor: KromColors.surface,
      dividerColor: KromColors.border,
      textTheme: TextTheme(
        bodyMedium: KromTypography.ui(color: KromColors.text),
        bodySmall: KromTypography.ui(
          color: KromColors.textSecondary,
          fontSize: KromTypography.uiFontSizeSmall,
        ),
        labelMedium: KromTypography.ui(color: KromColors.text),
      ),
      iconTheme: const IconThemeData(
        color: KromColors.textSecondary,
        size: 18,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          KromColors.textDisabled.withAlpha(80),
        ),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
      ),
    );
  }
}
