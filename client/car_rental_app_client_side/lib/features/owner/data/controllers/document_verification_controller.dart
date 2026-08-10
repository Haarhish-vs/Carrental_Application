import 'package:image_picker/image_picker.dart';
import '../models/document_verification_models.dart';
import '../repositories/document_verification_repository.dart';

class DocumentVerificationController {
  // Singleton pattern for memory persistence across registration wizard steps
  static final DocumentVerificationController instance =
      DocumentVerificationController._();
  DocumentVerificationController._();

  final DocumentVerificationRepository _repository =
      DocumentVerificationRepository();
  DocumentVerificationState _state = DocumentVerificationState();

  DocumentVerificationState get state => _state;

  final List<void Function(DocumentVerificationState)> _listeners = [];

  void addListener(void Function(DocumentVerificationState) listener) {
    _listeners.add(listener);
    listener(_state);
  }

  void removeListener(void Function(DocumentVerificationState) listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in _listeners) {
      listener(_state);
    }
  }

  void reset() {
    _state = DocumentVerificationState();
    _notify();
  }

  /// Triggers the document upload, OCR analysis, and overall verification workflow.
  /// Handles partial retries by skipping already verified/analyzed documents.
  Future<void> startVerificationFlow({
    required String vehicleId,
    XFile? rc,
    XFile? insurance,
    XFile? fc,
    XFile? puc,
    XFile? permit,
  }) async {
    _state = _state.copyWith(
      vehicleId: () => vehicleId,
      isUploading: true,
      errorMessage: () => null,
    );
    _notify();

    try {
      // Initialize statuses based on file existence
      final initialStatuses = Map<String, DocumentVerificationStatus>.from(
        _state.documentStatuses,
      );
      if (rc != null &&
          initialStatuses['rc'] != DocumentVerificationStatus.verified) {
        initialStatuses['rc'] = DocumentVerificationStatus.uploading;
      }
      if (insurance != null &&
          initialStatuses['insurance'] != DocumentVerificationStatus.verified) {
        initialStatuses['insurance'] = DocumentVerificationStatus.uploading;
      }
      if (fc != null &&
          initialStatuses['fc'] != DocumentVerificationStatus.verified) {
        initialStatuses['fc'] = DocumentVerificationStatus.uploading;
      }
      if (puc != null &&
          initialStatuses['puc'] != DocumentVerificationStatus.verified) {
        initialStatuses['puc'] = DocumentVerificationStatus.uploading;
      }
      if (permit != null &&
          initialStatuses['permit'] != DocumentVerificationStatus.verified) {
        initialStatuses['permit'] = DocumentVerificationStatus.uploading;
      }

      _state = _state.copyWith(documentStatuses: initialStatuses);
      _notify();

      // Filter and only upload files that need uploading (status == uploading)
      final rcFile =
          _state.documentStatuses['rc'] == DocumentVerificationStatus.uploading
          ? rc
          : null;
      final insFile =
          _state.documentStatuses['insurance'] ==
              DocumentVerificationStatus.uploading
          ? insurance
          : null;
      final fcFile =
          _state.documentStatuses['fc'] == DocumentVerificationStatus.uploading
          ? fc
          : null;
      final pucFile =
          _state.documentStatuses['puc'] == DocumentVerificationStatus.uploading
          ? puc
          : null;
      final permitFile =
          _state.documentStatuses['permit'] ==
              DocumentVerificationStatus.uploading
          ? permit
          : null;

      if (rcFile != null ||
          insFile != null ||
          fcFile != null ||
          pucFile != null ||
          permitFile != null) {
        await _repository.uploadDocuments(
          vehicleId: vehicleId,
          rc: rcFile,
          insurance: insFile,
          fc: fcFile,
          puc: pucFile,
          permit: permitFile,
        );
      }

      // Mark uploaded files as uploaded
      final postUploadStatuses = Map<String, DocumentVerificationStatus>.from(
        _state.documentStatuses,
      );
      if (rcFile != null) {
        postUploadStatuses['rc'] = DocumentVerificationStatus.uploaded;
      }
      if (insFile != null) {
        postUploadStatuses['insurance'] = DocumentVerificationStatus.uploaded;
      }
      if (fcFile != null) {
        postUploadStatuses['fc'] = DocumentVerificationStatus.uploaded;
      }
      if (pucFile != null) {
        postUploadStatuses['puc'] = DocumentVerificationStatus.uploaded;
      }
      if (permitFile != null) {
        postUploadStatuses['permit'] = DocumentVerificationStatus.uploaded;
      }

      _state = _state.copyWith(
        isUploading: false,
        isAnalyzing: true,
        documentStatuses: postUploadStatuses,
      );
      _notify();

      // Step 2: Analyze each document sequentially
      final docTypes = ['rc', 'insurance', 'fc', 'puc', 'permit'];
      final Map<String, DocumentAnalysisResult> currentAnalysisResults =
          Map.from(_state.analysisResults);

      for (final docType in docTypes) {
        final currentStatus = _state.documentStatuses[docType];

        // Analyze if the file was just uploaded or is not verified yet but we have it
        if (currentStatus == DocumentVerificationStatus.uploaded ||
            currentStatus == DocumentVerificationStatus.failed ||
            (currentStatus == null &&
                _hasFileForType(docType, rc, insurance, fc, puc, permit))) {
          final statuses = Map<String, DocumentVerificationStatus>.from(
            _state.documentStatuses,
          );
          statuses[docType] = DocumentVerificationStatus.analyzing;
          _state = _state.copyWith(documentStatuses: statuses);
          _notify();

          try {
            final result = await _repository.analyzeDocument(
              vehicleId: vehicleId,
              documentType: docType,
            );

            final finalStatuses = Map<String, DocumentVerificationStatus>.from(
              _state.documentStatuses,
            );
            finalStatuses[docType] = DocumentVerificationStatus.analyzed;
            currentAnalysisResults[docType] = result;

            _state = _state.copyWith(
              documentStatuses: finalStatuses,
              analysisResults: currentAnalysisResults,
            );
            _notify();
          } catch (e) {
            final finalStatuses = Map<String, DocumentVerificationStatus>.from(
              _state.documentStatuses,
            );
            finalStatuses[docType] = DocumentVerificationStatus.failed;

            _state = _state.copyWith(
              documentStatuses: finalStatuses,
              isAnalyzing: false,
              errorMessage: () =>
                  'Analysis failed for $docType: ${e.toString().replaceAll('Exception:', '').trim()}',
            );
            _notify();
            return;
          }
        }
      }

      // Step 3: Run final verification check
      _state = _state.copyWith(isAnalyzing: false, isVerifying: true);
      _notify();

      final verificationResult = await _repository.verifyDocuments(
        vehicleId: vehicleId,
      );

      // Map overall verification results back to document statuses
      final finalStatuses = Map<String, DocumentVerificationStatus>.from(
        _state.documentStatuses,
      );

      for (final docType in docTypes) {
        if (finalStatuses[docType] == DocumentVerificationStatus.analyzed ||
            finalStatuses[docType] == DocumentVerificationStatus.verified ||
            finalStatuses[docType] == DocumentVerificationStatus.failed) {
          final docValidation = verificationResult.validationResults[docType];
          final isValid =
              docValidation == null ||
              (docValidation is Map &&
                  (docValidation['isValid'] == true ||
                      docValidation['status'] == 'VALID' ||
                      docValidation['status'] == 'success'));

          finalStatuses[docType] = isValid
              ? DocumentVerificationStatus.verified
              : DocumentVerificationStatus.failed;
        }
      }

      _state = _state.copyWith(
        isVerifying: false,
        documentStatuses: finalStatuses,
        verificationResult: () => verificationResult,
      );
      _notify();
    } catch (e) {
      _state = _state.copyWith(
        isUploading: false,
        isAnalyzing: false,
        isVerifying: false,
        errorMessage: () => e.toString().replaceAll('Exception:', '').trim(),
      );
      _notify();
    }
  }

  bool _hasFileForType(
    String docType,
    XFile? rc,
    XFile? insurance,
    XFile? fc,
    XFile? puc,
    XFile? permit,
  ) {
    if (docType == 'rc') {
      return rc != null;
    }
    if (docType == 'insurance') {
      return insurance != null;
    }
    if (docType == 'fc') {
      return fc != null;
    }
    if (docType == 'puc') {
      return puc != null;
    }
    if (docType == 'permit') {
      return permit != null;
    }
    return false;
  }
}
