enum AppErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  tooManyRequests,
  server,
  auth,
  booking,
  payment,
  validation,
  unknown,
}

class AppError implements Exception {
  final String message;
  final AppErrorType type;
  final int? statusCode;
  final String? technicalDetails;

  const AppError({
    required this.message,
    required this.type,
    this.statusCode,
    this.technicalDetails,
  });

  @override
  String toString() => message;
}
