import 'dart:convert'; import 'dart:io'; import 'package:path/path.dart' as p;
class SettingsService {
  Map<String,dynamic> _global={}; Map<String,dynamic> _project={}; String? _workspaceRoot;
  Map<String,dynamic> get _data => {..._global,..._project};
  Future<void> load({String? workspaceRoot}) async { _workspaceRoot=workspaceRoot; _global=await _read(_settingsFile()); _project=workspaceRoot!=null?await _read(_projectFile(workspaceRoot)):{}; }
  Future<void> loadProjectOverrides(String? workspaceRoot) async { _workspaceRoot=workspaceRoot; _project=workspaceRoot!=null?await _read(_projectFile(workspaceRoot)):{}; }
  List<String> serverCommand(String id){ final o=_data['languageServers'] as Map?; final c=o?[id]; if(c is List) return c.cast<String>(); return _defaults[id]??const[]; }
  List<String> configuredLanguageIds(){ final ids=<String>{..._defaults.keys}; final o=_data['languageServers'] as Map?; if(o!=null) ids.addAll(o.keys.cast<String>()); return ids.where(serverCommand).toList(); }
  List<String> get parserCommand{ final c=_data['parserCommand']; if(c is List) return c.cast<String>(); return const[]; }
  bool get useTreeSitter => _data['useTreeSitter'] as bool? ?? true;
  String get themeId => _data['theme'] as String? ?? 'midnight-indigo';
  bool get isDark => themeId!='paper-light'&&themeId!='light';
  bool get autosave => _data['autosave'] as bool? ?? true;
  Future<void> setTheme(String t) async { _global['theme']=t; await _save(); }
  Future<void> setAutosave(bool e) async { _global['autosave']=e; await _save(); }
  Future<void> _save() async { final f=_settingsFile(); await f.parent.create(recursive:true); await f.writeAsString(const JsonEncoder.withIndent('  ').convert(_global)); }
  static Future<Map<String,dynamic>> _read(File f) async { if(!f.existsSync()) return {}; try{return jsonDecode(f.readAsStringSync()) as Map<String,dynamic>;}catch(_){return{};} }
  static const _defaults=<String,List<String>>{'dart':['dart','language-server','--protocol=lsp']};
  File _settingsFile(){ final d=Platform.isWindows?p.join(Platform.environment['APPDATA']??'','Krom'):p.join(Platform.environment['HOME']??'','.config','krom'); return File(p.join(d,'settings.json')); }
  static File _projectFile(String r)=>File(p.join(r,'.krom','settings.json'));
}
