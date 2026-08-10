enum DocumentVerificationStatus {
  notUploaded,
  uploading,
  uploaded,
  analyzing,
  analyzed,
  verifying,
  verified,
  failed,
}

class DocumentAnalysisResult {
  final String documentType;
  final Map<String, dynamic> extractedFields;

  DocumentAnalysisResult({
    required this.documentType,
    required this.extractedFields,
  });

  factory DocumentAnalysisResult.fromJson(
    Map<String, dynamic> json,
    String docType,
  ) {
    // Safely look inside common response wraps
    final data = json['data'] ?? json;
    final fields = data is Map ? (data['extractedFields'] ?? data) : {};
    return DocumentAnalysisResult(
      documentType: docType,
      extractedFields: Map<String, dynamic>.from(fields is Map ? fields : {}),
    );
  }
}

class DocumentVerificationResult {
  final String overallStatus; // e.g., 'VERIFIED', 'FAILED', 'NEEDS_ATTENTION'
  final double overallScore; // e.g., 95.0
  final String summary;
  final String recommendation;
  final Map<String, dynamic> validationResults;
  final Map<String, dynamic> crossValidationResults;

  DocumentVerificationResult({
    required this.overallStatus,
    required this.overallScore,
    required this.summary,
    required this.recommendation,
    required this.validationResults,
    required this.crossValidationResults,
  });

  factory DocumentVerificationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    double score = 0.0;
    final rawScore = data['overallScore'];
    if (rawScore is num) {
      score = rawScore.toDouble();
    } else if (rawScore is String) {
      score = double.tryParse(rawScore) ?? 0.0;
    }

    return DocumentVerificationResult(
      overallStatus: (data['overallStatus'] ?? 'PENDING').toString(),
      overallScore: score,
      summary: (data['summary'] ?? '').toString(),
      recommendation: (data['recommendation'] ?? '').toString(),
      validationResults: Map<String, dynamic>.from(
        data['validationResults'] is Map ? data['validationResults'] : {},
      ),
      crossValidationResults: Map<String, dynamic>.from(
        data['crossValidationResults'] is Map
            ? data['crossValidationResults']
            : {},
      ),
    );
  }
}

class DocumentVerificationState {
  final String? vehicleId;
  final double uploadProgress;
  final Map<String, DocumentVerificationStatus> documentStatuses;
  final Map<String, DocumentAnalysisResult> analysisResults;
  final DocumentVerificationResult? verificationResult;
  final String? errorMessage;
  final bool isUploading;
  final bool isAnalyzing;
  final bool isVerifying;

  DocumentVerificationState({
    this.vehicleId,
    this.uploadProgress = 0.0,
    this.documentStatuses = const {},
    this.analysisResults = const {},
    this.verificationResult,
    this.errorMessage,
    this.isUploading = false,
    this.isAnalyzing = false,
    this.isVerifying = false,
  });

  DocumentVerificationState copyWith({
    String? Function()? vehicleId,
    double? uploadProgress,
    Map<String, DocumentVerificationStatus>? documentStatuses,
    Map<String, DocumentAnalysisResult>? analysisResults,
    DocumentVerificationResult? Function()? verificationResult,
    String? Function()? errorMessage,
    bool? isUploading,
    bool? isAnalyzing,
    bool? isVerifying,
  }) {
    return DocumentVerificationState(
      vehicleId: vehicleId != null ? vehicleId() : this.vehicleId,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      documentStatuses: documentStatuses ?? this.documentStatuses,
      analysisResults: analysisResults ?? this.analysisResults,
      verificationResult: verificationResult != null
          ? verificationResult()
          : this.verificationResult,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isUploading: isUploading ?? this.isUploading,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isVerifying: isVerifying ?? this.isVerifying,
    );
  }
}

class PdfDocumentValidator {
  static String? validatePdf(
    String filename,
    String? mimeType,
    int bytesLength, {
    int maxSizeMb = 10,
  }) {
    final fileExt = filename.split('.').last.toLowerCase();
    final allowedExts = ['pdf', 'jpg', 'jpeg', 'png'];
    if (!allowedExts.contains(fileExt)) {
      return "Only PDF and image (JPG, PNG) documents are accepted.";
    }

    if (mimeType != null &&
        mimeType.isNotEmpty &&
        !['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'].contains(mimeType)) {
      return "Only PDF and image (JPG, PNG) documents are accepted.";
    }

    if (bytesLength <= 0) {
      return "This document appears to be empty or unreadable.";
    }

    final maxSizeInBytes = maxSizeMb * 1024 * 1024;
    if (bytesLength > maxSizeInBytes) {
      return "This document exceeds the allowed file size.";
    }

    return null;
  }
}
