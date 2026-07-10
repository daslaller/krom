import 'package:flutter/material.dart';

/// Design tokens for the "IDE Concepts" frontend, ported 1:1 from the
/// Claude Design mockup (Midnight Indigo / Paper Light variants).
@immutable
class IdeConceptsTheme {
  const IdeConceptsTheme({
    required this.name,
    required this.brightness,
    required this.editorBg,
    required this.topBg,
    required this.sidebarBg,
    required this.tabBarBg,
    required this.panelBg,
    required this.statusBg,
    required this.statusText,
    required this.statusAccent,
    required this.hairline,
    required this.hairlineStrong,
    required this.veil,
    required this.text,
    required this.muted,
    required this.lineNum,
    required this.rowActive,
    required this.rowHover,
    required this.iconDim,
    required this.accent,
    required this.accent2,
    required this.chromeDot,
    required this.togglePillBg,
    required this.fileDots,
    required this.syntax,
    required this.syntaxItalic,
  });

  final String name;
  final Brightness brightness;

  final Color editorBg;
  final Color topBg;
  final Color sidebarBg;
  final Color tabBarBg;
  final Color panelBg;
  final Color statusBg;
  final Color statusText;
  final Color statusAccent;
  final Color hairline;
  final Color hairlineStrong;
  final Color veil;
  final Color text;
  final Color muted;
  final Color lineNum;
  final Color rowActive;
  final Color rowHover;
  final Color iconDim;
  final Color accent;
  final Color accent2;

  /// The three faint decorative dots in the title bar.
  final Color chromeDot;
  final Color togglePillBg;

  /// File-extension → color, so a given extension always reads the same
  /// color everywhere (sidebar dot + extension text).
  final Map<String, Color> fileDots;

  /// Syntax token kind → color (keys mirror highlight.js / tree-sitter
  /// capture names used throughout Krom's highlighting pipeline).
  final Map<String, Color> syntax;

  /// Token kinds rendered in italic (e.g. comments).
  final Set<String> syntaxItalic;

  Color colorForExtension(String? ext) {
    if (ext == null || ext.isEmpty) return accent;
    return fileDots[ext.toLowerCase()] ?? accent;
  }

  static final midnightIndigo = IdeConceptsTheme(
    name: 'Midnight Indigo',
    brightness: Brightness.dark,
    editorBg: const Color(0xFF1B1C22),
    topBg: const Color(0xFF202128),
    sidebarBg: const Color(0xFF1E1F26),
    tabBarBg: const Color(0xFF1E1F26),
    panelBg: const Color(0xFF22232B),
    statusBg: const Color(0xFF2A2B78),
    statusText: const Color(0xFFDCDCF5),
    statusAccent: const Color(0xFF6FD3A3),
    hairline: Colors.white.withValues(alpha: 0.06),
    hairlineStrong: Colors.white.withValues(alpha: 0.12),
    veil: const Color(0x8008080E),
    text: const Color(0xFFEEEEF4),
    muted: const Color(0xFFEEEEF4).withValues(alpha: 0.62),
    lineNum: const Color(0xFFEEEEF4).withValues(alpha: 0.4),
    rowActive: const Color(0xFF8B93FF).withValues(alpha: 0.14),
    rowHover: Colors.white.withValues(alpha: 0.04),
    iconDim: const Color(0xFFEEEEF4).withValues(alpha: 0.4),
    accent: const Color(0xFF8B93FF),
    accent2: const Color(0xFF6FD3A3),
    chromeDot: Colors.white.withValues(alpha: 0.12),
    togglePillBg: Colors.white.withValues(alpha: 0.04),
    fileDots: const {
      'tsx': Color(0xFF6EA8FF),
      'css': Color(0xFFFF8FC7),
      'ts': Color(0xFFFFB066),
      'json': Color(0xFFFFE066),
      'md': Color(0xFF9AA5B1),
    },
    syntax: const {
      'keyword': Color(0xFF8B93FF),
      'string': Color(0xFF7FD8A0),
      'comment': Color(0x6AEEEEF4), // ~0.42 alpha
      'function': Color(0xFFA7B4FF),
      'number': Color(0xFFF0C88B),
      'tag': Color(0xFF8B93FF),
      'property': Color(0xFFC9CDF5),
      'plain': Color(0xFFDADBE4),
      'punc': Color(0x99EEEEF4), // ~0.6 alpha
    },
    syntaxItalic: const {'comment'},
  );

  static final paperLight = IdeConceptsTheme(
    name: 'Paper Light',
    brightness: Brightness.light,
    editorBg: const Color(0xFFFBFAF6),
    topBg: const Color(0xFFF3F1EA),
    sidebarBg: const Color(0xFFF3F1EA),
    tabBarBg: const Color(0xFFF3F1EA),
    panelBg: const Color(0xFFF7F5EF),
    statusBg: const Color(0xFF5C7A63),
    statusText: const Color(0xFFF3F7F2),
    statusAccent: const Color(0xFFE8FFE0),
    hairline: Colors.black.withValues(alpha: 0.07),
    hairlineStrong: Colors.black.withValues(alpha: 0.14),
    veil: const Color(0x4D282620),
    text: const Color(0xFF2B2A25),
    muted: const Color(0xFF2B2A25).withValues(alpha: 0.45),
    lineNum: const Color(0xFF2B2A25).withValues(alpha: 0.28),
    rowActive: const Color(0xFF5C7A63).withValues(alpha: 0.08),
    rowHover: Colors.black.withValues(alpha: 0.035),
    iconDim: const Color(0xFF2B2A25).withValues(alpha: 0.22),
    accent: const Color(0xFF5C7A63),
    accent2: const Color(0xFFC99A5B),
    chromeDot: Colors.black.withValues(alpha: 0.12),
    togglePillBg: Colors.black.withValues(alpha: 0.03),
    fileDots: const {
      'tsx': Color(0xFF3B6FD6),
      'css': Color(0xFFC94F8F),
      'ts': Color(0xFFC9772F),
      'json': Color(0xFFB89B1F),
      'md': Color(0xFF7A8087),
    },
    syntax: const {
      'keyword': Color(0xFF5C7A63),
      'string': Color(0xFF8A6A4A),
      'comment': Color(0x662B2A25), // ~0.4 alpha
      'function': Color(0xFF2B2A25),
      'number': Color(0xFFB3673A),
      'tag': Color(0xFF5C7A63),
      'property': Color(0xFF4A4940),
      'plain': Color(0xFF2B2A25),
      'punc': Color(0x8C2B2A25), // ~0.55 alpha
    },
    syntaxItalic: const {'comment'},
  );
}
