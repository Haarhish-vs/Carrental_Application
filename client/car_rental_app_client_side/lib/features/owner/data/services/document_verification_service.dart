import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:car_rental_app_client_side/core/config/api_config.dart';
import 'package:car_rental_app_client_side/features/auth/services/auth_service.dart';
import 'package:car_rental_app_client_side/features/owner/data/services/car_api_service.dart';

class DocumentVerificationService {
  final Dio _dio;

  DocumentVerificationService({Dio? dio}) : _dio = dio ?? Dio() {
    _initDio();
  }

  void _initDio() {
    _dio.options.baseUrl = ApiConfig.documentVerificationBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);
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
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> uploadDocuments({
    required String vehicleId,
    XFile? rc,
    XFile? insurance,
    XFile? fc,
    XFile? puc,
    XFile? permit,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('vehicleId', vehicleId));

    Future<void> addFileIfPresent(String fieldName, XFile? file) async {
      if (file != null) {
        final bytes = await file.readAsBytes();
        final fileExt = file.name.split('.').last.toLowerCase();
        final mimeType = fileExt == 'pdf'
            ? 'application/pdf'
            : 'image/${fileExt == 'png' ? 'png' : 'jpeg'}';
        final multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: file.name,
          contentType: DioMediaType.parse(mimeType),
        );
        formData.files.add(MapEntry(fieldName, multipartFile));
      }
    }

    await addFileIfPresent('rc', rc);
    await addFileIfPresent('insurance', insurance);
    await addFileIfPresent('fc', fc);
    await addFileIfPresent('puc', puc);
    await addFileIfPresent('permit', permit);

    return _dio.post<Map<String, dynamic>>(
      '/api/documents/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<Response<Map<String, dynamic>>> analyzeDocument({
    required String vehicleId,
    required String documentType,
  }) async {
    return _dio.post<Map<String, dynamic>>(
      '/api/documents/analyze',
      data: {'vehicleId': vehicleId, 'documentType': documentType},
    );
  }

  Future<Response<Map<String, dynamic>>> verifyDocuments({
    required String vehicleId,
  }) async {
    return _dio.post<Map<String, dynamic>>(
      '/api/documents/verify',
      data: {'vehicleId': vehicleId},
    );
  }

  Future<Response<Map<String, dynamic>>> getDocuments(String vehicleId) async {
    return _dio.get<Map<String, dynamic>>('/api/documents/$vehicleId');
  }

  Future<Response<Map<String, dynamic>>> getVerificationReport(
    String vehicleId,
  ) async {
    return _dio.get<Map<String, dynamic>>('/api/documents/$vehicleId/report');
  }

  Future<Response<Map<String, dynamic>>> deleteDocument(String id) async {
    return _dio.delete<Map<String, dynamic>>('/api/documents/$id');
  }
}
