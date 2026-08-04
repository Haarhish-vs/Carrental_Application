import '../models/driver_model.dart';
import '../models/service_model.dart';
import '../models/coupon_model.dart';
import '../models/booking_flow_state.dart';
import '../services/booking_service.dart';

abstract class BookingRepository {
  Future<List<Driver>> getDrivers();
  Future<List<Service>> getServices();
  Future<List<Coupon>> getCoupons();
  Future<Coupon?> verifyCoupon(String code, double bookingValue);
  Future<String> createBooking(BookingFlowState state);
}

class BookingRepositoryImpl implements BookingRepository {
  final BookingService _bookingService;

  BookingRepositoryImpl(this._bookingService);

  @override
  Future<List<Driver>> getDrivers() {
    return _bookingService.fetchDrivers();
  }

  @override
  Future<List<Service>> getServices() {
    return _bookingService.fetchServices();
  }

  @override
  Future<List<Coupon>> getCoupons() {
    return _bookingService.fetchCoupons();
  }

  @override
  Future<Coupon?> verifyCoupon(String code, double bookingValue) {
    return _bookingService.verifyCoupon(code, bookingValue);
  }

  @override
  Future<String> createBooking(BookingFlowState state) async {
    final result = await _bookingService.submitBooking(state);
    return result['id'] as String? ?? "bk_default";
  }
}
