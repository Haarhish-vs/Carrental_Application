import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../owner/data/services/car_api_service.dart';

class ProfileApiService {
  ProfileApiService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: CarApiService.baseUrl)) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final token = CarApiService.token;
      if (token != null && token.isNotEmpty) options.headers['Authorization'] = 'Bearer $token';
      return handler.next(options);
    }));
  }

  final Dio _dio;

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/api/profile');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> values) async {
    final response = await _dio.patch('/api/profile', data: values);
    return Map<String, dynamic>.from(response.data['data']['user'] as Map);
  }

  Future<void> becomeOwner() async => _dio.post('/api/profile/roles/owner');

  Future<Map<String, dynamic>> uploadPhoto(XFile photo) async {
    final response = await _dio.post('/api/profile/photo', data: FormData.fromMap({
      'photo': MultipartFile.fromBytes(await photo.readAsBytes(), filename: photo.name),
    }));
    return Map<String, dynamic>.from(response.data['data']['user'] as Map);
  }
}
