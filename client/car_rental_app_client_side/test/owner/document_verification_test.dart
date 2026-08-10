import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:car_rental_app_client_side/features/owner/data/services/car_api_service.dart';
import 'package:car_rental_app_client_side/features/owner/data/models/document_verification_models.dart';
import 'package:car_rental_app_client_side/features/owner/data/services/document_verification_service.dart';
import 'package:car_rental_app_client_side/features/owner/data/repositories/document_verification_repository.dart';

class MockInterceptor extends Interceptor {
  Map<String, dynamic>? mockResponseData;
  int mockStatusCode = 200;
  RequestOptions? lastRequestOptions;
  final List<RequestOptions> requestLog = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    lastRequestOptions = options;
    requestLog.add(options);
    final response = Response(
      requestOptions: options,
      data: mockResponseData,
      statusCode: mockStatusCode,
    );
    handler.resolve(response);
  }
}

void main() {
  group('Vehicle Document Verification & OCR Integration Tests', () {
    late Dio dio;
    late MockInterceptor mockInterceptor;
    late DocumentVerificationService service;
    late DocumentVerificationRepository repository;

    setUp(() {
      dio = Dio();
      mockInterceptor = MockInterceptor();
      service = DocumentVerificationService(dio: dio);
      dio.interceptors.add(mockInterceptor);
      repository = DocumentVerificationRepository(service: service);
    });

    test('1. Multipart field mapping checks', () async {
      mockInterceptor.mockResponseData = {'success': true};
      
      final rc = XFile.fromData(Uint8List(10), name: 'rc.pdf');
      final insurance = XFile.fromData(Uint8List(10), name: 'ins.jpg');
      final fc = XFile.fromData(Uint8List(10), name: 'fc.png');
      
      await repository.uploadDocuments(
        vehicleId: 'veh123',
        rc: rc,
        insurance: insurance,
        fc: fc,
      );

      final lastReq = mockInterceptor.lastRequestOptions;
      expect(lastReq, isNotNull);
      expect(lastReq!.path, '/api/documents/upload');
      expect(lastReq.data, isA<FormData>());
      
      final formData = lastReq.data as FormData;
      final fields = formData.fields;
      expect(fields.any((f) => f.key == 'vehicleId' && f.value == 'veh123'), isTrue);

      final files = formData.files;
      expect(files.any((f) => f.key == 'rc'), isTrue);
      expect(files.any((f) => f.key == 'insurance'), isTrue);
      expect(files.any((f) => f.key == 'fc'), isTrue);
      expect(files.any((f) => f.key == 'puc'), isFalse);
    });

    test('2. Authentication token header presence', () async {
      mockInterceptor.mockResponseData = {'success': true};
      
      // Inject dummy authentication session token to CarApiService
      CarApiService.token = 'test-token-jwt-123';
      
      await repository.verifyDocuments(vehicleId: 'veh123');

      final lastReq = mockInterceptor.lastRequestOptions;
      expect(lastReq, isNotNull);
      expect(lastReq!.headers['Authorization'], 'Bearer test-token-jwt-123');
      
      // Clean up token
      CarApiService.token = null;
    });

    test('3. OCR analysis request payload structure', () async {
      mockInterceptor.mockResponseData = {
        'success': true,
        'data': {
          'extractedFields': {
            'registrationNumber': 'TN-38-AB-1234',
            'ownerName': 'Alice Smith',
          }
        }
      };

      final result = await repository.analyzeDocument(
        vehicleId: 'veh123',
        documentType: 'rc',
      );

      final lastReq = mockInterceptor.lastRequestOptions;
      expect(lastReq, isNotNull);
      expect(lastReq!.path, '/api/documents/analyze');
      expect(lastReq.data['vehicleId'], 'veh123');
      expect(lastReq.data['documentType'], 'rc');

      expect(result.documentType, 'rc');
      expect(result.extractedFields['registrationNumber'], 'TN-38-AB-1234');
      expect(result.extractedFields['ownerName'], 'Alice Smith');
    });

    test('4. Verification endpoint request payload structure', () async {
      mockInterceptor.mockResponseData = {
        'success': true,
        'data': {
          'overallStatus': 'VERIFIED',
          'overallScore': 95.0,
          'summary': 'All clear',
          'recommendation': 'Approved',
          'validationResults': {},
          'crossValidationResults': {},
        }
      };

      final result = await repository.verifyDocuments(vehicleId: 'veh123');

      final lastReq = mockInterceptor.lastRequestOptions;
      expect(lastReq, isNotNull);
      expect(lastReq!.path, '/api/documents/verify');
      expect(lastReq.data['vehicleId'], 'veh123');

      expect(result.overallStatus, 'VERIFIED');
      expect(result.overallScore, 95.0);
    });

    test('5. Safe fallback structures for null / missing fields', () {
      final nullJson = <String, dynamic>{
        'overallStatus': null,
        'overallScore': null,
        'summary': null,
        'recommendation': null,
        'validationResults': null,
        'crossValidationResults': null,
      };

      final parsed = DocumentVerificationResult.fromJson(nullJson);
      expect(parsed.overallStatus, 'PENDING');
      expect(parsed.overallScore, 0.0);
      expect(parsed.summary, '');
      expect(parsed.recommendation, '');
      expect(parsed.validationResults, isNotNull);
      expect(parsed.crossValidationResults, isNotNull);
    });

    test('6. Handle failed overall verification response mapping', () async {
      mockInterceptor.mockResponseData = {
        'overallStatus': 'NEEDS_ATTENTION',
        'overallScore': 60,
        'summary': 'Insurance expired',
        'recommendation': 'Reject',
        'validationResults': {
          'insurance': {'isValid': false, 'status': 'EXPIRED'}
        },
        'crossValidationResults': {
          'chassisMismatch': {'passed': false, 'message': 'Chassis number mismatch'}
        }
      };

      final result = await repository.verifyDocuments(vehicleId: 'veh123');
      expect(result.overallStatus, 'NEEDS_ATTENTION');
      expect(result.overallScore, 60.0);
      expect(result.validationResults['insurance']['isValid'], false);
      expect(result.crossValidationResults['chassisMismatch']['passed'], false);
    });
  });
}
