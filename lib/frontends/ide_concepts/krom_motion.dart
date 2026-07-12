import 'package:flutter/animation.dart';

/// Unified motion tokens for the IDE Concepts shell.
///
/// Use these durations/curves everywhere so panels, palette, and chrome feel
/// like one physical interface.
abstract final class KromMotion {
  static const panelDuration = Duration(milliseconds: 320);
  static const chromeDuration = Duration(milliseconds: 280);
  static const hoverDuration = Duration(milliseconds: 120);
  static const paletteDuration = Duration(milliseconds: 220);
  static const themeDuration = Duration(milliseconds: 280);
  static const saveFlashDuration = Duration(milliseconds: 200);
  static const goToDefPulseDuration = Duration(milliseconds: 1200);
  static const paletteStaggerDelay = Duration(milliseconds: 30);

  static const panelCurve = Curves.easeOutCubic;
  static const chromeCurve = Curves.easeOutCubic;
  static const paletteCurve = Curves.easeOutBack;
  static const hoverCurve = Curves.easeOut;
}
