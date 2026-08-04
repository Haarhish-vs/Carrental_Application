import 'dart:developer' as developer;
import '../config/feature_flags.dart';

abstract class AnalyticsService {
  void logEvent(String name, {Map<String, dynamic>? parameters});
  void logScreenView(String screenName);
}

class MockAnalyticsService implements AnalyticsService {
  @override
  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    if (FeatureFlags.enableMockTelemetry) {
      developer.log("ANALYTICS: Event logged: '$name' with parameters: $parameters");
    }
  }

  @override
  void logScreenView(String screenName) {
    if (FeatureFlags.enableMockTelemetry) {
      developer.log("ANALYTICS: Screen View: '$screenName'");
    }
  }
}
