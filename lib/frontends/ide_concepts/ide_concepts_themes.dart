import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'ide_concepts_theme.dart';
import 'theme_json.dart';

abstract final class IdeConceptsThemes {
  static const defaultId = 'midnight-indigo';
  static final Map<String, IdeConceptsTheme> _builtIn = {
    'midnight-indigo': IdeConceptsTheme.midnightIndigo,
    'paper-light': IdeConceptsTheme.paperLight,
    'tokyo-night': IdeConceptsTheme.tokyoNight,
    'rose-pine': IdeConceptsTheme.rosePine,
    'obsidian': IdeConceptsTheme.obsidian,
    'dracula': IdeConceptsTheme.dracula,
    'nord': IdeConceptsTheme.nord,
    'catppuccin-mocha': IdeConceptsTheme.catppuccinMocha,
    'solarized-dark': IdeConceptsTheme.solarizedDark,
    'solarized-light': IdeConceptsTheme.solarizedLight,
    'gruvbox-dark': IdeConceptsTheme.gruvboxDark,
    'one-dark': IdeConceptsTheme.oneDark,
    'monokai': IdeConceptsTheme.monokai,
    'ayu-mirage': IdeConceptsTheme.ayuMirage,
  };
  static final Map<String, IdeConceptsTheme> _user = {};
  static Map<String, IdeConceptsTheme> get _catalog => {..._builtIn, ..._user};

  static Directory themesDirectory() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    if (Platform.isWindows) return Directory(p.join(Platform.environment['APPDATA'] ?? home, 'Krom', 'themes'));
    return Directory(p.join(home, '.config', 'krom', 'themes'));
  }

  static void loadUserThemes() {
    _user.clear();
    final dir = themesDirectory();
    if (!dir.existsSync()) return;
    for (final e in dir.listSync()) {
      if (e is! File || !e.path.endsWith('.json')) continue;
      try {
        final json = jsonDecode(e.readAsStringSync()) as Map<String, dynamic>;
        _user[json['id'] as String? ?? p.basenameWithoutExtension(e.path)] = ThemeJson.parse(json);
      } catch (_) {}
    }
  }

  static IdeConceptsTheme resolve(String? id) => _catalog[normalizeId(id)] ?? IdeConceptsTheme.midnightIndigo;

  static IdeConceptsTheme resolveWithOptions({required String themeId, required int accentIndex, required bool highContrast, required bool syncOs, required Brightness platformBrightness}) {
    var base = _catalog[normalizeId(themeId)] ?? IdeConceptsTheme.midnightIndigo;
    if (syncOs) {
      if (platformBrightness == Brightness.light && base.brightness == Brightness.dark) base = IdeConceptsTheme.paperLight;
      else if (platformBrightness == Brightness.dark && base.brightness == Brightness.light) base = IdeConceptsTheme.midnightIndigo;
    }
    var t = base.withAccentIndex(accentIndex);
    if (highContrast) t = t.toHighContrast();
    return t;
  }

  static String normalizeId(String? id) {
    if (id == null || id.isEmpty) return defaultId;
    return switch (id) { 'dark' => 'midnight-indigo', 'light' => 'paper-light', _ when _catalog.containsKey(id) => id, _ => defaultId };
  }

  static List<IdeConceptsThemeEntry> get all => _catalog.entries.map((e) => IdeConceptsThemeEntry(id: e.key, theme: e.value)).toList()..sort((a, b) => a.theme.name.compareTo(b.theme.name));
  static String? nextId(String id) { final ids = all.map((e) => e.id).toList(); final i = ids.indexOf(normalizeId(id)); return ids[(i + 1) % ids.length]; }
  static String exportJson(IdeConceptsTheme t, {String? id}) => const JsonEncoder.withIndent('  ').convert(ThemeJson.encode(t, id: id));
  static Future<String?> importThemeFile(String path) async {
    final f = File(path); if (!f.existsSync()) return null;
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final id = json['id'] as String? ?? p.basenameWithoutExtension(path);
    final dir = themesDirectory(); await dir.create(recursive: true);
    await File(p.join(dir.path, '$id.json')).writeAsString(f.readAsStringSync());
    loadUserThemes(); return id;
  }
}

class IdeConceptsThemeEntry { const IdeConceptsThemeEntry({required this.id, required this.theme}); final String id; final IdeConceptsTheme theme; }
