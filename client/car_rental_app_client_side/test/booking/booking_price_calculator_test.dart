import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_app_client_side/features/booking/models/booking_flow_state.dart';
import 'package:car_rental_app_client_side/features/booking/models/vehicle_model.dart';
import 'package:car_rental_app_client_side/features/booking/models/coupon_model.dart';
import 'package:car_rental_app_client_side/features/booking/models/driver_model.dart';
import 'package:car_rental_app_client_side/features/booking/utils/booking_price_calculator.dart';

void main() {
  group('BookingPriceCalculator and Duration Tests', () {
    const vehicle = Vehicle(
      id: 'v1',
      name: 'Tesla Model Y',
      imageUrl: '',
      pricePerDay: 120.0,
      specifications: [],
      rating: 4.8,
    );

    const driver = Driver(
      id: 'd1',
      name: 'Marcus Vance',
      rating: 4.9,
      experienceYears: 8,
      languages: ['English'],
      isVerified: true,
      pricePerDay: 25.0,
      imageUrl: '',
    );

    final baseDate = DateTime(2026, 8, 9, 12, 0);

    test('Rental duration calculation - positive days', () {
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(const Duration(days: 3)),
      );
      expect(state.rentalDurationDays, 3);
    });

    test(
      'Rental duration calculation - minimum 1 day on negative/same moment',
      () {
        final stateSame = BookingFlowState(
          vehicle: vehicle,
          pickupDateTime: baseDate,
          returnDateTime: baseDate,
        );
        final stateNegative = BookingFlowState(
          vehicle: vehicle,
          pickupDateTime: baseDate,
          returnDateTime: baseDate.subtract(const Duration(days: 1)),
        );
        expect(stateSame.rentalDurationDays, 1);
        expect(stateNegative.rentalDurationDays, 1);
      },
    );

    test('Rental duration calculation - partial day rounded up', () {
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(const Duration(days: 1, hours: 2)),
      );
      expect(state.rentalDurationDays, 2);
    });

    test('Self drive - driver is null and driver fee is 0', () {
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(const Duration(days: 3)),
        rentalType: RentalType.selfDrive,
        driver: driver, // even if driver is set, self-drive ignores it
      );
      expect(BookingPriceCalculator.calculateDriverFee(state), 0.0);
    });

    test('With driver - driver fee included', () {
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(const Duration(days: 3)),
        rentalType: RentalType.withDriver,
        driver: driver,
      );
      expect(
        BookingPriceCalculator.calculateDriverFee(state),
        75.0,
      ); // 3 days * 25/day
    });

    test('With driver but unselected - driver fee is 0', () {
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(const Duration(days: 3)),
        rentalType: RentalType.withDriver,
        driver: null,
      );
      expect(BookingPriceCalculator.calculateDriverFee(state), 0.0);
    });

    test('Coupon Discount - percentage coupon applied to base charge', () {
      const percentageCoupon = Coupon(
        code: 'DRIVE20',
        discountAmount: 0.0,
        percentage: 20.0,
        minBookingValue: 100.0,
        description: '',
      );
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(const Duration(days: 2)), // 240 subtotal
        coupon: percentageCoupon,
      );
      expect(
        BookingPriceCalculator.calculateDiscount(state),
        48.0,
      ); // 20% of 240
    });

    test('Coupon Discount - flat amount coupon', () {
      const flatCoupon = Coupon(
        code: 'RENTAL50',
        discountAmount: 50.0,
        percentage: 0.0,
        minBookingValue: 250.0,
        description: '',
      );
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(const Duration(days: 3)), // 360 subtotal
        coupon: flatCoupon,
      );
      expect(BookingPriceCalculator.calculateDiscount(state), 50.0);
    });

    test('Grand total includes taxes and security deposit', () {
      final state = BookingFlowState(
        vehicle: vehicle,
        pickupDateTime: baseDate,
        returnDateTime: baseDate.add(
          const Duration(days: 2),
        ), // 240 base rental
        rentalType: RentalType.selfDrive,
      );
      // subtotal: 240.0
      // discount: 0.0
      // tax: 240.0 * 0.18 = 43.2
      // security deposit: 150.0
      // total: 240 + 43.2 + 150 = 433.2
      expect(
        BookingPriceCalculator.calculateGrandTotal(state),
        closeTo(433.2, 0.01),
      );
    });
  });
}
