import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/analytics_service.dart';
import '../models/vehicle_model.dart';
import '../models/driver_model.dart';
import '../models/service_model.dart';
import '../models/coupon_model.dart';
import '../models/booking_step.dart';
import '../models/booking_flow_state.dart';
import '../services/booking_service.dart';
import '../repositories/booking_repository.dart';
import '../utils/booking_price_calculator.dart';

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

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return MockAnalyticsService();
});

// Future Providers for Lists
final driversListProvider = FutureProvider<List<Driver>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getDrivers();
});

final servicesListProvider = FutureProvider<List<Service>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getServices();
});

// Unified Booking State Provider
final bookingFlowProvider = StateNotifierProvider<BookingFlowNotifier, BookingFlowState>((ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return BookingFlowNotifier(repo, analytics);
});

class BookingFlowNotifier extends StateNotifier<BookingFlowState> {
  final BookingRepository _repository;
  final AnalyticsService _analytics;

  BookingFlowNotifier(this._repository, this._analytics) : super(const BookingFlowState());

  void setVehicle(Vehicle vehicle) {
    state = state.copyWith(vehicle: () => vehicle);
    _analytics.logEvent("vehicle_selected", parameters: {"vehicle_id": vehicle.id, "price": vehicle.pricePerDay});
  }

  void setLocations({String? pickup, String? returnLoc}) {
    state = state.copyWith(
      pickupLocation: pickup != null ? () => pickup : null,
      returnLocation: returnLoc != null ? () => returnLoc : null,
    );
  }

  void setDateTimes({DateTime? pickup, DateTime? returnDT}) {
    state = state.copyWith(
      pickupDateTime: pickup != null ? () => pickup : null,
      returnDateTime: returnDT != null ? () => returnDT : null,
    );
  }

  void setRentalType(RentalType type) {
    if (type == RentalType.selfDrive) {
      // Clear driver if toggled to self-drive
      state = state.copyWith(
        rentalType: type,
        driver: () => null,
      );
    } else {
      state = state.copyWith(rentalType: type);
    }
    _analytics.logEvent("rental_type_changed", parameters: {"type": type.toString()});
  }

  void selectDriver(Driver? driver) {
    state = state.copyWith(driver: () => driver);
    if (driver != null) {
      _analytics.logEvent("driver_selected", parameters: {"driver_id": driver.id});
    }
  }

  void toggleService(Service service) {
    final currentServices = List<Service>.from(state.selectedServices);
    if (currentServices.contains(service)) {
      currentServices.remove(service);
      _analytics.logEvent("service_removed", parameters: {"service_id": service.id});
    } else {
      currentServices.add(service);
      _analytics.logEvent("service_added", parameters: {"service_id": service.id});
    }
    state = state.copyWith(selectedServices: currentServices);
  }

  Future<bool> applyCoupon(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final baseRental = BookingPriceCalculator.calculateBaseRentalCharge(state);
      final coupon = await _repository.verifyCoupon(code, baseRental);
      state = state.copyWith(isLoading: false);
      if (coupon != null) {
        state = state.copyWith(coupon: () => coupon);
        _analytics.logEvent("coupon_applied", parameters: {"code": code, "discount": coupon.discountAmount});
        return true;
      } else {
        state = state.copyWith(errorMessage: () => "Invalid or expired coupon code");
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => "Error verifying coupon");
      return false;
    }
  }

  void removeCoupon() {
    state = state.copyWith(coupon: () => null);
    _analytics.logEvent("coupon_removed");
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: () => method);
    _analytics.logEvent("payment_method_selected", parameters: {"method": method.toString()});
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
      _analytics.logEvent("booking_submit_completed", parameters: {"booking_id": bookingId});
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
