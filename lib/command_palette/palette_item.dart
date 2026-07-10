sealed class PaletteItem {
  const PaletteItem({
    required this.label,
    required this.hint,
    required this.score,
  });

  final String label;
  final String hint;
  final int score;
}

class PaletteCommandItem extends PaletteItem {
  const PaletteCommandItem({
    required this.id,
    required super.label,
    required super.hint,
    super.score = 1000,
  });

  final String id;
}

class PaletteFileItem extends PaletteItem {
  const PaletteFileItem({
    required this.path,
    required super.label,
    required super.hint,
    required super.score,
  });

  final String path;
}
