import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class CarApiService {
  CarApiService({Dio? dio}) : _dio = dio ?? Dio() {
    _initDio();
  }

  final Dio _dio;
  
  // Base URL for the Rent-A-Car backend
  static String baseUrl = 'https://carrental-application-1.onrender.com';
  
  // Static token storage that can be set from elsewhere in the app (e.g., login)
  static String? token;

  void _initDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Authentication, Logging, and Retry Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final authToken = token ?? 'mock_dev_session_token';
          if (authToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }
          debugPrint('🌐 [API Request] ${options.method} ${options.baseUrl}${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ [API Response] ${response.statusCode} | ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          debugPrint('❌ [API Error] Status: ${error.response?.statusCode} | Path: ${error.requestOptions.path} | Error: ${error.message}');
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
          filename: file.name.isNotEmpty ? file.name : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        formData.files.add(MapEntry('files', multipartFile));
      }

      final response = await _dio.post(
        '/api/vehicles/upload',
        data: formData,
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
      // Fallback: If 404 or connection error occurs, convert files into Base64 Data URLs so images store cleanly in DB
      if (e.response?.statusCode == 404 || e.type == DioExceptionType.connectionError) {
        debugPrint('⚠️ Upload endpoint unreachable (${e.response?.statusCode}). Falling back to Base64 data encoding...');
        final base64Urls = <String>[];
        for (final file in files) {
          final bytes = await file.readAsBytes();
          final base64Str = base64Encode(bytes);
          base64Urls.add('data:image/jpeg;base64,$base64Str');
        }
        onProgress(1.0);
        return base64Urls;
      }
      throw _handleDioError(e);
    }
  }

  /// Create a new vehicle listing
  Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> vehicleData) async {
    try {
      final response = await _dio.post(
        '/api/vehicles',
        data: vehicleData,
      );

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
        data: {
          'documentType': documentType,
          'documentUrl': documentUrl,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          return response.data['data'] as Map<String, dynamic>;
        }
      }

      throw DioException(
        requestOptions: RequestOptions(path: '/api/vehicles/$vehicleId/documents'),
        message: 'Failed to submit document details',
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
          message = 'Cannot connect to the server. Please check your network connection.';
          break;
        default:
          message = error.message ?? message;
      }
    }
    return Exception(message);
  }
}
