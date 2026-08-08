import 'dart:convert';
import 'package:flutter/services.dart';
import 'api_exception.dart';
import 'api_response.dart';
import '../config/env.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({this.baseUrl = Env.baseUrl});

  // Load a mock JSON asset, acting like a mock GET request
  Future<ApiResponse<T>> getMockAsset<T>(String assetPath) async {
    try {
      // Simulate network latency (600ms)
      await Future.delayed(const Duration(milliseconds: 600));

      final jsonString = await rootBundle.loadString(assetPath);
      final dynamic decodedJson = json.decode(jsonString);

      return ApiResponse.success(decodedJson as T);
    } catch (e) {
      throw ApiException(
        message: "Failed to load mock data from $assetPath",
        details: e.toString(),
      );
    }
  }

  // Placeholder for real HTTP GET (to be plugged in with Dio by backend developers)
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    throw UnimplementedError(
      "Real API endpoints are not active. Switch Env features or use getMockAsset.",
    );
  }

  // Placeholder for real HTTP POST
  Future<ApiResponse<T>> post<T>(String path, {dynamic data}) async {
    // Return mock success
    await Future.delayed(const Duration(milliseconds: 800));
    return ApiResponse.success(
      {
            "id": "mock_tx_${DateTime.now().millisecondsSinceEpoch}",
            "status": "success",
            "timestamp": DateTime.now().toIso8601String(),
          }
          as T,
    );
  }
}
