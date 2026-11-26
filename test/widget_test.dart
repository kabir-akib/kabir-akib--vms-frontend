import 'package:flutter_test/flutter_test.dart';
import 'package:vms_frontend/main.dart';

void main() {
  testWidgets('Stark Group VMS application smoke test - loads login screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VmsApp());
    await tester.pumpAndSettle();

    // Verify that the login screen title and brand header render.
    expect(find.text('Fleet Admin Sign In'), findsOneWidget);
    expect(find.text('STARK GROUP'), findsOneWidget);
  });
}
