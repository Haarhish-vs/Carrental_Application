import 'package:image_picker/image_picker.dart';
import '../models/document_verification_models.dart';
import '../services/document_verification_service.dart';

class DocumentVerificationRepository {
  final DocumentVerificationService _service;

  DocumentVerificationRepository({DocumentVerificationService? service})
    : _service = service ?? DocumentVerificationService();

  Future<void> uploadDocuments({
    required String vehicleId,
    XFile? rc,
    XFile? insurance,
    XFile? fc,
    XFile? puc,
    XFile? permit,
  }) async {
    final response = await _service.uploadDocuments(
      vehicleId: vehicleId,
      rc: rc,
      insurance: insurance,
      fc: fc,
      puc: puc,
      permit: permit,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        response.data?['message'] ?? 'Failed to upload documents',
      );
    }
  }

  Future<DocumentAnalysisResult> analyzeDocument({
    required String vehicleId,
    required String documentType,
  }) async {
    final response = await _service.analyzeDocument(
      vehicleId: vehicleId,
      documentType: documentType,
    );

    if (response.statusCode == 200 && response.data != null) {
      return DocumentAnalysisResult.fromJson(response.data!, documentType);
    }
    throw Exception(
      response.data?['message'] ?? 'Failed to analyze document $documentType',
    );
  }

  Future<DocumentVerificationResult> verifyDocuments({
    required String vehicleId,
  }) async {
    final response = await _service.verifyDocuments(vehicleId: vehicleId);

    if (response.statusCode == 200 && response.data != null) {
      return DocumentVerificationResult.fromJson(response.data!);
    }
    throw Exception(response.data?['message'] ?? 'Failed to verify documents');
  }
}
