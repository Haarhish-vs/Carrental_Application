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
            debugPrint('⚠️ [AuthService] 401 Unauthorized encountered from backend. Auto-logging out...');
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
    debugPrint('📥 [Auth] Checking encrypted secure storage for existing session token...');
    try {
      final savedToken = await _storage.read(key: _tokenKey);
      final savedUserJson = await _storage.read(key: _userKey);

      if (savedToken != null && savedToken.isNotEmpty) {
        debugPrint('📥 [Auth] Token retrieval successful: Length=${savedToken.length} characters');
        currentToken = savedToken;
        CarApiService.token = savedToken;

        if (savedUserJson != null && savedUserJson.isNotEmpty) {
          try {
            currentUser = jsonDecode(savedUserJson) as Map<String, dynamic>;
            authStateNotifier.value = currentUser;
            debugPrint('📥 [Auth] Cached user profile restored from secure storage: ${currentUser?['full_name'] ?? currentUser?['phone_number']}');
          } catch (_) {}
        }

        // Validate token against backend /api/auth/me
        debugPrint('🌐 [Auth] Validating session with backend endpoint /api/auth/me...');
        final authService = AuthService();
        final freshUser = await authService.getMe();
        if (freshUser != null) {
          await persistSession(savedToken, freshUser);
          debugPrint('✅ [Auth] Auto-login SUCCESS: User "${freshUser['full_name'] ?? freshUser['phone_number']}" is authenticated.');
          return true;
        } else {
          debugPrint('❌ [Auth] Auto-login FAILED: /api/auth/me returned null/invalid response. Removing stale token.');
          await logout();
          return false;
        }
      } else {
        debugPrint('ℹ️ [Auth] No stored authentication token found. Starting in Guest mode.');
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
    debugPrint('💾 [Auth] Saving JWT token and user profile to FlutterSecureStorage...');
    currentToken = token;
    currentUser = user;
    CarApiService.token = token;
    authStateNotifier.value = user;

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user));
    debugPrint('💾 [Auth] Token save complete for user: ${user['full_name'] ?? user['phone_number']}');
  }

  /// Checks whether a phone number is already registered in the backend database.
  /// Returns true if already registered, false if new.
  Future<bool> isPhoneRegistered(String phoneNumber) async {
    final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
    debugPrint('🔍 [Auth] Checking backend database if phone is already registered: $formattedPhone...');
    try {
      final response = await _dio.post(
        '/api/auth/verify-otp',
        data: {'phoneNumber': formattedPhone, 'otp': '123456'},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final isNewUser = data?['isNewUser'] as bool? ?? false;
        final isExisting = !isNewUser;
        debugPrint('🔍 [Auth] Phone check response for $formattedPhone: isExistingUser=$isExisting (isNewUser=$isNewUser)');
        return isExisting;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('🔍 [Auth] Phone check encountered error: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  /// Send OTP to phone number
  Future<String?> sendOtp(String phoneNumber, {bool isRegister = false}) async {
    final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';
    debugPrint('📨 [Auth] Requesting OTP for ${isRegister ? 'REGISTRATION' : 'LOGIN'} to phone: $formattedPhone');
    
    try {
      final response = await _dio.post(
        '/api/auth/send-otp',
        data: {
          'phoneNumber': formattedPhone,
          'isRegister': isRegister,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final rawOtp = data?['otp']?.toString();
        debugPrint('📨 [Auth] OTP sent successfully! ${rawOtp != null ? '(Dev OTP: $rawOtp)' : ''}');
        return rawOtp;
      }
      debugPrint('❌ [Auth] Failed to send OTP: Status code ${response.statusCode}');
      throw Exception('Failed to send OTP');
    } on DioException catch (e) {
      debugPrint('❌ [Auth] Send OTP error: ${e.response?.data ?? e.message}');
      throw _handleError(e);
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
    debugPrint('🔐 [Auth] Verifying OTP ($otp) for phone: $formattedPhone (Mode: ${isRegister ? 'REGISTER' : 'LOGIN'})');

    try {
      final response = await _dio.post(
        '/api/auth/verify-otp',
        data: {'phoneNumber': formattedPhone, 'otp': otp.trim()},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        var user = Map<String, dynamic>.from(data['user'] as Map);
        final isNewUser = data['isNewUser'] as bool? ?? false;

        debugPrint('🔐 [Auth] OTP verification result: isNewUser=$isNewUser, userId=${user['id']}');

        // Check if existing user is trying to register
        if (isRegister && !isNewUser) {
          debugPrint('🔍 [Auth] Existing user detected! User attempted to register with an already registered phone: $formattedPhone');
          return {
            'alreadyExists': true,
            'token': token,
            'user': user,
            'isNewUser': false,
          };
        }

        // Set token in memory for completeProfile call if registration provided a name
        currentToken = token;
        CarApiService.token = token;

        if (fullName != null && fullName.trim().isNotEmpty) {
          debugPrint('📝 [Auth] Completing profile with full name "$fullName" for new user...');
          try {
            final updatedUser = await completeProfile(fullName.trim());
            user = updatedUser;
          } catch (e) {
            debugPrint('⚠️ [Auth] Error updating profile name during registration: $e');
          }
        }

        // Persist token and user in encrypted secure storage
        await persistSession(token, user);
        debugPrint('✅ [Auth] Login/Registration SUCCESS! Active user: ${user['full_name'] ?? user['phone_number']}');

        return {
          'alreadyExists': false,
          'token': token,
          'user': user,
          'isNewUser': isNewUser,
        };
      }
      debugPrint('❌ [Auth] Invalid response format during OTP verification');
      throw Exception('Invalid OTP verification response');
    } on DioException catch (e) {
      debugPrint('❌ [Auth] OTP verification failed: ${e.response?.data ?? e.message}');
      throw _handleError(e);
    }
  }

  /// Complete profile with full name
  Future<Map<String, dynamic>> completeProfile(String fullName) async {
    debugPrint('📝 [Auth] Calling /api/auth/complete-profile with name "$fullName"...');
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
        debugPrint('✅ [Auth] Profile name updated successfully: ${user['full_name']}');
        return user;
      }
      throw Exception('Failed to update profile name');
    } on DioException catch (e) {
      debugPrint('❌ [Auth] Profile completion error: ${e.response?.data ?? e.message}');
      throw _handleError(e);
    }
  }

  /// Fetch authenticated user profile from /api/auth/me
  Future<Map<String, dynamic>?> getMe() async {
    if (!isAuthenticated) return null;
    debugPrint('🌐 [Auth] GET /api/auth/me request initiated...');
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
          debugPrint('🌐 [Auth] GET /api/auth/me profile load SUCCESS for: ${user['full_name'] ?? user['phone_number']}');
          return user;
        }
      }
      debugPrint('⚠️ [Auth] GET /api/auth/me failed with status code ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      debugPrint('❌ [Auth] GET /api/auth/me error: ${e.message}');
      return null;
    }
  }

  /// Logout: Clears encrypted storage, tokens, user data, and notifies listeners.
  static Future<void> logout() async {
    final userName = currentUser?['full_name'] ?? currentUser?['phone_number'] ?? 'User';
    debugPrint('🚪 [Auth] Logging out user "$userName"...');
    debugPrint('🚪 [Auth] Token removal started: Clearing JWT token and cached user data from FlutterSecureStorage...');

    currentToken = null;
    currentUser = null;
    CarApiService.token = null;
    authStateNotifier.value = null;
    debugPrint('🔄 [Auth] Auth-state reset complete: currentToken=null, currentUser=null, CarApiService.token=null.');

    try {
      await _storage.deleteAll();
      debugPrint('🚪 [Auth] Token removal SUCCESS: All encrypted keys wiped from FlutterSecureStorage.');
    } catch (e) {
      debugPrint('⚠️ [Auth] Error clearing secure storage on logout: $e');
    }
    debugPrint('🚪 [Auth] Logout flow completed successfully.');
  }

  Exception _handleError(DioException error) {
    if (error.response != null && error.response?.data is Map) {
      final msg = error.response?.data['message'];
      if (msg != null) return Exception(msg.toString());
    }
    return Exception(error.message ?? 'Authentication failed. Please check your connection.');
  }
}
