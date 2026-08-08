import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_app_client_side/features/booking/models/booking_step.dart';
import 'package:car_rental_app_client_side/features/booking/widgets/timeline/booking_progress_indicator.dart';

void main() {
  testWidgets('BookingProgressIndicator renders successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BookingProgressIndicator(currentStep: BookingStep.vehicle),
        ),
      ),
    );

    // Verify indicator elements exist
    expect(find.byType(BookingProgressIndicator), findsOneWidget);
    expect(find.text('Vehicle'), findsOneWidget);
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Extras'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
  });
}
