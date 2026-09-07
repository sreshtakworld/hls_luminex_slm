import 'package:flutter_test/flutter_test.dart';
import 'package:nira/main.dart';

void main() {
  testWidgets('NIRA app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const NiraApp());

    expect(find.text('NIRA'), findsOneWidget);
    expect(find.text('Offline AI Assistant'), findsOneWidget);
  });
}