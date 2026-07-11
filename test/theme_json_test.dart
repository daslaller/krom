import 'package:flutter_test/flutter_test.dart';
import 'package:krom/frontends/ide_concepts/ide_concepts_theme.dart';
import 'package:krom/frontends/ide_concepts/theme_json.dart';

void main() {
  test('ThemeJson round-trip', () {
    final parsed = ThemeJson.parse(ThemeJson.encode(IdeConceptsTheme.midnightIndigo, id: 'x'));
    expect(parsed.name, IdeConceptsTheme.midnightIndigo.name);
    expect(parsed.accent, IdeConceptsTheme.midnightIndigo.accent);
  });
}
