import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/services/auth_service.dart';
import '../../../owner/data/services/car_api_service.dart';
import '../models/user_profile_model.dart';

class ProfileApiService {
  ProfileApiService({Dio? dio}) : _dio = dio ?? Dio() {
    _initDio();
  }

  final Dio _dio;

  void _initDio() {
    _dio.options.baseUrl = CarApiService.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.options.headers = {'Accept': 'application/json'};

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final authToken = CarApiService.token ?? AuthService.currentToken;
          if (authToken != null && authToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            debugPrint('⚠️ [ProfileApiService] 401 Unauthorized.');
            await AuthService.logout();
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Fetch user profile and activity metrics from backend
  Future<UserProfileModel> getProfile() async {
    try {
      final response = await _dio.get('/api/profile');
      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          final data = response.data['data'] as Map<String, dynamic>;
          final profile = UserProfileModel.fromJson(data);
          // Sync with local AuthService state
          AuthService.currentUser = {
            ...?AuthService.currentUser,
            'id': profile.id,
            'full_name': profile.fullName,
            'phone_number': profile.phoneNumber,
            'email': profile.email,
            'profile_image_url': profile.profileImageUrl,
            'is_dl_verified': profile.isDlVerified,
            'trust_score': profile.trustScore,
          };
          AuthService.authStateNotifier.value = AuthService.currentUser;
          return profile;
        }
      }
      throw Exception('Failed to load profile');
    } on DioException catch (e) {
      if (AuthService.currentUser != null) {
        debugPrint('ℹ️ [ProfileApiService] Using cached user session while backend deploys');
        return UserProfileModel.fromJson(AuthService.currentUser!);
      }
      throw _handleDioError(e);
    }
  }

  /// Update user profile details (Name, Phone number, Email)
  Future<UserProfileModel> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (fullName != null) payload['fullName'] = fullName;
      if (phoneNumber != null) payload['phoneNumber'] = phoneNumber;
      if (email != null) payload['email'] = email;

      final response = await _dio.put('/api/profile', data: payload);
      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          final data = response.data['data'] as Map<String, dynamic>;
          final profile = UserProfileModel.fromJson(data);
          // Sync with local AuthService state
          AuthService.currentUser = {
            ...?AuthService.currentUser,
            'id': profile.id,
            'full_name': profile.fullName,
            'phone_number': profile.phoneNumber,
            'email': profile.email,
            'profile_image_url': profile.profileImageUrl,
          };
          AuthService.authStateNotifier.value = AuthService.currentUser;
          return profile;
        }
      }
      throw Exception('Failed to update profile');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Upload profile avatar image to Cloudinary via backend
  Future<UserProfileModel> uploadProfileImage(
    XFile file, {
    ValueChanged<double>? onProgress,
  }) async {
    try {
      final formData = FormData();
      final bytes = await file.readAsBytes();

      final fileExt = file.name.split('.').lastOrNull ?? 'jpg';
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      final multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      formData.files.add(MapEntry('image', multipartFile));

      final response = await _dio.post(
        '/api/profile/upload-image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          final data = response.data['data'] as Map<String, dynamic>;
          final profile = UserProfileModel.fromJson(data);
          // Sync with local AuthService state
          AuthService.currentUser = {
            ...?AuthService.currentUser,
            'profile_image_url': profile.profileImageUrl,
          };
          AuthService.authStateNotifier.value = AuthService.currentUser;
          return profile;
        }
      }
      throw Exception('Failed to upload profile image');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    String message = 'An unexpected error occurred';
    if (error.response != null) {
      final responseData = error.response?.data;
      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else {
        message = 'Server returned error status ${error.response?.statusCode}';
      }
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Network connection timed out';
          break;
        case DioExceptionType.connectionError:
          message = 'Cannot connect to the server. Please check your network connection.';
          break;
        default:
          message = error.message ?? message;
      }
    }
    return Exception(message);
  }
}
