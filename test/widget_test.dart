import 'package:flutter_test/flutter_test.dart';
import 'package:khidma/main.dart';

void main() {
  testWidgets('KhidmaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KhidmaApp());
    expect(find.byType(KhidmaApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
