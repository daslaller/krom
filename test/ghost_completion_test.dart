import 'package:flutter_test/flutter_test.dart';
import 'package:krom/services/ghost_completion_service.dart';

void main() {
  test('heuristicSuffix completes word from file tokens', () {
    const text = 'controller\n  cont';
    expect(
      GhostCompletionService.heuristicSuffix(text, text.length),
      'roller',
    );
  });

  test('heuristicSuffix returns null for short prefix', () {
    expect(GhostCompletionService.heuristicSuffix('final a = 1;', 6), isNull);
  });
}
