import 'ide_concepts_theme.dart';

/// Catalog of built-in IDE Concepts themes, keyed by stable id for persistence.
abstract final class IdeConceptsThemes {
  static const defaultId = 'midnight-indigo';

  static final _catalog = <String, IdeConceptsTheme>{
    'midnight-indigo': IdeConceptsTheme.midnightIndigo,
    'paper-light': IdeConceptsTheme.paperLight,
    'tokyo-night': IdeConceptsTheme.tokyoNight,
    'rose-pine': IdeConceptsTheme.rosePine,
    'obsidian': IdeConceptsTheme.obsidian,
  };

  static IdeConceptsTheme resolve(String? id) =>
      _catalog[id] ?? IdeConceptsTheme.midnightIndigo;

  static String normalizeId(String? id) {
    if (id == null || id.isEmpty) return defaultId;
    // Legacy settings used `dark` / `light`.
    return switch (id) {
      'dark' => 'midnight-indigo',
      'light' => 'paper-light',
      _ when _catalog.containsKey(id) => id,
      _ => defaultId,
    };
  }

  static List<IdeConceptsThemeEntry> get all => _catalog.entries
      .map((e) => IdeConceptsThemeEntry(id: e.key, theme: e.value))
      .toList();

  static String? nextId(String currentId) {
    final ids = _catalog.keys.toList();
    final idx = ids.indexOf(normalizeId(currentId));
    if (idx < 0) return ids.first;
    return ids[(idx + 1) % ids.length];
  }
}

class IdeConceptsThemeEntry {
  const IdeConceptsThemeEntry({required this.id, required this.theme});

  final String id;
  final IdeConceptsTheme theme;
}
