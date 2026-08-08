import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String baseUrl = kDebugMode
      ? 'http://localhost:5000'
      : 'https://carrental-application-1.onrender.com';
}
