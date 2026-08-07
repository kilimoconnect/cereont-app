// Basic smoke test for the Cereont app.

import 'package:flutter_test/flutter_test.dart';

import 'package:cereont/main.dart';

void main() {
  testWidgets('App boots to the command dashboard', (tester) async {
    await tester.pumpWidget(const CereontApp());
    await tester.pumpAndSettle();

    // The bottom navigation and company name should be present.
    expect(find.text('Command'), findsOneWidget);
    expect(find.textContaining('Meridian Trade Co.'), findsWidgets);
  });
}
