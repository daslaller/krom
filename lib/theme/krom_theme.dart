import 'package:flutter/material.dart';
import '../frontends/ide_concepts/ide_concepts_theme.dart';
import 'krom_colors.dart';
import 'typography.dart';

abstract final class KromTheme {
  static ThemeData dark() => fromIdeConcepts(IdeConceptsTheme.midnightIndigo);

  static ThemeData light() => fromIdeConcepts(IdeConceptsTheme.paperLight);

  static ThemeData fromIdeConcepts(IdeConceptsTheme concepts, {double? uiFontSize}) {
    final isDark = concepts.brightness == Brightness.dark;
    final uiSize = uiFontSize ?? KromTypography.uiFontSize;
    return ThemeData(
      brightness: concepts.brightness,
      scaffoldBackgroundColor: concepts.editorBg,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: concepts.accent,
              surface: concepts.sidebarBg,
            )
          : ColorScheme.light(
              primary: concepts.accent,
              surface: concepts.sidebarBg,
            ),
      cardColor: concepts.panelBg,
      dividerColor: concepts.hairline,
      textTheme: TextTheme(
        bodyMedium: KromTypography.ui(color: concepts.text, fontSize: uiSize),
        bodySmall: KromTypography.ui(color: concepts.muted, fontSize: uiSize - 1),
        labelMedium: KromTypography.ui(color: concepts.text, fontSize: uiSize),
      ),
      iconTheme: IconThemeData(color: concepts.muted, size: 18),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          concepts.iconDim.withValues(alpha: 0.5),
        ),
        thickness: WidgetStateProperty.all(8),
        radius: const Radius.circular(4),
      ),
    );
  }

  /// Legacy dark theme for the old editor shell.
  static ThemeData legacyDark() {
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
