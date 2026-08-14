import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:car_rental_app_client_side/core/error_handling/app_error_handler.dart';
import '../../../auth/services/auth_service.dart';
import '../../../home/models/car_model.dart';
import '../../../owner/data/services/car_api_service.dart';

class WishlistApiService {
  WishlistApiService({Dio? dio}) : _dio = dio ?? Dio() {
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
            debugPrint('⚠️ [WishlistApiService] 401 Unauthorized.');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Toggle vehicle in/out of wishlist
  Future<bool> toggleWishlist(String vehicleId) async {
    try {
      final response = await _dio.post(
        '/api/wishlist/toggle',
        data: {'vehicleId': vehicleId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          return response.data['data']['isWishlisted'] as bool? ?? false;
        }
      }
      throw Exception('Failed to toggle wishlist');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetch list of vehicle IDs wishlisted by the current user
  Future<List<String>> getWishlistIds() async {
    try {
      final response = await _dio.get('/api/wishlist/ids');
      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          final rawList = response.data['data'] as List;
          return rawList.map((id) => id.toString()).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('⚠️ [WishlistApiService.getWishlistIds] Error: ${e.message}');
      return [];
    }
  }

  /// Fetch full populated vehicle list in user's wishlist
  Future<List<CarModel>> getWishlist() async {
    try {
      final response = await _dio.get('/api/wishlist');
      if (response.statusCode == 200 && response.data != null) {
        final success = response.data['success'] as bool? ?? false;
        if (success && response.data['data'] != null) {
          final rawList = response.data['data'] as List;
          return rawList
              .map((item) => CarModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    return AppErrorHandler.handle(error);
  }
}
