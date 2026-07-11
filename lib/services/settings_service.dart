import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class SettingsService {
  Map<String, dynamic> _global = {};
  Map<String, dynamic> _project = {};
  String? _workspaceRoot;

  Map<String, dynamic> get _data => {..._global, ..._project};

  Future<void> load({String? workspaceRoot}) async {
    _workspaceRoot = workspaceRoot;
    _global = await _read(_settingsFile());
    _project = workspaceRoot != null
        ? await _read(_projectFile(workspaceRoot))
        : {};
  }

  Future<void> loadProjectOverrides(String? workspaceRoot) async {
    _workspaceRoot = workspaceRoot;
    _project = workspaceRoot != null
        ? await _read(_projectFile(workspaceRoot))
        : {};
  }

  List<String> serverCommand(String id) {
    final o = _data['languageServers'] as Map?;
    final c = o?[id];
    if (c is List) return c.cast<String>();
    return _defaults[id] ?? const [];
  }

  List<String> configuredLanguageIds() {
    final ids = <String>{..._defaults.keys};
    final o = _data['languageServers'] as Map?;
    if (o != null) ids.addAll(o.keys.cast<String>());
    return ids.where((id) => serverCommand(id).isNotEmpty).toList();
  }

  List<String> get parserCommand {
    final c = _data['parserCommand'];
    if (c is List) return c.cast<String>();
    return const [];
  }

  bool get useTreeSitter => _data['useTreeSitter'] as bool? ?? true;
  String get themeId => _data['theme'] as String? ?? 'midnight-indigo';
  bool get isDark => themeId != 'paper-light' && themeId != 'light';
  bool get autosave => _data['autosave'] as bool? ?? true;
  bool get themeSyncOs => _data['themeSyncOs'] as bool? ?? false;
  bool get highContrast => _data['highContrast'] as bool? ?? false;
  int get accentIndex => (_data['accentIndex'] as num?)?.toInt() ?? 0;
  double get editorFontSize =>
      (_data['editorFontSize'] as num?)?.toDouble() ?? 13.5;
  double get editorLineHeight =>
      (_data['editorLineHeight'] as num?)?.toDouble() ?? 24 / 13.5;
  double get uiFontSize => (_data['uiFontSize'] as num?)?.toDouble() ?? 13.0;

  String? get anthropicApiKey => _data['anthropicApiKey'] as String?;
  String? get githubToken => _data['githubToken'] as String?;
  bool get hasAnthropicKey {
    final key = anthropicApiKey;
    return key != null && key.isNotEmpty;
  }

  Future<void> setTheme(String theme) async {
    _global['theme'] = theme;
    await _save();
  }

  Future<void> setAutosave(bool enabled) async {
    _global['autosave'] = enabled;
    await _save();
  }

  Future<void> setThemeSyncOs(bool v) async {
    _global['themeSyncOs'] = v;
    await _save();
  }

  Future<void> setHighContrast(bool v) async {
    _global['highContrast'] = v;
    await _save();
  }

  Future<void> setAccentIndex(int i) async {
    _global['accentIndex'] = i.clamp(0, 3);
    await _save();
  }

  Future<void> _save() async {
    final file = _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(_global),
    );
  }

  static Future<Map<String, dynamic>> _read(File f) async {
    if (!f.existsSync()) return {};
    try {
      return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static const _defaults = <String, List<String>>{
    'dart': ['dart', 'language-server', '--protocol=lsp'],
  };

  File _settingsFile() {
    final dir = Platform.isWindows
        ? p.join(Platform.environment['APPDATA'] ?? '', 'Krom')
        : p.join(Platform.environment['HOME'] ?? '', '.config', 'krom');
    return File(p.join(dir, 'settings.json'));
  }

  static File _projectFile(String root) => File(p.join(root, '.krom', 'settings.json'));
}
