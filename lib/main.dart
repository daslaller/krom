import 'package:flutter/material.dart';
import 'frontends/ide_concepts/ide_concepts_page.dart';
import 'frontends/ide_concepts/ide_concepts_theme.dart';
import 'frontends/ide_concepts/ide_concepts_themes.dart';
import 'frontends/ide_concepts/krom_motion.dart';
import 'services/settings_service.dart';
import 'theme/krom_theme.dart';

void main() {
  runApp(const KromApp());
}

class KromApp extends StatefulWidget {
  const KromApp({super.key});

  @override
  State<KromApp> createState() => _KromAppState();
}

class _KromAppState extends State<KromApp> {
  final _settings = SettingsService();
  bool _ready = false;
  String _themeId = IdeConceptsThemes.defaultId;

  @override
  void initState() {
    super.initState();
    _settings.load().then((_) {
      if (!mounted) return;
      setState(() {
        _themeId = IdeConceptsThemes.normalizeId(_settings.themeId);
        _ready = true;
      });
    });
  }

  Future<void> _setThemeId(String themeId) async {
    final normalized = IdeConceptsThemes.normalizeId(themeId);
    setState(() => _themeId = normalized);
    await _settings.setTheme(normalized);
  }

  Future<void> _cycleTheme() async {
    final next = IdeConceptsThemes.nextId(_themeId);
    if (next != null) await _setThemeId(next);
  }

  IdeConceptsTheme get _conceptsTheme => IdeConceptsThemes.resolve(_themeId);

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final conceptsTheme = _conceptsTheme;

    return MaterialApp(
      title: 'Krom',
      debugShowCheckedModeBanner: false,
      theme: KromTheme.fromIdeConcepts(conceptsTheme),
      home: AnimatedTheme(
        duration: KromMotion.themeDuration,
        curve: KromMotion.chromeCurve,
        data: KromTheme.fromIdeConcepts(conceptsTheme),
        child: IdeConceptsPage(
        settings: _settings,
        themeId: _themeId,
        onCycleTheme: _cycleTheme,
        onSetTheme: _setThemeId,
      ),
      ),
    );
  }
}
