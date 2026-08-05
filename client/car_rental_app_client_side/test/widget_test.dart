import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_app_client_side/features/booking/models/booking_flow_state.dart';
import 'package:car_rental_app_client_side/features/booking/models/vehicle_model.dart';
import 'package:car_rental_app_client_side/features/booking/models/service_model.dart';
import 'package:car_rental_app_client_side/features/booking/models/coupon_model.dart';
import 'package:car_rental_app_client_side/features/booking/models/driver_model.dart';
import 'package:car_rental_app_client_side/features/booking/utils/booking_price_calculator.dart';

void main() {
  group('BookingPriceCalculator Tests', () {
    final vehicle = const Vehicle(
      id: 'v1',
      name: 'Tesla Model Y',
      imageUrl: '',
      pricePerDay: 120.0,
      specifications: [],
      rating: 4.8,
    );

    final baseDate = DateTime.now();

    test('Calculate base rental charge correctly', () {
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(const Duration(days: 3)),
      );
      expect(BookingPriceCalculator.calculateBaseRentalCharge(state), 360.0);
    });

    test('Calculate driver fee correctly when rental type is selfDrive', () {
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(const Duration(days: 3)),
        rentalType: RentalType.selfDrive,
      );
      expect(BookingPriceCalculator.calculateDriverFee(state), 0.0);
    });

    test('Calculate driver fee correctly when rental type is withDriver', () {
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(const Duration(days: 3)),
        rentalType: RentalType.withDriver,
      );
      expect(BookingPriceCalculator.calculateDriverFee(state), 150.0); // 3 * 50.0
    });

    test('Calculate insurance correctly', () {
      const insuranceService = Service(
        id: 'srv_insurance',
        name: 'Premium Insurance',
        description: '',
        price: 15.0,
        isReoccurring: true,
      );
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(const Duration(days: 3)),
        selectedServices: const [insuranceService],
      );
      expect(BookingPriceCalculator.calculateInsurance(state), 45.0); // 15.0 * 3
    });

    test('Calculate subtotal, tax and grand total correctly', () {
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(const Duration(days: 2)),
        rentalType: RentalType.selfDrive,
      );
      // Base charge: 120 * 2 = 240.0
      // Driver fee: 0.0
      // Insurance: 0.0
      // Subtotal: 240.0
      // Discount: 0.0
      // Taxable: 240.0
      // Tax: 240.0 * 0.18 = 43.2
      // Security Deposit: 150.0
      // Grand Total: 240.0 + 43.2 + 150.0 = 433.2
      expect(BookingPriceCalculator.calculateSubtotal(state), closeTo(240.0, 0.01));
      expect(BookingPriceCalculator.calculateTax(state), closeTo(43.2, 0.01));
      expect(BookingPriceCalculator.calculateGrandTotal(state), closeTo(433.2, 0.01));
    });
  });
}
