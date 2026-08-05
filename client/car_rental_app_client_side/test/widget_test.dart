import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_app_client_side/main.dart';

void main() {
  testWidgets('App loads home screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the app launches successfully.
    expect(find.byType(MyApp), findsOneWidget);
  });
}
