import 'package:path/path.dart' as p;

/// Human-readable language name for the status bar, keyed by file extension.
String languageLabelForPath(String path) {
  final ext = p.extension(path).toLowerCase();
  return _labels[ext] ??
      (ext.isEmpty ? 'Plain Text' : ext.substring(1).toUpperCase());
}

const _labels = <String, String>{
  '.dart': 'Dart',
  '.py': 'Python',
  '.js': 'JavaScript',
  '.jsx': 'JavaScript React',
  '.ts': 'TypeScript',
  '.tsx': 'TypeScript React',
  '.go': 'Go',
  '.java': 'Java',
  '.kt': 'Kotlin',
  '.cs': 'C#',
  '.cpp': 'C++',
  '.c': 'C',
  '.h': 'C++',
  '.html': 'HTML',
  '.xml': 'XML',
  '.css': 'CSS',
  '.scss': 'SCSS',
  '.json': 'JSON',
  '.yaml': 'YAML',
  '.yml': 'YAML',
  '.md': 'Markdown',
  '.sql': 'SQL',
  '.sh': 'Shell Script',
  '.bat': 'Batch',
  '.ps1': 'PowerShell',
  '.rb': 'Ruby',
  '.swift': 'Swift',
  '.php': 'PHP',
  '.lua': 'Lua',
  '.toml': 'TOML',
  '.ini': 'INI',
  '.gradle': 'Groovy',
  '.cmake': 'CMake',
  '.rs': 'Rust',
};
