import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_app_client_side/features/owner/presentation/screens/rent_car/car_spefication.dart';
import 'package:car_rental_app_client_side/features/owner/presentation/screens/rent_car/rent_car_shared.dart';
import 'package:car_rental_app_client_side/features/owner/data/models/vehicle_model.dart';

void main() {
  group('Rent Out Your Car Flow Tests', () {
    testWidgets('Step 1: Car Specification form validation and navigation', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        const MaterialApp(home: CarSpecificationScreen()),
      );

      // Verify header and initial step
      expect(find.text('Car Specifications'), findsWidgets);
      expect(find.text('Vehicle Identity'), findsOneWidget);

      // Try tapping Next without filling required fields
      final nextButton = find.widgetWithText(FilledButton, 'Next');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pump();

      // Expect validation error messages to be displayed
      expect(find.text('Enter brand'), findsOneWidget);
      expect(find.text('Enter model'), findsOneWidget);

      // Fill in required fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Brand'),
        'Toyota',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Model'),
        'Camry',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Variant'),
        'SE 2.5L',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Manufacturing Year'),
        '2023',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Registration Number'),
        'KA-05-MN-9988',
      );

      // Select Dropdowns
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Fuel Type'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Petrol').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Transmission'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Automatic').last);
      await tester.pumpAndSettle();

      // Fill numerical fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mileage'),
        '16.5',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Seating Capacity'),
        '5',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Color'),
        'Black',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Engine Capacity'),
        '2500',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Odometer Reading'),
        '15000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Well maintained family car.',
      );

      // Tap Next to navigate to Step 2
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Verify Navigation to Step 2: Pricing & Availability
      expect(find.text('Pricing & Availability'), findsWidgets);
      expect(find.text('Pricing'), findsOneWidget);
    });

    test(
      'VehicleModel.fromDraft maps fields correctly for backend submission',
      () {
        const draft = RentCarDraft(
          brand: 'Honda',
          model: 'Civic',
          variant: 'ZX',
          manufacturingYear: '2022',
          registrationNumber: 'MH-12-AB-1234',
          fuelType: 'Petrol',
          transmission: 'CVT',
          mileage: '17.5',
          seatingCapacity: '5',
          color: 'White',
          engineCapacity: '1800',
          odometerReading: '25000',
          vehicleDescription: 'Great condition car.',
          dailyPrice: '3500',
          securityDeposit: '15000',
          minimumRentalDays: '2',
          pickupLocation: 'Main Street, Mumbai',
          availabilityFrom: '2026-08-10',
          availabilityTo: '2026-08-20',
          deliveryFee: '400',
          selectedPhotos: [
            'https://example.com/front.jpg',
            'https://example.com/rear.jpg',
          ],
        );

        final payload = VehicleModel.fromDraft(draft);

        expect(payload['brand'], 'Honda');
        expect(payload['model'], 'Civic');
        expect(payload['manufacturingYear'], 2022);
        expect(payload['rc_number'], 'MH-12-AB-1234');
        expect(payload['city'], 'Mumbai');
        expect(payload['dailyPrice'], 3500.0);
        expect(payload['selectedPhotos'], hasLength(2));
      },
    );
  });
}
