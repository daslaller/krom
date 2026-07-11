import 'package:flutter/material.dart';
import 'frontends/ide_concepts/ide_concepts_page.dart';
import 'frontends/ide_concepts/ide_concepts_theme.dart';
import 'frontends/ide_concepts/ide_concepts_themes.dart';
import 'frontends/ide_concepts/krom_motion.dart';
import 'services/settings_service.dart';
import 'theme/krom_theme.dart';

void main() => runApp(const KromApp());

class KromApp extends StatefulWidget {
  const KromApp({super.key});
  @override State<KromApp> createState() => _KromAppState();
}

class _KromAppState extends State<KromApp> {
  final _settings = SettingsService();
  bool _ready = false;
  String _themeId = IdeConceptsThemes.defaultId;
  Brightness _platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (mounted) setState(() => _platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness);
    };
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = null;
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _settings.load();
    IdeConceptsThemes.loadUserThemes();
    if (!mounted) return;
    setState(() {
      _themeId = IdeConceptsThemes.normalizeId(_settings.themeId);
      _platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _ready = true;
    });
  }

  IdeConceptsTheme get _theme => IdeConceptsThemes.resolveWithOptions(
    themeId: _themeId, accentIndex: _settings.accentIndex, highContrast: _settings.highContrast,
    syncOs: _settings.themeSyncOs, platformBrightness: _platformBrightness);

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    final t = _theme; final ui = _settings.uiFontSize;
    return MaterialApp(
      title: 'Krom', debugShowCheckedModeBanner: false,
      theme: KromTheme.fromIdeConcepts(t, uiFontSize: ui),
      home: AnimatedTheme(
        duration: KromMotion.themeDuration, curve: KromMotion.chromeCurve,
        data: KromTheme.fromIdeConcepts(t, uiFontSize: ui),
        child: IdeConceptsPage(
          settings: _settings, themeId: _themeId, theme: t,
          onCycleTheme: () async {
            final n = IdeConceptsThemes.nextId(_themeId);
            if (n == null) return;
            setState(() => _themeId = n);
            await _settings.setTheme(n);
          },
          onSetTheme: (id) async { setState(() => _themeId = IdeConceptsThemes.normalizeId(id)); await _settings.setTheme(_themeId); },
          onSetAccentIndex: (i) async { setState(() {}); await _settings.setAccentIndex(i); },
          onSetHighContrast: (v) async { setState(() {}); await _settings.setHighContrast(v); },
          onSetThemeSyncOs: (v) async { setState(() {}); await _settings.setThemeSyncOs(v); },
          onReloadThemes: () async { IdeConceptsThemes.loadUserThemes(); setState(() {}); },
        ),
      ),
    );
  }
}
