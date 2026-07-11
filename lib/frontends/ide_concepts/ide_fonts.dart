import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography helpers for the IDE Concepts frontend.
abstract final class IdeFonts {
  static TextStyle mono({
    double? fontSize,
    Color? color,
    FontWeight? weight,
    double? height,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize ?? 13.5,
      color: color,
      fontWeight: weight,
      height: height,
      fontStyle: fontStyle,
    );
  }

  static TextStyle ui({double? fontSize, Color? color, FontWeight? weight}) =>
      GoogleFonts.inter(fontSize: fontSize ?? 13, color: color, fontWeight: weight);
}
