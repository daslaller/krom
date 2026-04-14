import 'package:flutter_test/flutter_test.dart';
import 'package:krom/main.dart';

void main() {
  testWidgets('App boots without error', (tester) async {
    await tester.pumpWidget(const KromApp());
    expect(find.text('Krom'), findsOneWidget);
  });
}
