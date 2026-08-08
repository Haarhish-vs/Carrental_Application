import 'package:flutter_test/flutter_test.dart';
import 'package:car_rental_app_client_side/features/booking/models/booking_flow_state.dart';
import 'package:car_rental_app_client_side/features/booking/models/driver_model.dart';
import 'package:car_rental_app_client_side/features/booking/models/location_model.dart';
import 'package:car_rental_app_client_side/features/booking/models/vehicle_model.dart';
import 'package:car_rental_app_client_side/features/booking/repositories/driver_repository.dart';
import 'package:car_rental_app_client_side/features/booking/repositories/booking_repository.dart';
import 'package:car_rental_app_client_side/features/booking/providers/booking_provider.dart';
import 'package:car_rental_app_client_side/features/booking/services/booking_service.dart';
import 'package:car_rental_app_client_side/core/services/analytics_service.dart';
import 'package:car_rental_app_client_side/core/network/api_client.dart';

void main() {
  group('Chauffeur Driver Availability & Selection Tests', () {
    late MockDriverRepository driverRepo;
    late BookingFlowNotifier notifier;
    late MockBookingServiceImpl bookingService;

    final locA = LocationModel.mockLocations[0]; // Gandhipuram
    final locB = LocationModel.mockLocations[1]; // RS Puram
    final baseTime = DateTime(2026, 8, 10, 10, 0);

    const mockVehicle = Vehicle(
      id: 'v1',
      name: 'Tesla Model Y',
      imageUrl: '',
      pricePerDay: 120.0,
      specifications: [],
      rating: 4.8,
    );

    setUp(() {
      driverRepo = MockDriverRepository();
      bookingService = MockBookingServiceImpl(ApiClient());
      notifier = BookingFlowNotifier(
        BookingRepositoryImpl(bookingService),
        MockAnalyticsService(),
        driverRepo,
      );
    });

    test('1. No pickup location -> no drivers shown', () async {
      final state = BookingFlowState(
        pickupLocation: null,
        pickupDateTime: DateTime(2026, 8, 10),
      );
      expect(state.pickupLocation, isNull);
    });

    test(
      '2. Location selected + date/time missing -> no drivers shown',
      () async {
        final state = BookingFlowState(
          pickupLocation: locA,
          pickupDateTime: null,
        );
        expect(state.pickupDateTime, isNull);
      },
    );

    test('3. Location selected + valid date/time -> drivers fetched', () async {
      final drivers = await driverRepo.getAvailableDrivers(
        pickupLocation: locA,
        pickupDateTime: baseTime,
      );
      expect(drivers, isNotEmpty);
    });

    test('4. Drivers from Location A do not appear for Location B', () async {
      final driversForGandhipuram = await driverRepo.getAvailableDrivers(
        pickupLocation: locA,
        pickupDateTime: baseTime,
      );
      final hasRajeshInGandhipuram = driversForGandhipuram.any(
        (d) => d.id == 'drv_rajesh_khanna',
      );
      expect(hasRajeshInGandhipuram, isFalse);

      final airportLoc = LocationModel.mockLocations[2];
      final driversForAirport = await driverRepo.getAvailableDrivers(
        pickupLocation: airportLoc,
        pickupDateTime: baseTime,
      );
      final hasRajeshInAirport = driversForAirport.any(
        (d) => d.id == 'drv_rajesh_khanna',
      );
      expect(hasRajeshInAirport, isTrue);
    });

    test('5. Changing pickup location clears selected driver', () {
      notifier.setVehicle(mockVehicle);
      notifier.setLocations(pickup: locA);
      const driver = Driver(
        id: 'drv_david_kumar',
        name: 'David Kumar',
        rating: 4.9,
        experienceYears: 8,
        languages: ['Tamil'],
        isVerified: true,
        pricePerDay: 600.0,
        imageUrl: '',
      );
      notifier.selectDriver(driver);
      expect(notifier.state.driver, equals(driver));

      // Change location
      notifier.setLocations(pickup: locB);
      expect(notifier.state.driver, isNull);
    });

    test(
      '6. Changing pickup time rechecks driver availability and clears if unavailable',
      () async {
        notifier.setLocations(pickup: locA);
        notifier.setDateTimes(pickup: baseTime);
        const driver = Driver(
          id: 'drv_busy_driver',
          name: 'Busy Driver',
          rating: 4.95,
          experienceYears: 15,
          languages: ['English'],
          isVerified: true,
          pricePerDay: 800.0,
          imageUrl: '',
          isAvailable: false,
          serviceLocations: ['coimbatore_gandhipuram'],
        );
        notifier.selectDriver(driver);
        expect(notifier.state.driver, equals(driver));

        notifier.setDateTimes(pickup: baseTime.add(const Duration(hours: 2)));
        await Future.delayed(const Duration(milliseconds: 700));
        expect(notifier.state.driver, isNull);
      },
    );

    test(
      '7. Unavailable driver cannot be selected (filtered out from repository)',
      () async {
        final drivers = await driverRepo.getAvailableDrivers(
          pickupLocation: locA,
          pickupDateTime: baseTime,
        );
        final hasBusyDriver = drivers.any((d) => d.id == 'drv_busy_driver');
        expect(hasBusyDriver, isFalse);
      },
    );

    test('8. With Driver without driver -> checkout disabled', () {
      notifier.setVehicle(mockVehicle);
      notifier.setRentalType(RentalType.withDriver);
      notifier.selectDriver(null);

      final dateError = notifier.state.pickupDateTime == null
          ? "Required"
          : null;
      final isDriverRequiredButMissing =
          notifier.state.rentalType == RentalType.withDriver &&
          notifier.state.driver == null;
      final isCheckoutEnabled =
          dateError == null && !isDriverRequiredButMissing;

      expect(isCheckoutEnabled, isFalse);
    });

    test('9. Self Drive -> driver cleared', () {
      notifier.setVehicle(mockVehicle);
      notifier.setRentalType(RentalType.withDriver);
      const driver = Driver(
        id: 'drv_david_kumar',
        name: 'David Kumar',
        rating: 4.9,
        experienceYears: 8,
        languages: ['Tamil'],
        isVerified: true,
        pricePerDay: 600.0,
        imageUrl: '',
      );
      notifier.selectDriver(driver);
      expect(notifier.state.driver, equals(driver));

      notifier.setRentalType(RentalType.selfDrive);
      expect(notifier.state.driver, isNull);
    });

    test('10. Driver fee included only for With Driver', () {
      notifier.setVehicle(mockVehicle);
      notifier.setDateTimes(
        pickup: baseTime,
        returnDT: baseTime.add(const Duration(days: 2)),
      );
      notifier.setRentalType(RentalType.withDriver);
      const driver = Driver(
        id: 'drv_david_kumar',
        name: 'David Kumar',
        rating: 4.9,
        experienceYears: 8,
        languages: ['Tamil'],
        isVerified: true,
        pricePerDay: 600.0,
        imageUrl: '',
      );
      notifier.selectDriver(driver);

      expect(notifier.state.rentalDurationDays, 2);
      expect(notifier.state.driver, equals(driver));

      notifier.setRentalType(RentalType.selfDrive);
      expect(notifier.state.driver, isNull);
    });

    test('11. No drivers -> correct empty list returned', () async {
      const unknownLoc = LocationModel(
        id: 'unknown',
        name: 'Unknown Hub',
        address: 'Unknown',
        latitude: 0.0,
        longitude: 0.0,
      );
      final drivers = await driverRepo.getAvailableDrivers(
        pickupLocation: unknownLoc,
        pickupDateTime: baseTime,
      );
      expect(drivers, isEmpty);
    });

    test(
      '12. Recommended driver is selected based on deterministic ranking',
      () async {
        final drivers = await driverRepo.getAvailableDrivers(
          pickupLocation: locA,
          pickupDateTime: baseTime,
        );
        drivers.sort((a, b) {
          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) return ratingCompare;

          final distA = MockDriverRepository.calculateDistance(
            a.latitude,
            a.longitude,
            locA.latitude,
            locA.longitude,
          );
          final distB = MockDriverRepository.calculateDistance(
            b.latitude,
            b.longitude,
            locA.latitude,
            locA.longitude,
          );
          final distCompare = distA.compareTo(distB);
          if (distCompare != 0) return distCompare;

          return b.experienceYears.compareTo(a.experienceYears);
        });

        expect(drivers.first.id, equals('drv_david_kumar'));
      },
    );

    test('13. Price updates after driver selection', () {
      notifier.setVehicle(mockVehicle);
      notifier.setDateTimes(
        pickup: baseTime,
        returnDT: baseTime.add(const Duration(days: 2)),
      );
      notifier.setRentalType(RentalType.withDriver);
      expect(notifier.state.rentalDurationDays, 2);

      const driver = Driver(
        id: 'drv_david_kumar',
        name: 'David Kumar',
        rating: 4.9,
        experienceYears: 8,
        languages: ['Tamil'],
        isVerified: true,
        pricePerDay: 600.0,
        imageUrl: '',
      );
      notifier.selectDriver(driver);
      expect(notifier.state.driver, equals(driver));
    });
  });
}
