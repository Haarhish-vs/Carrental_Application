class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://carrental-application-z49a.onrender.com',
  );

  static const String documentVerificationBaseUrl = String.fromEnvironment(
    'DOCUMENT_VERIFICATION_BASE_URL',
    defaultValue: 'https://carrental-application-z49a.onrender.com',
  );

  static const int maxDocumentPdfSizeMb = int.fromEnvironment(
    'MAX_DOCUMENT_PDF_SIZE_MB',
    defaultValue: 10,
  );
}
