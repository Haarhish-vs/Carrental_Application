import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:car_rental_app_client_side/features/owner/data/services/car_api_service.dart';

class AuthService {
  AuthService({Dio? dio}) : _dio = dio ?? Dio() {
    _initDio();
  }

  final Dio _dio;

  static String? currentToken;
  static Map<String, dynamic>? currentUser;

  static bool get isAuthenticated => currentToken != null && currentToken!.isNotEmpty;

  void _initDio() {
    _dio.options.baseUrl = CarApiService.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (currentToken != null && currentToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $currentToken';
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Send OTP to phone number
  Future<String?> sendOtp(String phoneNumber) async {
    try {
      final response = await _dio.post(
        '/api/auth/send-otp',
        data: {'phoneNumber': phoneNumber},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        // In development/test mode, backend returns raw OTP
        return data?['otp'] as String?;
      }
      throw Exception('Failed to send OTP');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify OTP and log in / register
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/verify-otp',
        data: {
          'phoneNumber': phoneNumber,
          'otp': otp,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;
        final isNewUser = data['isNewUser'] as bool? ?? false;

        // Store token in auth state & sync with CarApiService
        currentToken = token;
        currentUser = user;
        CarApiService.token = token;

        return {
          'token': token,
          'user': user,
          'isNewUser': isNewUser,
        };
      }
      throw Exception('Invalid OTP verification response');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Complete profile with full name for new users
  Future<Map<String, dynamic>> completeProfile(String fullName) async {
    try {
      final response = await _dio.post(
        '/api/auth/complete-profile',
        data: {'fullName': fullName},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;
        currentUser = user;
        return user;
      }
      throw Exception('Failed to complete profile');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch authenticated user profile
  Future<Map<String, dynamic>?> getMe() async {
    if (!isAuthenticated) return null;
    try {
      final response = await _dio.get('/api/auth/me');
      if (response.statusCode == 200 && response.data != null) {
        final user = response.data['data']['user'] as Map<String, dynamic>;
        currentUser = user;
        return user;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  /// Logout and clear saved token
  static void logout() {
    currentToken = null;
    currentUser = null;
    CarApiService.token = null;
  }

  Exception _handleError(DioException error) {
    if (error.response != null && error.response?.data is Map) {
      final msg = error.response?.data['message'];
      if (msg != null) return Exception(msg.toString());
    }
    return Exception(error.message ?? 'Authentication failed');
  }
}
