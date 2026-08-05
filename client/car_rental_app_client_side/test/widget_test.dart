import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_app_client_side/main.dart';

void main() {
  testWidgets('App renders Car Rental Home Screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the title and action button exist
    expect(find.text('Earn by Renting Your Car'), findsOneWidget);
    expect(find.text('Rent Out'), findsOneWidget);
  });
}
