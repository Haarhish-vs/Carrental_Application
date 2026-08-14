import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import 'app_error.dart';

/// Centralized error-handling service for API, Auth, Network, Booking, and UI operations.
class AppErrorHandler {
  AppErrorHandler._();

  static DateTime? _lastShownTime;
  static String? _lastShownMessage;

  /// Parses any thrown error into a clean, user-friendly [AppError] instance.
  /// Technical details and raw stack traces are logged strictly to developer logs.
  static AppError handle(dynamic error, [StackTrace? stackTrace]) {
    // Log technical details silently for developer diagnostics
    developer.log(
      'AppErrorHandler trapped error: $error',
      name: 'AppErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    if (error is AppError) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error);
    }

    if (error is TimeoutException) {
      return const AppError(
        message: 'The request took too long. Please try again.',
        type: AppErrorType.timeout,
      );
    }

    final errString = error.toString().toLowerCase();

    if (errString.contains('socketexception') ||
        errString.contains('connection refused') ||
        errString.contains('networkisunreachable') ||
        errString.contains('handshakeexception')) {
      return const AppError(
        message: 'Check your internet connection.',
        type: AppErrorType.network,
      );
    }

    if (errString.contains('payment cancelled') ||
        errString.contains('payment_cancelled')) {
      return const AppError(
        message: 'Payment was cancelled.',
        type: AppErrorType.payment,
      );
    }

    if (errString.contains('payment failed') ||
        errString.contains('payment_failed')) {
      return const AppError(
        message: 'Payment failed. Please try again or use another payment method.',
        type: AppErrorType.payment,
      );
    }

    // Clean up raw Exception: prefix if present
    String rawMsg = error.toString();
    if (rawMsg.startsWith('Exception: ')) {
      rawMsg = rawMsg.substring(11).trim();
    }

    // Sanitize raw technical exception text
    if (_isRawTechnicalMessage(rawMsg)) {
      return const AppError(
        message: 'Something went wrong. Please try again.',
        type: AppErrorType.unknown,
        technicalDetails: null,
      );
    }

    return AppError(
      message: rawMsg.isNotEmpty
          ? rawMsg
          : 'Something went wrong. Please try again.',
      type: AppErrorType.unknown,
    );
  }

  /// Maps DioException to exact user-facing AppError
  static AppError _handleDioError(DioException dioError) {
    if (dioError.type == DioExceptionType.connectionTimeout ||
        dioError.type == DioExceptionType.sendTimeout ||
        dioError.type == DioExceptionType.receiveTimeout) {
      return const AppError(
        message: 'The request took too long. Please try again.',
        type: AppErrorType.timeout,
      );
    }

    if (dioError.type == DioExceptionType.connectionError) {
      return const AppError(
        message: 'Check your internet connection.',
        type: AppErrorType.network,
      );
    }

    final response = dioError.response;
    if (response != null) {
      final statusCode = response.statusCode;
      final data = response.data;
      String? backendMsg;

      if (data is Map) {
        backendMsg = data['message']?.toString() ?? data['error']?.toString();
      }

      switch (statusCode) {
        case 400:
          return AppError(
            message: _sanitizeBackendMsg(
              backendMsg,
              defaultMsg: 'Please check the information you entered.',
            ),
            type: AppErrorType.validation,
            statusCode: 400,
          );
        case 401:
          return const AppError(
            message: 'Your session has expired. Please login again.',
            type: AppErrorType.unauthorized,
            statusCode: 401,
          );
        case 403:
          return const AppError(
            message: "You don't have permission to perform this action.",
            type: AppErrorType.forbidden,
            statusCode: 403,
          );
        case 404:
          return AppError(
            message: _sanitizeBackendMsg(
              backendMsg,
              defaultMsg: 'The requested information could not be found.',
            ),
            type: AppErrorType.notFound,
            statusCode: 404,
          );
        case 409:
          return AppError(
            message: _sanitizeBackendMsg(
              backendMsg,
              defaultMsg: 'Reservation or request already exists.',
            ),
            type: AppErrorType.conflict,
            statusCode: 409,
          );
        case 429:
          return const AppError(
            message: 'Too many requests. Please try again later.',
            type: AppErrorType.tooManyRequests,
            statusCode: 429,
          );
        case 500:
        case 502:
        case 503:
        case 504:
          return const AppError(
            message: 'Something went wrong on our server. Please try again.',
            type: AppErrorType.server,
            statusCode: 500,
          );
        default:
          return AppError(
            message: _sanitizeBackendMsg(
              backendMsg,
              defaultMsg: 'Something went wrong. Please try again.',
            ),
            type: AppErrorType.unknown,
            statusCode: statusCode,
          );
      }
    }

    return const AppError(
      message: 'Check your internet connection.',
      type: AppErrorType.network,
    );
  }

  /// Maps Firebase Auth errors to clean user messages
  static AppError _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return const AppError(
          message: 'Invalid phone number format. Please check.',
          type: AppErrorType.auth,
        );
      case 'invalid-verification-code':
        return const AppError(
          message: 'Invalid OTP entered. Please try again.',
          type: AppErrorType.auth,
        );
      case 'session-expired':
        return const AppError(
          message: 'OTP has expired. Please request a new code.',
          type: AppErrorType.auth,
        );
      case 'quota-exceeded':
      case 'too-many-requests':
        return const AppError(
          message: 'Too many attempts. Please try again later.',
          type: AppErrorType.tooManyRequests,
        );
      case 'user-disabled':
        return const AppError(
          message: 'This account has been disabled. Please contact support.',
          type: AppErrorType.auth,
        );
      default:
        return const AppError(
          message: 'Authentication failed. Please try again.',
          type: AppErrorType.auth,
        );
    }
  }

  /// Displays an app-themed, subtle floating SnackBar for an error with duplicate protection.
  static void show(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
  }) {
    final appError = handle(error);
    final now = DateTime.now();

    // Prevent duplicate spamming within 1.5 seconds
    if (_lastShownMessage == appError.message &&
        _lastShownTime != null &&
        now.difference(_lastShownTime!).inMilliseconds < 1500) {
      return;
    }

    _lastShownMessage = appError.message;
    _lastShownTime = now;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                appError.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: AppColors.primary,
                onPressed: onRetry,
              )
            : null,
        backgroundColor: const Color(0xFF1E293B), // Subtle slate dark surface
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Displays an app-themed floating success toast
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Displays an app-themed floating info toast
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Helper to convert any error into a user-friendly string for widget states.
  static String getErrorMessage(dynamic error) {
    return handle(error).message;
  }

  /// Sanitizes backend response text so raw stack traces or internal DB details are omitted.
  static String _sanitizeBackendMsg(String? raw, {required String defaultMsg}) {
    if (raw == null || raw.trim().isEmpty) return defaultMsg;
    final trimmed = raw.trim();

    if (_isRawTechnicalMessage(trimmed)) {
      return defaultMsg;
    }
    return trimmed;
  }

  /// Checks if a string contains raw internal error indicators
  static bool _isRawTechnicalMessage(String text) {
    final lower = text.toLowerCase();
    return lower.contains('axioserror') ||
        lower.contains('socketexception') ||
        lower.contains('dioexception') ||
        lower.contains('typeerror') ||
        lower.contains('nullcheckoperator') ||
        lower.contains('nosuchmethoderror') ||
        lower.contains('500 internal server error') ||
        lower.contains('route not found') ||
        lower.contains('mongodb') ||
        lower.contains('mongoose') ||
        lower.contains('sql') ||
        lower.contains('econnrefused') ||
        lower.contains('stack trace') ||
        lower.contains('html');
  }
}
