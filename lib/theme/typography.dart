import 'package:flutter/material.dart';

abstract final class KromTypography {
  static const codeFontFamily = 'Cascadia Code';
  static const uiFontFamily = 'Segoe UI Variable';
  static const codeFontFallback = ['Consolas', 'Courier New', 'monospace'];
  static const uiFontFallback = ['Segoe UI', 'Arial', 'sans-serif'];

  static const codeFontSize = 14.0;
  static const codeLineHeight = 1.6;
  static const uiFontSize = 13.5;
  static const uiFontSizeSmall = 12.0;

  static TextStyle code({Color? color}) => TextStyle(
        fontFamily: codeFontFamily,
        fontFamilyFallback: codeFontFallback,
        fontSize: codeFontSize,
        height: codeLineHeight,
        color: color,
      );

  static TextStyle ui({
    Color? color,
    double? fontSize,
    FontWeight? weight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallback,
        fontSize: fontSize ?? uiFontSize,
        color: color,
        fontWeight: weight,
        height: height,
      );
}
