import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Loads Krom settings from a JSON file in the OS config directory.
///
/// Location:
///   Windows: %APPDATA%\Krom\settings.json
///   Linux/macOS: ~/.config/krom/settings.json
///
/// Keys (all optional):
///   githubToken        — GitHub personal access token (Phase 4)
///   anthropicApiKey    — Anthropic API key (Phase 4)
///   languageServers    — Map of languageId → command list (overrides defaults)
///   parserCommand      — Command to spawn krom-parser, e.g.
///                        ["/path/to/krom-parser", "--plugin-dir", "/path/to/plugins"]
///   useTreeSitter      — Use krom-parser for syntax highlighting (default true)
class SettingsService {
  Map<String, dynamic> _data = {};

  Future<void> load() async {
    final file = _settingsFile();
    if (file.existsSync()) {
      try {
        _data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      } catch (_) {
        // Corrupt settings file — use defaults.
      }
    }
  }

  /// Returns the server command for [languageId], falling back to built-in defaults.
  List<String> serverCommand(String languageId) {
    final overrides = _data['languageServers'] as Map?;
    final cmd = overrides?[languageId];
    if (cmd is List) return cmd.cast<String>();
    return _defaults[languageId] ?? const [];
  }

  /// All language IDs with a configured server command.
  List<String> configuredLanguageIds() {
    final ids = <String>{..._defaults.keys};
    final overrides = _data['languageServers'] as Map?;
    if (overrides != null) {
      ids.addAll(overrides.keys.cast<String>());
    }
    return ids.where((id) => serverCommand(id).isNotEmpty).toList();
  }

  /// Command to spawn the krom-parser daemon.
  List<String> get parserCommand {
    final cmd = _data['parserCommand'];
    if (cmd is List) return cmd.cast<String>();
    return const [];
  }

  /// Whether to prefer krom-parser over highlight.js for syntax highlighting.
  bool get useTreeSitter => _data['useTreeSitter'] as bool? ?? true;

  static const _defaults = <String, List<String>>{
    'dart': ['dart', 'language-server', '--protocol=lsp'],
    // Configure additional servers in settings.json, e.g.:
    // 'python': ['pyright-langserver', '--stdio'],
    // 'typescript': ['typescript-language-server', '--stdio'],
  };

  File _settingsFile() {
    final dir = Platform.isWindows
        ? p.join(Platform.environment['APPDATA'] ?? '', 'Krom')
        : p.join(Platform.environment['HOME'] ?? '', '.config', 'krom');
    return File(p.join(dir, 'settings.json'));
  }
}
