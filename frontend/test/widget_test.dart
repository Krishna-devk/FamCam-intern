import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app.dart';

void main() {
  testWidgets('FamCareApp boots successfully and displays home dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame inside ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: FamCareApp(),
      ),
    );

    // Verify that our app renders and Home Screen elements are found
    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('Arjun Mehta'), findsOneWidget);
  });
}
