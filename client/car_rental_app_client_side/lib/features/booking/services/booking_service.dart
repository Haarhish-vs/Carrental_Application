import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_client.dart';
import '../models/driver_model.dart';
import '../models/service_model.dart';
import '../models/coupon_model.dart';
import '../models/booking_flow_state.dart';

abstract class BookingService {
  Future<List<Driver>> fetchDrivers();
  Future<List<Service>> fetchServices();
  Future<List<Coupon>> fetchCoupons();
  Future<Coupon?> validateCoupon(String code, double bookingValue);
  Future<Map<String, dynamic>> submitBooking(BookingFlowState state);
}

class MockBookingServiceImpl implements BookingService {
  final ApiClient _apiClient;

  MockBookingServiceImpl(this._apiClient);

  @override
  Future<List<Driver>> fetchDrivers() async {
    final response = await _apiClient.getMockAsset<List<dynamic>>(
      AppAssets.driversJson,
    );
    if (response.success && response.data != null) {
      return response.data!
          .map((item) => Driver.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<Service>> fetchServices() async {
    final response = await _apiClient.getMockAsset<List<dynamic>>(
      AppAssets.servicesJson,
    );
    if (response.success && response.data != null) {
      return response.data!
          .map((item) => Service.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<Coupon>> fetchCoupons() async {
    final response = await _apiClient.getMockAsset<List<dynamic>>(
      AppAssets.couponsJson,
    );
    if (response.success && response.data != null) {
      return response.data!
          .map((item) => Coupon.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<Coupon?> validateCoupon(String code, double bookingValue) async {
    final response = await _apiClient.getMockAsset<List<dynamic>>(
      AppAssets.couponsJson,
    );
    if (response.success && response.data != null) {
      final coupons = response.data!
          .map((item) => Coupon.fromJson(item as Map<String, dynamic>))
          .toList();
      for (final coupon in coupons) {
        if (coupon.code.toUpperCase() == code.toUpperCase()) {
          if (bookingValue >= coupon.minBookingValue) {
            return coupon;
          }
          return null; // Value below threshold
        }
      }
    }
    return null; // Coupon not found
  }

  @override
  Future<Map<String, dynamic>> submitBooking(BookingFlowState state) async {
    // Simulate API reservation call
    final response = await _apiClient.post<Map<String, dynamic>>(
      "/bookings",
      data: {
        "vehicleId": state.vehicle?.id,
        "pickupLocation": state.pickupLocation?.toJson(),
        "returnLocation": state.returnLocation?.toJson(),
        "pickupDateTime": state.pickupDateTime?.toIso8601String(),
        "returnDateTime": state.returnDateTime?.toIso8601String(),
        "rentalType": state.rentalType.toString(),
        "driverId": state.driver?.id,
        "serviceIds": state.selectedServices.map((e) => e.id).toList(),
        "couponCode": state.coupon?.code,
        "paymentMethod": state.paymentMethod?.toString(),
      },
    );

    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception("Booking failed to process.");
  }
}
