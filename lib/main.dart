import 'package:flutter/material.dart';
import 'frontends/ide_concepts/ide_concepts_page.dart';
import 'theme/krom_theme.dart';

void main() {
  runApp(const KromApp());
}

class KromApp extends StatelessWidget {
  const KromApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krom',
      debugShowCheckedModeBanner: false,
      theme: KromTheme.dark(),
      home: const IdeConceptsPage(),
    );
  }
}
