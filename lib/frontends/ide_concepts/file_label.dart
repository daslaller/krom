import 'package:path/path.dart' as p;

/// Splits a filename into base + extension for consistent coloring in tabs
/// and the file tree.
class FileLabelParts {
  const FileLabelParts({
    required this.base,
    required this.ext,
    required this.extKey,
  });

  final String base;
  final String ext;
  final String? extKey;

  static FileLabelParts fromFileName(String name) {
    final ext = p.extension(name);
    if (ext.isEmpty) {
      return FileLabelParts(base: name, ext: '', extKey: null);
    }
    return FileLabelParts(
      base: name.substring(0, name.length - ext.length),
      ext: ext,
      extKey: ext.substring(1).toLowerCase(),
    );
  }

  /// Short tag for sidebar rows (e.g. `dart`, `tsx`).
  String get tag => extKey ?? '';
}
