import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/analytics_service.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';
import '../models/service_model.dart';
import '../models/coupon_model.dart';
import '../models/booking_step.dart';
import '../models/booking_flow_state.dart';
import '../models/location_model.dart';
import '../services/booking_service.dart';
import '../repositories/booking_repository.dart';
import '../repositories/driver_repository.dart';
import '../utils/booking_price_calculator.dart';
import '../utils/currency_formatter.dart';

// Core Network Providers
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final bookingServiceProvider = Provider<BookingService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MockBookingServiceImpl(apiClient);
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final service = ref.watch(bookingServiceProvider);
  return BookingRepositoryImpl(service);
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return MockDriverRepository();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return MockAnalyticsService();
});

// Future Providers for Lists
final driversListProvider = FutureProvider<List<Driver>>((ref) async {
  final flowState = ref.watch(bookingFlowProvider);
  final driverRepo = ref.watch(driverRepositoryProvider);

  final pickupLoc = flowState.pickupLocation;
  final pickupTime = flowState.pickupDateTime;

  if (pickupLoc == null || pickupTime == null) {
    return const [];
  }

  return driverRepo.getAvailableDrivers(
    pickupLocation: pickupLoc,
    pickupDateTime: pickupTime,
    returnDateTime: flowState.returnDateTime,
  );
});

final servicesListProvider = FutureProvider<List<Service>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getServices();
});

final couponsListProvider = FutureProvider<List<Coupon>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getCoupons();
});

// Unified Booking State Provider
final bookingFlowProvider =
    StateNotifierProvider<BookingFlowNotifier, BookingFlowState>((ref) {
      final repo = ref.watch(bookingRepositoryProvider);
      final analytics = ref.watch(analyticsServiceProvider);
      final driverRepo = ref.watch(driverRepositoryProvider);
      return BookingFlowNotifier(repo, analytics, driverRepo);
    });

class BookingFlowNotifier extends StateNotifier<BookingFlowState> {
  final BookingRepository _repository;
  final AnalyticsService _analytics;
  final DriverRepository _driverRepository;

  BookingFlowNotifier(this._repository, this._analytics, this._driverRepository)
    : super(const BookingFlowState());

  void setVehicle(Vehicle vehicle) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final pickupDefault = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      10,
    );
    final returnDefault = pickupDefault.add(const Duration(days: 3, hours: 8));

    state = state.copyWith(
      vehicle: () => vehicle,
      pickupLocation: () =>
          state.pickupLocation ?? LocationModel.mockLocations[0],
      returnLocation: () =>
          state.returnLocation ?? LocationModel.mockLocations[0],
      pickupDateTime: () => state.pickupDateTime ?? pickupDefault,
      returnDateTime: () => state.returnDateTime ?? returnDefault,
    );
    _analytics.logEvent(
      "vehicle_selected",
      parameters: {"vehicle_id": vehicle.id, "price": vehicle.pricePerDay},
    );
  }

  void setLocations({LocationModel? pickup, LocationModel? returnLoc}) {
    final currentPickup = state.pickupLocation;
    final isPickupChanged = pickup != null && pickup != currentPickup;

    state = state.copyWith(
      pickupLocation: pickup != null ? () => pickup : null,
      returnLocation: returnLoc != null ? () => returnLoc : null,
      driver: isPickupChanged ? () => null : null,
    );
  }

  void setDateTimes({DateTime? pickup, DateTime? returnDT}) {
    final nextPickup = pickup ?? state.pickupDateTime;
    final nextReturn = returnDT ?? state.returnDateTime;

    state = state.copyWith(
      pickupDateTime: pickup != null ? () => pickup : null,
      returnDateTime: returnDT != null ? () => returnDT : null,
    );

    // If a driver is currently selected, check if they are still available at the new time
    if (state.driver != null &&
        state.pickupLocation != null &&
        nextPickup != null) {
      _checkSelectedDriverAvailability(
        state.pickupLocation!,
        nextPickup,
        nextReturn,
      );
    }
  }

  Future<void> _checkSelectedDriverAvailability(
    LocationModel location,
    DateTime pickup,
    DateTime? returnDT,
  ) async {
    final available = await _driverRepository.getAvailableDrivers(
      pickupLocation: location,
      pickupDateTime: pickup,
      returnDateTime: returnDT,
    );
    final currentDriver = state.driver;
    if (currentDriver != null) {
      final isStillAvailable = available.any((d) => d.id == currentDriver.id);
      if (!isStillAvailable) {
        state = state.copyWith(
          driver: () => null,
          errorMessage: () =>
              "Your selected driver is no longer available for this time.",
        );
      }
    }
  }

  void clearErrorMessage() {
    state = state.copyWith(errorMessage: () => null);
  }

  void setRentalType(RentalType type) {
    if (type == RentalType.selfDrive) {
      // Clear driver if toggled to self-drive
      state = state.copyWith(rentalType: type, driver: () => null);
    } else {
      state = state.copyWith(rentalType: type);
    }
    _analytics.logEvent(
      "rental_type_changed",
      parameters: {"type": type.toString()},
    );
  }

  void selectDriver(Driver? driver) {
    state = state.copyWith(driver: () => driver);
    if (driver != null) {
      _analytics.logEvent(
        "driver_selected",
        parameters: {"driver_id": driver.id},
      );
    }
  }

  void toggleService(Service service) {
    final currentServices = List<Service>.from(state.selectedServices);
    if (currentServices.contains(service)) {
      currentServices.remove(service);
      _analytics.logEvent(
        "service_removed",
        parameters: {"service_id": service.id},
      );
    } else {
      currentServices.add(service);
      _analytics.logEvent(
        "service_added",
        parameters: {"service_id": service.id},
      );
    }
    state = state.copyWith(selectedServices: currentServices);
  }

  Future<bool> applyCoupon(String code) async {
    if (code.trim().isEmpty) {
      state = state.copyWith(errorMessage: () => null);
      return false;
    }
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final baseRental = BookingPriceCalculator.calculateBaseRentalCharge(
        state,
      );
      final coupons = await _repository.getCoupons();
      Coupon? matchedCoupon;
      for (final c in coupons) {
        if (c.code.toUpperCase() == code.trim().toUpperCase()) {
          matchedCoupon = c;
          break;
        }
      }

      state = state.copyWith(isLoading: false);
      if (matchedCoupon == null) {
        state = state.copyWith(errorMessage: () => "Invalid coupon code");
        return false;
      }

      if (baseRental < matchedCoupon.minBookingValue) {
        state = state.copyWith(
          errorMessage: () =>
              "Not Eligible: Min booking of ${formatCurrency(matchedCoupon!.minBookingValue)} required",
        );
        return false;
      }

      state = state.copyWith(coupon: () => matchedCoupon);
      _analytics.logEvent(
        "coupon_applied",
        parameters: {"code": code, "discount": matchedCoupon.discountAmount},
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => "Error verifying coupon",
      );
      return false;
    }
  }

  void removeCoupon() {
    state = state.copyWith(coupon: () => null);
    _analytics.logEvent("coupon_removed");
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: () => method);
    _analytics.logEvent(
      "payment_method_selected",
      parameters: {"method": method.toString()},
    );
  }

  void setStep(BookingStep step) {
    state = state.copyWith(currentStep: step);
    _analytics.logScreenView(step.label);
  }

  void nextStep() {
    final nextIndex = state.currentStep.index + 1;
    if (nextIndex < BookingStep.values.length) {
      setStep(BookingStep.values[nextIndex]);
    }
  }

  void prevStep() {
    final prevIndex = state.currentStep.index - 1;
    if (prevIndex >= 0) {
      setStep(BookingStep.values[prevIndex]);
    }
  }

  Future<bool> submitBooking() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    _analytics.logEvent("booking_submit_started");
    try {
      final bookingId = await _repository.createBooking(state);
      state = state.copyWith(
        isLoading: false,
        bookingId: () => bookingId,
        currentStep: BookingStep.success,
      );
      _analytics.logEvent(
        "booking_submit_completed",
        parameters: {"booking_id": bookingId},
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const BookingFlowState();
    _analytics.logEvent("booking_flow_reset");
  }
}
