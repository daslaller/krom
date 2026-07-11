import 'package:flutter/material.dart';

import 'ide_concepts_theme.dart';
import 'ide_fonts.dart';

Future<bool?> showExternalChangeDialog(
  BuildContext context,
  IdeConceptsTheme theme,
  String relativePath,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.panelBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.hairline),
      ),
      title: Text('File changed on disk', style: IdeFonts.mono(color: theme.text, fontSize: 14)),
      content: Text(
        '$relativePath was modified outside Krom. Reload from disk?',
        style: IdeFonts.mono(color: theme.muted, fontSize: 12),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Keep editor', style: IdeFonts.mono(color: theme.muted, fontSize: 12)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Reload', style: IdeFonts.mono(color: theme.accent, fontSize: 12)),
        ),
      ],
    ),
  );
}
