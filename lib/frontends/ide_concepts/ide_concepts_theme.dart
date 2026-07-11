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
    required this.indentGuideColors,
    required this.bracketPairColors,
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
  final List<Color> indentGuideColors;
  final List<Color> bracketPairColors;
  static const _gM=[Color(0xFF8B93FF),Color(0xFF6FD3A3),Color(0xFFFFB066),Color(0xFFFF8FC7),Color(0xFF6EA8FF),Color(0xFFFFE066),Color(0xFFF7768E),Color(0xFF7DCFFF)];
  static const _gP=[Color(0xFF5C7A63),Color(0xFF8A6A4A),Color(0xFFB3673A),Color(0xFFC94F8F),Color(0xFF3B6FD6),Color(0xFFB89B1F),Color(0xFFC9772F),Color(0xFF55763E)];
  static const _gT=[Color(0xFF7AA2F7),Color(0xFF9ECE6A),Color(0xFFFF9E64),Color(0xFFF7768E),Color(0xFFBB9AF7),Color(0xFFE0AF68),Color(0xFF7DCFFF),Color(0xFF73DACA)];
  static const _gR=[Color(0xFFC4A7E7),Color(0xFF9CCFD8),Color(0xFFF6C177),Color(0xFFEB6F92),Color(0xFF31748F),Color(0xFFDAC1FF),Color(0xFFEA9A97),Color(0xFF6E6A86)];
  static const _gO=[Color(0xFF7FD8A0),Color(0xFFB0B0FF),Color(0xFFF0C88B),Color(0xFFFF8FC7),Color(0xFF6EA8FF),Color(0xFFFFE066),Color(0xFF9CCFD8),Color(0xFFC4A7E7)];
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
      'dart': Color(0xFF6EA8FF),
      'tsx': Color(0xFF6EA8FF),
      'jsx': Color(0xFF6EA8FF),
      'js': Color(0xFFFFE066),
      'ts': Color(0xFFFFB066),
      'css': Color(0xFFFF8FC7),
      'scss': Color(0xFFFF8FC7),
      'json': Color(0xFFFFE066),
      'yaml': Color(0xFFFFB066),
      'yml': Color(0xFFFFB066),
      'md': Color(0xFF9AA5B1),
      'py': Color(0xFF7FD8A0),
      'rs': Color(0xFFFFB066),
      'go': Color(0xFF6FD3A3),
      'java': Color(0xFFFF8FC7),
      'kt': Color(0xFFFF8FC7),
      'html': Color(0xFFFF8FC7),
      'xml': Color(0xFFFF8FC7),
      'sh': Color(0xFF9AA5B1),
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
    indentGuideColors: _gM,
    bracketPairColors: _gM,
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
      'dart': Color(0xFF3B6FD6),
      'tsx': Color(0xFF3B6FD6),
      'jsx': Color(0xFF3B6FD6),
      'js': Color(0xFFB89B1F),
      'ts': Color(0xFFC9772F),
      'css': Color(0xFFC94F8F),
      'scss': Color(0xFFC94F8F),
      'json': Color(0xFFB89B1F),
      'yaml': Color(0xFFC9772F),
      'yml': Color(0xFFC9772F),
      'md': Color(0xFF7A8087),
      'py': Color(0xFF55763E),
      'rs': Color(0xFFC9772F),
      'go': Color(0xFF5C7A63),
      'java': Color(0xFFC94F8F),
      'kt': Color(0xFFC94F8F),
      'html': Color(0xFFC94F8F),
      'xml': Color(0xFFC94F8F),
      'sh': Color(0xFF7A8087),
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
    indentGuideColors: _gP,
    bracketPairColors: _gP,
  );

  /// Deep blue-violet night palette inspired by Tokyo Night.
  static final tokyoNight = IdeConceptsTheme(
    name: 'Tokyo Night',
    brightness: Brightness.dark,
    editorBg: const Color(0xFF1A1B26),
    topBg: const Color(0xFF1F2335),
    sidebarBg: const Color(0xFF1F2335),
    tabBarBg: const Color(0xFF1F2335),
    panelBg: const Color(0xFF24283B),
    statusBg: const Color(0xFF3D59A1),
    statusText: const Color(0xFFC0CAF5),
    statusAccent: const Color(0xFF9ECE6A),
    hairline: Colors.white.withValues(alpha: 0.06),
    hairlineStrong: Colors.white.withValues(alpha: 0.12),
    veil: const Color(0x801A1B26),
    text: const Color(0xFFC0CAF5),
    muted: const Color(0xFFC0CAF5).withValues(alpha: 0.55),
    lineNum: const Color(0xFF565F89),
    rowActive: const Color(0xFF7AA2F7).withValues(alpha: 0.16),
    rowHover: Colors.white.withValues(alpha: 0.04),
    iconDim: const Color(0xFF565F89),
    accent: const Color(0xFF7AA2F7),
    accent2: const Color(0xFF9ECE6A),
    chromeDot: Colors.white.withValues(alpha: 0.1),
    togglePillBg: Colors.white.withValues(alpha: 0.04),
    fileDots: midnightIndigo.fileDots,
    syntax: const {
      'keyword': Color(0xFFBB9AF7),
      'string': Color(0xFF9ECE6A),
      'comment': Color(0x66565F89),
      'function': Color(0xFF7AA2F7),
      'number': Color(0xFFFF9E64),
      'tag': Color(0xFFF7768E),
      'property': Color(0xFF7DCFFF),
      'plain': Color(0xFFC0CAF5),
      'punc': Color(0x99C0CAF5),
    },
    syntaxItalic: const {'comment'},
    indentGuideColors: _gT,
    bracketPairColors: _gT,
  );

  /// Muted rose palette inspired by Rosé Pine.
  static final rosePine = IdeConceptsTheme(
    name: 'Rosé Pine',
    brightness: Brightness.dark,
    editorBg: const Color(0xFF191724),
    topBg: const Color(0xFF1F1D2E),
    sidebarBg: const Color(0xFF1F1D2E),
    tabBarBg: const Color(0xFF1F1D2E),
    panelBg: const Color(0xFF26233A),
    statusBg: const Color(0xFF524B7A),
    statusText: const Color(0xFFE0DEF4),
    statusAccent: const Color(0xFF9CCFD8),
    hairline: Colors.white.withValues(alpha: 0.06),
    hairlineStrong: Colors.white.withValues(alpha: 0.11),
    veil: const Color(0x80191724),
    text: const Color(0xFFE0DEF4),
    muted: const Color(0xFF908CAA),
    lineNum: const Color(0xFF6E6A86),
    rowActive: const Color(0xFFC4A7E7).withValues(alpha: 0.14),
    rowHover: Colors.white.withValues(alpha: 0.035),
    iconDim: const Color(0xFF6E6A86),
    accent: const Color(0xFFC4A7E7),
    accent2: const Color(0xFF9CCFD8),
    chromeDot: Colors.white.withValues(alpha: 0.1),
    togglePillBg: Colors.white.withValues(alpha: 0.04),
    fileDots: midnightIndigo.fileDots,
    syntax: const {
      'keyword': Color(0xFFEB6F92),
      'string': Color(0xFFF6C177),
      'comment': Color(0x666E6A86),
      'function': Color(0xFF9CCFD8),
      'number': Color(0xFFF6C177),
      'tag': Color(0xFFEB6F92),
      'property': Color(0xFFC4A7E7),
      'plain': Color(0xFFE0DEF4),
      'punc': Color(0x99908CAA),
    },
    syntaxItalic: const {'comment'},
    indentGuideColors: _gR,
    bracketPairColors: _gR,
  );

  /// Pure OLED black for maximum contrast and focus.
  static final obsidian = IdeConceptsTheme(
    name: 'Obsidian',
    brightness: Brightness.dark,
    editorBg: const Color(0xFF0D0D0D),
    topBg: const Color(0xFF141414),
    sidebarBg: const Color(0xFF111111),
    tabBarBg: const Color(0xFF111111),
    panelBg: const Color(0xFF161616),
    statusBg: const Color(0xFF2A2A2A),
    statusText: const Color(0xFFE8E8E8),
    statusAccent: const Color(0xFF7FD8A0),
    hairline: Colors.white.withValues(alpha: 0.07),
    hairlineStrong: Colors.white.withValues(alpha: 0.14),
    veil: const Color(0xCC000000),
    text: const Color(0xFFE8E8E8),
    muted: const Color(0xFF8A8A8A),
    lineNum: const Color(0xFF5A5A5A),
    rowActive: Colors.white.withValues(alpha: 0.08),
    rowHover: Colors.white.withValues(alpha: 0.04),
    iconDim: const Color(0xFF5A5A5A),
    accent: const Color(0xFFE8E8E8),
    accent2: const Color(0xFF7FD8A0),
    chromeDot: Colors.white.withValues(alpha: 0.08),
    togglePillBg: Colors.white.withValues(alpha: 0.04),
    fileDots: midnightIndigo.fileDots,
    syntax: const {
      'keyword': Color(0xFFE8E8E8),
      'string': Color(0xFF7FD8A0),
      'comment': Color(0x665A5A5A),
      'function': Color(0xFFB0B0FF),
      'number': Color(0xFFF0C88B),
      'tag': Color(0xFFE8E8E8),
      'property': Color(0xFFC8C8C8),
      'plain': Color(0xFFE8E8E8),
      'punc': Color(0x998A8A8A),
    },
    syntaxItalic: const {'comment'},
    indentGuideColors: _gO,
    bracketPairColors: _gO,
  );
}
