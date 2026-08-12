import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:car_rental_app_client_side/features/owner/data/services/car_api_service.dart';

class AuthService {
  AuthService({Dio? dio}) : _dio = dio ?? Dio() {
    _initDio();
  }

  final Dio _dio;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const String _tokenKey = 'auth_jwt_token';
  static const String _userKey = 'auth_user_data';

  static String? currentToken;
  static Map<String, dynamic>? currentUser;

  /// Global reactive notifier for auth changes (Home Screen, App Bar, Drawer, etc.)
  static final ValueNotifier<Map<String, dynamic>?> authStateNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  static bool get isAuthenticated =>
      currentToken != null && currentToken!.isNotEmpty;

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
          final token = currentToken ?? CarApiService.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            debugPrint(
              '⚠️ [AuthService] 401 Unauthorized encountered from backend. Auto-logging out...',
            );
            await logout();
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Called on app startup in main.dart before runApp.
  /// Checks for stored JWT, retrieves it from secure storage, and calls /api/auth/me to validate session.
  static Future<bool> tryAutoLogin() async {
    debugPrint('📥 [Auth] Checking secure storage for existing session token...');
    try {
      final savedToken = await _storage.read(key: _tokenKey);
      final savedUserJson = await _storage.read(key: _userKey);

      if (savedToken != null && savedToken.isNotEmpty) {
        currentToken = savedToken;
        CarApiService.token = savedToken;

        if (savedUserJson != null && savedUserJson.isNotEmpty) {
          try {
            currentUser = jsonDecode(savedUserJson) as Map<String, dynamic>;
            authStateNotifier.value = currentUser;
          } catch (_) {}
        }

        // Validate token against backend /api/auth/me
        final authService = AuthService();
        final freshUser = await authService.getMe();
        if (freshUser != null) {
          await persistSession(savedToken, freshUser);
          debugPrint(
            '✅ [Auth] Auto-login SUCCESS: User "${freshUser['full_name'] ?? freshUser['phone_number']}" is authenticated.',
          );
          return true;
        } else {
          debugPrint('❌ [Auth] Stale or invalid session. Clearing storage...');
          await logout();
          return false;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Auth] Auto-login error reading secure storage: $e');
      await logout();
    }
    return false;
  }

  /// Persist session in encrypted secure storage and notify listeners
  static Future<void> persistSession(
    String token,
    Map<String, dynamic> user,
  ) async {
    currentToken = token;
    currentUser = user;
    CarApiService.token = token;
    authStateNotifier.value = user;

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  /// Checks if a phone number exists in the backend DB (409 for register, 404 for login).
  Future<void> checkPhone(String phoneNumber, {required bool isRegister}) async {
    final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
    try {
      await _dio.post(
        '/api/auth/check-phone',
        data: {'phoneNumber': formattedPhone, 'isRegister': isRegister},
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Send OTP to phone number with strict DB validation before sending
  Future<String?> sendOtp(String phoneNumber, {required bool isRegister}) async {
    final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
    debugPrint(
      '📨 [Auth] Requesting OTP for ${isRegister ? 'REGISTRATION' : 'LOGIN'} to phone: $formattedPhone',
    );

    try {
      final response = await _dio.post(
        '/api/auth/send-otp',
        data: {'phoneNumber': formattedPhone, 'isRegister': isRegister},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        return data?['otp']?.toString();
      }
      throw Exception('Failed to send OTP');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Verify OTP and log in / register
  Future<Map<String, dynamic>> verifyOtpAndLogin({
    required String phoneNumber,
    required String otp,
    String? fullName,
    bool isRegister = false,
  }) async {
    final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
    debugPrint(
      '🔐 [Auth] Verifying OTP ($otp) for phone: $formattedPhone (Mode: ${isRegister ? 'REGISTER' : 'LOGIN'})',
    );

    try {
      final response = await _dio.post(
        '/api/auth/verify-otp',
        data: {
          'phoneNumber': formattedPhone,
          'otp': otp.trim(),
          if (fullName != null && fullName.trim().isNotEmpty) 'fullName': fullName.trim(),
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = Map<String, dynamic>.from(data['user'] as Map);
        final isNewUser = data['isNewUser'] as bool? ?? (response.statusCode == 201);
        final message = response.data['message']?.toString() ??
            (isNewUser ? 'Account created successfully' : 'Login successful');

        // Persist token and user in encrypted secure storage
        await persistSession(token, user);
        debugPrint('✅ [Auth] Auth SUCCESS: ${user['full_name'] ?? user['phone_number']}');

        return {
          'token': token,
          'user': user,
          'isNewUser': isNewUser,
          'message': message,
          'statusCode': response.statusCode,
        };
      }
      throw Exception('Invalid OTP verification response');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Complete profile with full name
  Future<Map<String, dynamic>> completeProfile(String fullName) async {
    try {
      final response = await _dio.post(
        '/api/auth/complete-profile',
        data: {'fullName': fullName.trim()},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final user = Map<String, dynamic>.from(data['user'] as Map);
        if (currentToken != null) {
          await persistSession(currentToken!, user);
        }
        return user;
      }
      throw Exception('Failed to update profile name');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Fetch authenticated user profile from /api/auth/me
  Future<Map<String, dynamic>?> getMe() async {
    if (!isAuthenticated) return null;
    try {
      final response = await _dio.get('/api/auth/me');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null && data['user'] != null) {
          final user = Map<String, dynamic>.from(data['user'] as Map);
          currentUser = user;
          authStateNotifier.value = user;
          if (currentToken != null) {
            await _storage.write(key: _userKey, value: jsonEncode(user));
          }
          return user;
        }
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Logout: Clears encrypted storage, tokens, user data, and notifies listeners.
  static Future<void> logout() async {
    debugPrint('🚪 [Auth] Clearing session and secure storage...');
    currentToken = null;
    currentUser = null;
    CarApiService.token = null;
    authStateNotifier.value = null;

    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('⚠️ [Auth] Error clearing secure storage: $e');
    }
  }

  /// Maps backend HTTP status codes & Dio exceptions to exact required user-facing messages
  Exception _mapDioError(DioException error) {
    if (error.response != null) {
      final status = error.response?.statusCode;
      final responseData = error.response?.data;
      final serverMsg = responseData is Map ? responseData['message']?.toString() : null;

      // Exact HTTP status code mapping
      switch (status) {
        case 201:
          return Exception('Account created successfully');
        case 200:
          return Exception(serverMsg ?? 'Login successful');
        case 409:
          return Exception('Phone number already registered. Please login.');
        case 404:
          return Exception('Phone number not registered. Please register.');
        case 400:
          return Exception('Invalid OTP. Please try again.');
        case 410:
          return Exception('OTP expired. Please request a new OTP.');
        case 429:
          return Exception('Too many attempts. Please try again later.');
        case 401:
          return Exception('Session expired. Please login again.');
        case 403:
          return Exception("You don't have permission to perform this action.");
        case 422:
          return Exception('Please check the entered details.');
        case 500:
          return Exception('Something went wrong. Please try again.');
        default:
          return Exception(serverMsg ?? 'Something went wrong. Please try again.');
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return Exception('Unable to connect. Check your internet connection.');
      default:
        return Exception('Unable to connect. Check your internet connection.');
    }
  }
}
