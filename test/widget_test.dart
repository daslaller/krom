import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krom/main.dart';

void main() {
  testWidgets('App boots and shows empty-state actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const KromApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Open File'), findsOneWidget);
    expect(find.text('Toggle Sidebar'), findsOneWidget);
    expect(find.text('Toggle Outline'), findsOneWidget);
  });
}
