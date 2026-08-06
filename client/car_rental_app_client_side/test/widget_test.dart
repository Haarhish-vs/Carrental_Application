import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_app_client_side/main.dart';
import 'package:car_rental_app_client_side/features/home/presentation/screens/home_screen.dart';

class _MockHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _MockHttpOverrides();

  testWidgets('App renders Car Rental Home Screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(minutes: 5));

    // Verify that the Home Screen widget renders cleanly
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
