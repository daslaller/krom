import 'package:flutter/material.dart';
import 'frontends/ide_concepts/ide_concepts_page.dart';
import 'theme/krom_theme.dart';

// This branch (frontend/ide-concepts) swaps Krom's home screen for the
// "IDE Concepts" frontend so it can be tried out and compared against
// other frontend candidates before one is picked as the default. See
// lib/frontends/ide_concepts/ for the implementation.
void main() {
  runApp(const KromApp());
}

class KromApp extends StatelessWidget {
  const KromApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krom — IDE Concepts',
      debugShowCheckedModeBanner: false,
      theme: KromTheme.dark(),
      home: const IdeConceptsPage(),
    );
  }
}
