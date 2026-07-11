import 'package:flutter/material.dart';

/// Design tokens for the "IDE Concepts" frontend, ported 1:1 from the
/// Claude Design mockup (Midnight Indigo / Paper Light variants).
@immutable
class IdeConceptsTheme {
  const IdeConceptsTheme({
    required this.name,
    required this.brightness,
    this.accentVariants = const [],
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
  final List<Color> accentVariants;

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


  List<Color> get resolvedAccentVariants {
    if (accentVariants.length >= 4) return accentVariants.take(4).toList();
    return [accent, accent2, Color.lerp(accent, accent2, 0.5) ?? accent,
      brightness == Brightness.dark ? Color.lerp(accent, Colors.white, 0.35)! : Color.lerp(accent, Colors.black, 0.25)!];
  }
  IdeConceptsTheme withAccentIndex(int index) {
    final pick = resolvedAccentVariants[index.clamp(0, 3)];
    return copyWith(accent: pick, rowActive: pick.withValues(alpha: brightness == Brightness.dark ? 0.18 : 0.12), statusAccent: pick);
  }
  IdeConceptsTheme toHighContrast() {
    final d = brightness == Brightness.dark;
    return copyWith(
      editorBg: d ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      topBg: d ? const Color(0xFF0A0A0A) : const Color(0xFFF0F0F0),
      sidebarBg: d ? const Color(0xFF050505) : const Color(0xFFF5F5F5),
      tabBarBg: d ? const Color(0xFF050505) : const Color(0xFFF5F5F5),
      panelBg: d ? const Color(0xFF101010) : const Color(0xFFFAFAFA),
      text: d ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      muted: d ? const Color(0xFFCCCCCC) : const Color(0xFF333333),
      lineNum: d ? const Color(0xFFAAAAAA) : const Color(0xFF555555),
      hairline: d ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
      hairlineStrong: d ? Colors.white.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.35),
      syntax: {for (final e in syntax.entries) e.key: d ? Color.lerp(e.value, Colors.white, 0.25)! : Color.lerp(e.value, Colors.black, 0.2)!},
    );
  }
  IdeConceptsTheme copyWith({String? name, Brightness? brightness, Color? editorBg, Color? topBg, Color? sidebarBg, Color? tabBarBg, Color? panelBg, Color? statusBg, Color? statusText, Color? statusAccent, Color? hairline, Color? hairlineStrong, Color? veil, Color? text, Color? muted, Color? lineNum, Color? rowActive, Color? rowHover, Color? iconDim, Color? accent, Color? accent2, Color? chromeDot, Color? togglePillBg, Map<String, Color>? fileDots, Map<String, Color>? syntax, Set<String>? syntaxItalic, List<Color>? accentVariants}) {
    return IdeConceptsTheme(name: name ?? this.name, brightness: brightness ?? this.brightness, accentVariants: accentVariants ?? this.accentVariants, editorBg: editorBg ?? this.editorBg, topBg: topBg ?? this.topBg, sidebarBg: sidebarBg ?? this.sidebarBg, tabBarBg: tabBarBg ?? this.tabBarBg, panelBg: panelBg ?? this.panelBg, statusBg: statusBg ?? this.statusBg, statusText: statusText ?? this.statusText, statusAccent: statusAccent ?? this.statusAccent, hairline: hairline ?? this.hairline, hairlineStrong: hairlineStrong ?? this.hairlineStrong, veil: veil ?? this.veil, text: text ?? this.text, muted: muted ?? this.muted, lineNum: lineNum ?? this.lineNum, rowActive: rowActive ?? this.rowActive, rowHover: rowHover ?? this.rowHover, iconDim: iconDim ?? this.iconDim, accent: accent ?? this.accent, accent2: accent2 ?? this.accent2, chromeDot: chromeDot ?? this.chromeDot, togglePillBg: togglePillBg ?? this.togglePillBg, fileDots: fileDots ?? this.fileDots, syntax: syntax ?? this.syntax, syntaxItalic: syntaxItalic ?? this.syntaxItalic);
  }

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
  );

  static final dracula = IdeConceptsTheme(name: 'Dracula', brightness: Brightness.dark, editorBg: Color(0xFF282A36), topBg: Color(0xFF2D2F3D), sidebarBg: Color(0xFF2D2F3D), tabBarBg: Color(0xFF2D2F3D), panelBg: Color(0xFF343746), statusBg: Color(0xFF6272A4), statusText: Color(0xFFF8F8F2), statusAccent: Color(0xFF50FA7B), hairline: Colors.white.withValues(alpha: 0.07), hairlineStrong: Colors.white.withValues(alpha: 0.14), veil: Color(0x80282A36), text: Color(0xFFF8F8F2), muted: Color(0xFF6272A4), lineNum: Color(0xFF6272A4), rowActive: Color(0xFFBD93F9).withValues(alpha: 0.16), rowHover: Colors.white.withValues(alpha: 0.04), iconDim: Color(0xFF6272A4), accent: Color(0xFFBD93F9), accent2: Color(0xFF50FA7B), chromeDot: Colors.white.withValues(alpha: 0.1), togglePillBg: Colors.white.withValues(alpha: 0.04), fileDots: midnightIndigo.fileDots, syntax: {'keyword': Color(0xFFFF79C6), 'string': Color(0xFFF1FA8C), 'comment': Color(0xFF6272A4), 'function': Color(0xFF50FA7B), 'number': Color(0xFFBD93F9), 'tag': Color(0xFFFF79C6), 'property': Color(0xFF8BE9FD), 'plain': Color(0xFFF8F8F2), 'punc': Color(0x99F8F8F2)}, syntaxItalic: {'comment'}, accentVariants: [Color(0xFFBD93F9), Color(0xFF50FA7B), Color(0xFFFF79C6), Color(0xFF8BE9FD)]);
  static final nord = IdeConceptsTheme(name: 'Nord', brightness: Brightness.dark, editorBg: Color(0xFF2E3440), topBg: Color(0xFF3B4252), sidebarBg: Color(0xFF3B4252), tabBarBg: Color(0xFF3B4252), panelBg: Color(0xFF434C5E), statusBg: Color(0xFF5E81AC), statusText: Color(0xFFECEFF4), statusAccent: Color(0xFFA3BE8C), hairline: Colors.white.withValues(alpha: 0.06), hairlineStrong: Colors.white.withValues(alpha: 0.12), veil: Color(0x802E3440), text: Color(0xFFECEFF4), muted: Color(0xFF81A1C1), lineNum: Color(0xFF4C566A), rowActive: Color(0xFF88C0D0).withValues(alpha: 0.14), rowHover: Colors.white.withValues(alpha: 0.04), iconDim: Color(0xFF4C566A), accent: Color(0xFF88C0D0), accent2: Color(0xFFA3BE8C), chromeDot: Colors.white.withValues(alpha: 0.1), togglePillBg: Colors.white.withValues(alpha: 0.04), fileDots: midnightIndigo.fileDots, syntax: {'keyword': Color(0xFF81A1C1), 'string': Color(0xFFA3BE8C), 'comment': Color(0xFF616E88), 'function': Color(0xFF88C0D0), 'number': Color(0xFFB48EAD), 'tag': Color(0xFF81A1C1), 'property': Color(0xFFD8DEE9), 'plain': Color(0xFFECEFF4), 'punc': Color(0x99D8DEE9)}, syntaxItalic: {'comment'}, accentVariants: [Color(0xFF88C0D0), Color(0xFFA3BE8C), Color(0xFF5E81AC), Color(0xFFB48EAD)]);
  static final catppuccinMocha = IdeConceptsTheme(name: 'Catppuccin Mocha', brightness: Brightness.dark, editorBg: Color(0xFF1E1E2E), topBg: Color(0xFF181825), sidebarBg: Color(0xFF181825), tabBarBg: Color(0xFF181825), panelBg: Color(0xFF313244), statusBg: Color(0xFF45475A), statusText: Color(0xFFCDD6F4), statusAccent: Color(0xFFA6E3A1), hairline: Colors.white.withValues(alpha: 0.06), hairlineStrong: Colors.white.withValues(alpha: 0.12), veil: Color(0x801E1E2E), text: Color(0xFFCDD6F4), muted: Color(0xFF6C7086), lineNum: Color(0xFF6C7086), rowActive: Color(0xFF89B4FA).withValues(alpha: 0.14), rowHover: Colors.white.withValues(alpha: 0.04), iconDim: Color(0xFF6C7086), accent: Color(0xFF89B4FA), accent2: Color(0xFFA6E3A1), chromeDot: Colors.white.withValues(alpha: 0.1), togglePillBg: Colors.white.withValues(alpha: 0.04), fileDots: midnightIndigo.fileDots, syntax: {'keyword': Color(0xFF89B4FA), 'string': Color(0xFFA6E3A1), 'comment': Color(0xFF6C7086), 'function': Color(0xFFF9E2AF), 'number': Color(0xFFFAB387), 'tag': Color(0xFFF38BA8), 'property': Color(0xFF94E2D5), 'plain': Color(0xFFCDD6F4), 'punc': Color(0x99CDD6F4)}, syntaxItalic: {'comment'}, accentVariants: [Color(0xFF89B4FA), Color(0xFFA6E3A1), Color(0xFFF38BA8), Color(0xFFF9E2AF)]);
  static final solarizedDark = IdeConceptsTheme(name: 'Solarized Dark', brightness: Brightness.dark, editorBg: Color(0xFF002B36), topBg: Color(0xFF073642), sidebarBg: Color(0xFF073642), tabBarBg: Color(0xFF073642), panelBg: Color(0xFF073642), statusBg: Color(0xFF268BD2), statusText: Color(0xFFEEE8D5), statusAccent: Color(0xFF2AA198), hairline: Colors.white.withValues(alpha: 0.06), hairlineStrong: Colors.white.withValues(alpha: 0.12), veil: Color(0x80002B36), text: Color(0xFFEEE8D5), muted: Color(0xFF93A1A1), lineNum: Color(0xFF586E75), rowActive: Color(0xFF268BD2).withValues(alpha: 0.16), rowHover: Colors.white.withValues(alpha: 0.04), iconDim: Color(0xFF586E75), accent: Color(0xFF268BD2), accent2: Color(0xFF2AA198), chromeDot: Colors.white.withValues(alpha: 0.1), togglePillBg: Colors.white.withValues(alpha: 0.04), fileDots: midnightIndigo.fileDots, syntax: {'keyword': Color(0xFF859900), 'string': Color(0xFF2AA198), 'comment': Color(0xFF586E75), 'function': Color(0xFF268BD2), 'number': Color(0xFFD33682), 'tag': Color(0xFFCB4B16), 'property': Color(0xFF93A1A1), 'plain': Color(0xFFEEE8D5), 'punc': Color(0x9986A1A1)}, syntaxItalic: {'comment'}, accentVariants: [Color(0xFF268BD2), Color(0xFF2AA198), Color(0xFF859900), Color(0xFFD33682)]);
  static final gruvboxDark = IdeConceptsTheme(name: 'Gruvbox Dark', brightness: Brightness.dark, editorBg: Color(0xFF282828), topBg: Color(0xFF32302F), sidebarBg: Color(0xFF32302F), tabBarBg: Color(0xFF32302F), panelBg: Color(0xFF3C3836), statusBg: Color(0xFF504945), statusText: Color(0xFFEBDBB2), statusAccent: Color(0xFFB8BB26), hairline: Colors.white.withValues(alpha: 0.06), hairlineStrong: Colors.white.withValues(alpha: 0.12), veil: Color(0x80282828), text: Color(0xFFEBDBB2), muted: Color(0xFFA89984), lineNum: Color(0xFF928374), rowActive: Color(0xFFFE8019).withValues(alpha: 0.14), rowHover: Colors.white.withValues(alpha: 0.04), iconDim: Color(0xFF928374), accent: Color(0xFFFE8019), accent2: Color(0xFFB8BB26), chromeDot: Colors.white.withValues(alpha: 0.1), togglePillBg: Colors.white.withValues(alpha: 0.04), fileDots: midnightIndigo.fileDots, syntax: {'keyword': Color(0xFFFB4934), 'string': Color(0xFFB8BB26), 'comment': Color(0xFF928374), 'function': Color(0xFF83A598), 'number': Color(0xFFD3869B), 'tag': Color(0xFFFE8019), 'property': Color(0xFFEBDBB2), 'plain': Color(0xFFEBDBB2), 'punc': Color(0x99A89984)}, syntaxItalic: {'comment'}, accentVariants: [Color(0xFFFE8019), Color(0xFFB8BB26), Color(0xFF83A598), Color(0xFFD3869B)]);
  static final oneDark = IdeConceptsTheme(name: 'One Dark', brightness: Brightness.dark, editorBg: Color(0xFF282C34), topBg: Color(0xFF21252B), sidebarBg: Color(0xFF21252B), tabBarBg: Color(0xFF21252B), panelBg: Color(0xFF2C313A), statusBg: Color(0xFF3E4451), statusText: Color(0xFFABB2BF), statusAccent: Color(0xFF98C379), hairline: Colors.white.withValues(alpha: 0.06), hairlineStrong: Colors.white.withValues(alpha: 0.12), veil: Color(0x80282C34), text: Color(0xFFABB2BF), muted: Color(0xFF5C6370), lineNum: Color(0xFF4B5263), rowActive: Color(0xFF61AFEF).withValues(alpha: 0.14), rowHover: Colors.white.withValues(alpha: 0.04), iconDim: Color(0xFF4B5263), accent: Color(0xFF61AFEF), accent2: Color(0xFF98C379), chromeDot: Colors.white.withValues(alpha: 0.1), togglePillBg: Colors.white.withValues(alpha: 0.04), fileDots: midnightIndigo.fileDots, syntax: {'keyword': Color(0xFFC678DD), 'string': Color(0xFF98C379), 'comment': Color(0xFF5C6370), 'function': Color(0xFF61AFEF), 'number': Color(0xFFD19A66), 'tag': Color(0xFFE06C75), 'property': Color(0xFFE5C07B), 'plain': Color(0xFFABB2BF), 'punc': Color(0x99ABB2BF)}, syntaxItalic: {'comment'}, accentVariants: [Color(0xFF61AFEF), Color(0xFF98C379), Color(0xFFC678DD), Color(0xFFE06C75)]);
  static final monokai = IdeConceptsTheme(name: 'Monokai', brightness: Brightness.dark, editorBg: Color(0xFF272822), topBg: Color(0xFF2D2E27), sidebarBg: Color(0xFF2D2E27), tabBarBg: Color(0xFF2D2E27), panelBg: Color(0xFF3E3D32), statusBg: Color(0xFF49483E), statusText: Color(0xFFF8F8F2), statusAccent: Color(0xFFA6E22E), hairline: Colors.white.withValues(alpha: 0.06), hairlineStrong: Colors.white.withValues(alpha: 0.12), veil: Color(0x80272822), text: Color(0xFFF8F8F2), muted: Color(0xFF75715E), lineNum: Color(0xFF75715E), rowActive: Color(0xFF66D9EF).withValues(alpha: 0.14), rowHover: Colors.white.withValues(alpha: 0.04), iconDim: Color(0xFF75715E), accent: Color(0xFF66D9EF), accent2: Color(0xFFA6E22E), chromeDot: Colors.white.withValues(alpha: 0.1), togglePillBg: Colors.white.withValues(alpha: 0.04), fileDots: midnightIndigo.fileDots, syntax: {'keyword': Color(0xFFF92672), 'string': Color(0xFFE6DB74), 'comment': Color(0xFF75715E), 'function': Color(0xFFA6E22E), 'number': Color(0xFFAE81FF), 'tag': Color(0xFFF92672), 'property': Color(0xFF66D9EF), 'plain': Color(0xFFF8F8F2), 'punc': Color(0x99F8F8F2)}, syntaxItalic: {'comment'}, accentVariants: [Color(0xFF66D9EF), Color(0xFFA6E22E), Color(0xFFF92672), Color(0xFFAE81FF)]);
  static final ayuMirage = IdeConceptsTheme(name: 'Ayu Mirage', brightness: Brightness.dark, editorBg: Color(0xFF1F2430), topBg: Color(0xFF232834), sidebarBg: Color(0xFF232834), tabBarBg: Color(0xFF232834), panelBg: Color(0xFF2A303C), statusBg: Color(0xFF3D424D), statusText: Color(0xFFD9D7CE), statusAccent: Color(0xFFBAE67E), hairline: Colors.white.withValues(alpha: 0.06), hairlineStrong: Colors.white.withValues(alpha: 0.12), veil: Color(0x801F2430), text: Color(0xFFD9D7CE), muted: Color(0xFF5C6773), lineNum: Color(0xFF5C6773), rowActive: Color(0xFF73D0FF).withValues(alpha: 0.14), rowHover: Colors.white.withValues(alpha: 0.04), iconDim: Color(0xFF5C6773), accent: Color(0xFF73D0FF), accent2: Color(0xFFBAE67E), chromeDot: Colors.white.withValues(alpha: 0.1), togglePillBg: Colors.white.withValues(alpha: 0.04), fileDots: midnightIndigo.fileDots, syntax: {'keyword': Color(0xFFFFAD66), 'string': Color(0xFFBAE67E), 'comment': Color(0xFF5C6773), 'function': Color(0xFF73D0FF), 'number': Color(0xFFD4BFFF), 'tag': Color(0xFFF28779), 'property': Color(0xFF95E6CB), 'plain': Color(0xFFD9D7CE), 'punc': Color(0x99D9D7CE)}, syntaxItalic: {'comment'}, accentVariants: [Color(0xFF73D0FF), Color(0xFFBAE67E), Color(0xFFFFAD66), Color(0xFFF28779)]);
  static final solarizedLight = IdeConceptsTheme(name: 'Solarized Light', brightness: Brightness.light, editorBg: Color(0xFFFDF6E3), topBg: Color(0xFFEEE8D5), sidebarBg: Color(0xFFEEE8D5), tabBarBg: Color(0xFFEEE8D5), panelBg: Color(0xFFEEE8D5), statusBg: Color(0xFF268BD2), statusText: Color(0xFFFDF6E3), statusAccent: Color(0xFF2AA198), hairline: Colors.black.withValues(alpha: 0.07), hairlineStrong: Colors.black.withValues(alpha: 0.14), veil: Color(0x4D002B36), text: Color(0xFF657B83), muted: Color(0xFF93A1A1), lineNum: Color(0xFF93A1A1), rowActive: Color(0xFF268BD2).withValues(alpha: 0.1), rowHover: Colors.black.withValues(alpha: 0.035), iconDim: Color(0xFF93A1A1), accent: Color(0xFF268BD2), accent2: Color(0xFF2AA198), chromeDot: Colors.black.withValues(alpha: 0.12), togglePillBg: Colors.black.withValues(alpha: 0.03), fileDots: paperLight.fileDots, syntax: {'keyword': Color(0xFF859900), 'string': Color(0xFF2AA198), 'comment': Color(0xFF93A1A1), 'function': Color(0xFF268BD2), 'number': Color(0xFFD33682), 'tag': Color(0xFFCB4B16), 'property': Color(0xFF657B83), 'plain': Color(0xFF657B83), 'punc': Color(0x8C657B83)}, syntaxItalic: {'comment'}, accentVariants: [Color(0xFF268BD2), Color(0xFF2AA198), Color(0xFF859900), Color(0xFFD33682)]);

}
