import 'package:flutter/material.dart';

import 'ide_concepts_theme.dart';
import 'ide_fonts.dart';

Future<String?> showRenameDialog(
  BuildContext context,
  IdeConceptsTheme theme, {
  String? initialName,
}) {
  final controller = TextEditingController(text: initialName ?? '');
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.panelBg,
        title: Text('Rename Symbol', style: IdeFonts.mono(color: theme.text)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: IdeFonts.mono(color: theme.text),
          cursorColor: theme.accent,
          decoration: InputDecoration(
            hintText: 'New name',
            hintStyle: IdeFonts.mono(color: theme.muted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.hairline),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.accent),
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) Navigator.of(context).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: IdeFonts.mono(color: theme.muted)),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.of(context).pop(value);
            },
            child: Text('Rename', style: IdeFonts.mono(color: theme.accent)),
          ),
        ],
      );
    },
  );
}
