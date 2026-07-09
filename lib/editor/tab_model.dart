import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/highlight_core.dart';
import 'package:highlight/languages/all.dart';
import 'package:path/path.dart' as p;

import 'krom_code_controller.dart';

class TabModel {
  TabModel({
    required this.filePath,
    required this.content,
    this.useParser = true,
  }) : label = p.basename(filePath);

  final String filePath;
  final String label;
  String content;
  bool isDirty = false;
  final bool useParser;
  KromCodeController? _codeController;

  KromCodeController get codeController {
    return _codeController ??= KromCodeController(
      text: content,
      language: _languageFromPath(filePath),
      filePath: filePath,
      useParser: useParser,
    );
  }

  void dispose() {
    _codeController?.dispose();
    _codeController = null;
  }

  static Mode? _languageFromPath(String path) {
    final ext = p.extension(path).toLowerCase();
    final key = _extensionToKey[ext];
    if (key == null) return null;
    return allLanguages[key];
  }

  static const _extensionToKey = <String, String>{
    '.dart': 'dart',
    '.py': 'python',
    '.js': 'javascript',
    '.ts': 'typescript',
    '.jsx': 'javascript',
    '.tsx': 'typescript',
    '.go': 'go',
    '.java': 'java',
    '.kt': 'kotlin',
    '.cs': 'cs',
    '.cpp': 'cpp',
    '.c': 'cpp',
    '.h': 'cpp',
    '.html': 'xml',
    '.xml': 'xml',
    '.css': 'css',
    '.scss': 'scss',
    '.json': 'json',
    '.yaml': 'yaml',
    '.yml': 'yaml',
    '.md': 'markdown',
    '.sql': 'sql',
    '.sh': 'bash',
    '.bat': 'dos',
    '.ps1': 'powershell',
    '.rb': 'ruby',
    '.swift': 'swift',
    '.php': 'php',
    '.lua': 'lua',
    '.toml': 'ini',
    '.ini': 'ini',
    '.gradle': 'groovy',
    '.cmake': 'cmake',
    '.rs': 'rust',
  };
}
