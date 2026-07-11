import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krom/frontends/ide_concepts/ide_concepts_theme.dart';
import 'package:krom/frontends/ide_concepts/theme_json.dart';

void main() {
  test('ThemeJson round-trip preserves name and accent', () {
    const original = IdeConceptsTheme.midnightIndigo;
    final json = ThemeJson.encode(original, id: 'midnight-indigo');
    final parsed = ThemeJson.parse(json);
    expect(parsed.name, original.name);
    expect(parsed.accent, original.accent);
    expect(parsed.brightness, original.brightness);
  });

  test('ThemeJson parse custom brightness', () {
    final parsed = ThemeJson.parse({
      'name': 'Test',
      'brightness': 'light',
      'chrome': {'accent': '#FF0000'},
    });
    expect(parsed.brightness, Brightness.light);
    expect(parsed.accent, const Color(0xFFFF0000));
  });
}
