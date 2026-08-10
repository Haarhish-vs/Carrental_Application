import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:car_rental_app_client_side/features/auth/services/auth_service.dart';

class CarApiService {
  CarApiService({Dio? dio}) : _dio = dio ?? Dio() {
    _initDio();
  }

  final Dio _dio;

  // Base URL for the Rent-A-Car backend
  static String baseUrl = 'https://carrental-application-z49a.onrender.com';

  // Static token storage that can be set from elsewhere in the app (e.g., login)
  static String? token;

  void _initDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);
    _dio.options.headers = {'Accept': 'application/json'};

    // Authentication, Logging, and Retry Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final authToken = token ?? AuthService.currentToken;
          if (authToken != null && authToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }
          debugPrint(
            '🌐 [API Request] ${options.method} ${options.baseUrl}${options.path} | auth=${options.headers['Authorization'] != null}',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '✅ [API Response] ${response.statusCode} | ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          debugPrint(
            '❌ [API Error] Status: ${error.response?.statusCode} | Path: ${error.requestOptions.path} | Error: ${error.message}',
          );
          if (error.response?.statusCode == 401) {
            debugPrint('⚠️ [CarApiService] 401 Unauthorized. Clearing session...');
            await AuthService.logout();
          }
          // Implement simple retry functionality for network connection timeouts
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            final requestOptions = error.requestOptions;
            // Retry only once to prevent infinite loops
            if (requestOptions.extra['isRetry'] != true) {
              requestOptions.extra['isRetry'] = true;
              try {
                final response = await _dio.request(
                  requestOptions.path,
                  data: requestOptions.data,
                  queryParameters: requestOptions.queryParameters,
                  options: Options(
                    method: requestOptions.method,
                    headers: requestOptions.headers,
                    extra: requestOptions.extra,
                  ),
                );
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Upload multiple files using multipart/form-data with progress tracking
  Future<List<String>> uploadFiles(
    List<XFile> files,
    ValueChanged<double> onProgress,
  ) async {
    try {
      final formData = FormData();

      for (final file in files) {
        final bytes = await file.readAsBytes();
        final multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: file.name.isNotEmpty
              ? file.name
              : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        formData.files.add(MapEntry('files', multipartFile));
      }

      final authToken = token ?? AuthService.currentToken;
      if (authToken == null || authToken.isEmpty) {
        throw DioException(
          requestOptions: RequestOptions(path: '/api/vehicles/upload'),
          message: 'Not authenticated. Please log in before uploading files.',
          type: DioExceptionType.cancel,
        );
      }

      debugPrint('🔐 Upload auth token length: ${authToken.length}');

      final response = await _dio.post(
        '/api/vehicles/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Authorization': 'Bearer $authToken'},
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success) {
          final data = response.data['data'] as List<dynamic>?;
          if (data != null) {
            return data.map((url) => url.toString()).toList();
          }
        }
      }

      throw DioException(
        requestOptions: RequestOptions(path: '/api/vehicles/upload'),
        message: 'Upload failed: Invalid response format',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetch active & available vehicles for browsing on the Home Screen
  Future<List<Map<String, dynamic>>> getVehicles() async {
    try {
      final response = await _dio.get('/api/vehicles');
      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          final list = response.data['data'] as List<dynamic>;
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Error fetching vehicles: ${e.message}');
      return [];
    }
  }

  /// Fetch a single vehicle's details by ID
  Future<Map<String, dynamic>> getVehicleById(String vehicleId) async {
    try {
      final response = await _dio.get('/api/vehicles/$vehicleId');
      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          return Map<String, dynamic>.from(response.data['data'] as Map);
        }
      }
      throw Exception('Failed to fetch vehicle details');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetch the logged-in user's bookings.
  Future<List<Map<String, dynamic>>> getMyBookings() async {
    try {
      final response = await _dio.get('/api/bookings/my-bookings');
      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          final list = response.data['data'] as List<dynamic>;
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Error fetching my bookings: ${e.message}');
      return [];
    }
  }

  /// Fetch a single booking by its ID.
  Future<Map<String, dynamic>> getBookingById(String bookingId) async {
    try {
      final response = await _dio.get('/api/bookings/$bookingId');
      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          return Map<String, dynamic>.from(response.data['data'] as Map);
        }
      }
      throw Exception('Failed to fetch booking details');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetch the logged-in user's listed vehicles.
  Future<List<Map<String, dynamic>>> getMyListings() async {
    try {
      final response = await _dio.get('/api/vehicles/my-listings');
      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          final list = response.data['data'] as List<dynamic>;
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Error fetching my listings: ${e.message}');
      return [];
    }
  }

  /// Create a new booking for a selected vehicle.
  Future<Map<String, dynamic>> createBooking({
    required String vehicleId,
    required String startDate,
    required String endDate,
    double? totalPrice,
  }) async {
    try {
      final response = await _dio.post(
        '/api/bookings',
        data: {
          'vehicleId': vehicleId,
          'startDate': startDate,
          'endDate': endDate,
          if (totalPrice != null) 'totalPrice': totalPrice,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          return response.data['data'] as Map<String, dynamic>;
        }
      }

      throw DioException(
        requestOptions: RequestOptions(path: '/api/bookings'),
        message: 'Failed to create booking',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create a new vehicle listing
  Future<Map<String, dynamic>> createVehicle(
    Map<String, dynamic> vehicleData,
  ) async {
    try {
      final response = await _dio.post('/api/vehicles', data: vehicleData);

      if (response.statusCode == 201 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          return response.data['data'] as Map<String, dynamic>;
        }
      }

      throw DioException(
        requestOptions: RequestOptions(path: '/api/vehicles'),
        message: 'Failed to create vehicle listing',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Associate a verified document reference with the listed vehicle
  Future<Map<String, dynamic>> uploadVehicleDocument({
    required String vehicleId,
    required String documentType,
    required String documentUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/api/vehicles/$vehicleId/documents',
        data: {'documentType': documentType, 'documentUrl': documentUrl},
      );

      if (response.statusCode == 201 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          return response.data['data'] as Map<String, dynamic>;
        }
      }

      throw DioException(
        requestOptions: RequestOptions(
          path: '/api/vehicles/$vehicleId/documents',
        ),
        message: 'Failed to submit document details',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Upload a single document file to Supabase storage via the backend API.
  Future<String> uploadDocument(XFile file) async {
    try {
      final formData = FormData();
      final bytes = await file.readAsBytes();

      // Determine file extension and name
      final fileSegments = file.name.split('.');
      final fileExt = fileSegments.isNotEmpty ? fileSegments.last : 'jpg';
      final fileName = file.name.isNotEmpty
          ? file.name
          : 'doc_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      final multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      formData.files.add(MapEntry('files', multipartFile));

      final authToken = token ?? AuthService.currentToken;
      if (authToken == null || authToken.isEmpty) {
        throw DioException(
          requestOptions: RequestOptions(path: '/api/vehicles/upload-document'),
          message:
              'Not authenticated. Please log in before uploading documents.',
          type: DioExceptionType.cancel,
        );
      }

      final response = await _dio.post(
        '/api/vehicles/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Authorization': 'Bearer $authToken'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          final data = response.data['data'];
          if (data is List && data.isNotEmpty) {
            return data.first.toString();
          }
          return data.toString();
        }
      }

      throw DioException(
        requestOptions: RequestOptions(path: '/api/vehicles/upload'),
        message: response.data?['message'] ?? 'Document upload failed',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Cancel a booking by its ID. Can be called by the renter or owner.
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final response = await _dio.patch(
        '/api/bookings/$bookingId/cancel',
        data: {'reason': reason ?? 'Cancelled by user'},
      );
      if (response.statusCode == 200) return;
      throw DioException(
        requestOptions: RequestOptions(path: '/api/bookings/$bookingId/cancel'),
        message: response.data?['message'] ?? 'Failed to cancel booking',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Toggle a vehicle's availability (owner only).
  /// Pass [isAvailable] = false to mark as unavailable, true to re-enable.
  Future<void> toggleVehicleAvailability(String vehicleId, {required bool isAvailable}) async {
    try {
      final response = await _dio.patch(
        '/api/vehicles/$vehicleId/availability',
        data: {'isAvailable': isAvailable},
      );
      if (response.statusCode == 200) return;
      throw DioException(
        requestOptions: RequestOptions(path: '/api/vehicles/$vehicleId/availability'),
        message: response.data?['message'] ?? 'Failed to update availability',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetch incoming bookings for the owner's listed vehicles.
  Future<List<Map<String, dynamic>>> getMyVehicleBookings() async {
    try {
      final response = await _dio.get('/api/bookings/my-vehicle-bookings');
      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          final list = response.data['data'] as List<dynamic>;
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Error fetching vehicle bookings: ${e.message}');
      return [];
    }
  }

  /// Confirm a booking request (Owner accepts).
  Future<void> confirmBooking(String bookingId) async {
    try {
      final response = await _dio.patch('/api/bookings/$bookingId/confirm');
      if (response.statusCode == 200) return;
      throw DioException(
        requestOptions: RequestOptions(path: '/api/bookings/$bookingId/confirm'),
        message: response.data?['message'] ?? 'Failed to confirm booking',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Decline / cancel a booking request.
  Future<void> declineBooking(String bookingId, {String? reason}) async {
    try {
      final response = await _dio.patch(
        '/api/bookings/$bookingId/cancel',
        data: {'reason': reason ?? 'Declined by owner'},
      );
      if (response.statusCode == 200) return;
      throw DioException(
        requestOptions: RequestOptions(path: '/api/bookings/$bookingId/cancel'),
        message: response.data?['message'] ?? 'Failed to decline booking',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Confirm a booking payment (Renter pays).
  Future<void> confirmBookingPayment(String bookingId) async {
    try {
      final response = await _dio.patch('/api/bookings/$bookingId/pay');
      if (response.statusCode == 200) return;
      throw DioException(
        requestOptions: RequestOptions(path: '/api/bookings/$bookingId/pay'),
        message: response.data?['message'] ?? 'Failed to confirm booking payment',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Start a booking trip.
  Future<void> startBooking(String bookingId) async {
    try {
      final response = await _dio.patch('/api/bookings/$bookingId/start');
      if (response.statusCode == 200) return;
      throw DioException(
        requestOptions: RequestOptions(path: '/api/bookings/$bookingId/start'),
        message: response.data?['message'] ?? 'Failed to start booking',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Complete a booking trip.
  Future<void> completeBooking(String bookingId) async {
    try {
      final response = await _dio.patch('/api/bookings/$bookingId/complete');
      if (response.statusCode == 200) return;
      throw DioException(
        requestOptions: RequestOptions(path: '/api/bookings/$bookingId/complete'),
        message: response.data?['message'] ?? 'Failed to complete booking',
      );
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
          message =
              'Cannot connect to the server. Please check your network connection.';
          break;
        default:
          message = error.message ?? message;
      }
    }
    return Exception(message);
  }
}
