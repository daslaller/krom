import 'package:flutter/material.dart';
import 'frontends/ide_concepts/ide_concepts_page.dart';
import 'frontends/ide_concepts/ide_concepts_theme.dart';
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
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _settings.load().then((_) {
      if (!mounted) return;
      setState(() {
        _isDark = _settings.isDark;
        _ready = true;
      });
    });
  }

  Future<void> _toggleTheme() async {
    setState(() => _isDark = !_isDark);
    await _settings.setTheme(_isDark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final conceptsTheme =
        _isDark ? IdeConceptsTheme.midnightIndigo : IdeConceptsTheme.paperLight;

    return MaterialApp(
      title: 'Krom',
      debugShowCheckedModeBanner: false,
      theme: KromTheme.fromIdeConcepts(conceptsTheme),
      home: IdeConceptsPage(
        settings: _settings,
        isDark: _isDark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
