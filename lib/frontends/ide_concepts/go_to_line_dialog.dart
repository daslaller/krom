import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ide_concepts_theme.dart';
import 'ide_fonts.dart';

Future<int?> showGoToLineDialog(
  BuildContext context,
  IdeConceptsTheme theme, {
  int currentLine = 1,
}) {
  final controller = TextEditingController(text: '$currentLine');
  return showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.panelBg,
        title: Text('Go to Line', style: IdeFonts.mono(color: theme.text)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: IdeFonts.mono(color: theme.text),
          cursorColor: theme.accent,
          decoration: InputDecoration(
            hintText: 'Line number',
            hintStyle: IdeFonts.mono(color: theme.muted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.hairline),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.accent),
            ),
          ),
          onSubmitted: (value) {
            final line = int.tryParse(value);
            if (line != null && line > 0) {
              Navigator.of(context).pop(line - 1);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: IdeFonts.mono(color: theme.muted)),
          ),
          TextButton(
            onPressed: () {
              final line = int.tryParse(controller.text);
              if (line != null && line > 0) {
                Navigator.of(context).pop(line - 1);
              }
            },
            child: Text('Go', style: IdeFonts.mono(color: theme.accent)),
          ),
        ],
      );
    },
  );
}
