import 'package:flutter/material.dart';
import 'ide_concepts_theme.dart';

abstract final class ThemeJson {
  static const version = 1;
  static IdeConceptsTheme parse(Map<String, dynamic> json) {
    final base = json['brightness'] == 'light' ? IdeConceptsTheme.paperLight : IdeConceptsTheme.midnightIndigo;
    final chrome = json['chrome'] as Map<String, dynamic>? ?? {};
    final syntax = json['syntax'] as Map<String, dynamic>? ?? {};
    return base.copyWith(
      name: json['name'] as String? ?? 'Custom',
      brightness: json['brightness'] == 'light' ? Brightness.light : Brightness.dark,
      editorBg: _c(chrome['editorBg']) ?? base.editorBg,
      accent: _c(chrome['accent']) ?? base.accent,
      accent2: _c(chrome['accent2']) ?? base.accent2,
      text: _c(chrome['text']) ?? base.text,
      syntax: _syn(syntax, base.syntax),
    );
  }
  static Map<String, dynamic> encode(IdeConceptsTheme t, {String? id}) => {
    'version': version, if (id != null) 'id': id, 'name': t.name,
    'brightness': t.brightness == Brightness.light ? 'light' : 'dark',
    'chrome': {'editorBg': _h(t.editorBg), 'accent': _h(t.accent), 'accent2': _h(t.accent2), 'text': _h(t.text)},
    'syntax': {for (final e in t.syntax.entries) e.key: _h(e.value)},
    'accentVariants': t.resolvedAccentVariants.map(_h).toList(),
  };
  static Color? _c(dynamic v) { if (v is! String) return null; final h = v.replaceFirst('#',''); if (h.length==6) return Color(int.parse('FF$h',radix:16)); if (h.length==8) return Color(int.parse(h,radix:16)); return null; }
  static Map<String,Color> _syn(Map j, Map<String,Color> fb) { final o=Map<String,Color>.from(fb); for (final e in j.entries) { final c=_c(e.value); if (c!=null) o[e.key]=c; } return o; }
  static String _h(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8,'0').substring(2)}';
}
