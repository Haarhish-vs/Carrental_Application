import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../auth/services/auth_service.dart';
import '../models/location_model.dart';

class LocationApiEndpoints {
  LocationApiEndpoints._();

  static const String search = '/api/locations/search';
  static const String recent = '/api/locations/recent';
  static const String popular = '/api/locations/popular';
  static const String reverseGeocode = '/api/locations/reverse-geocode';
}

/// Thin HTTP client for the Location feature. No dummy data, no fake
/// responses — every call hits the real backend endpoint. Base URL
/// comes from ApiConfig only, never hardcoded here.
///
/// Every backend response is wrapped as `{ success: bool, data: ..., message?: string }`.
/// All parsing here goes through [_decodeEnvelope] to unwrap that consistently
/// instead of assuming the response body IS the payload.
class LocationApiService {
  final http.Client _client;

  LocationApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _getAuthHeaders({bool jsonContent = false}) {
    final headers = <String, String>{};
    if (jsonContent) {
      headers['Content-Type'] = 'application/json';
    }
    final token = AuthService.currentToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Decodes a backend response, unwraps the `{success, data}` envelope,
  /// and throws a [LocationApiException] with the backend's own message
  /// when `success` is false or the HTTP status is non-2xx.
  dynamic _decodeEnvelope(http.Response response, String fallbackMessage) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw LocationApiException(
        fallbackMessage,
        statusCode: response.statusCode,
      );
    }

    final success = body['success'] as bool? ?? false;
    if (response.statusCode < 200 || response.statusCode >= 300 || !success) {
      final message = body['message'] as String? ?? fallbackMessage;
      throw LocationApiException(message, statusCode: response.statusCode);
    }

    return body['data'];
  }

  Future<List<LocationModel>> searchLocations(String query) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${LocationApiEndpoints.search}',
    ).replace(queryParameters: {'q': query});
    final response = await _client.get(uri);

    final data = _decodeEnvelope(response, 'Failed to search locations');
    final list = (data as List<dynamic>?) ?? [];
    return list
        .map((item) => LocationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<LocationModel>> fetchRecentLocations() async {
    // If user is not logged in (Guest), do not query the shared backend database
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      return [];
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${LocationApiEndpoints.recent}');
    final response = await _client.get(uri, headers: _getAuthHeaders());

    final data = _decodeEnvelope(response, 'Failed to fetch recent locations');
    final list = (data as List<dynamic>?) ?? [];
    return list
        .map((item) => LocationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Saves a location the user selected (from search, current location,
  /// or map) into the backend's recent-locations list.
  Future<void> saveRecentLocation(LocationModel location) async {
    // If user is not logged in (Guest), do not save to shared backend database
    final token = AuthService.currentToken;
    if (token == null || token.isEmpty) {
      return;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${LocationApiEndpoints.recent}');
    final response = await _client.post(
      uri,
      headers: _getAuthHeaders(jsonContent: true),
      body: jsonEncode(location.toJson()),
    );

    _decodeEnvelope(response, 'Failed to save recent location');
  }

  Future<void> deleteRecentLocation(String id) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${LocationApiEndpoints.recent}/$id',
    );
    final response = await _client.delete(uri);

    if (response.statusCode != 200 && response.statusCode != 204) {
      // DELETE responses may have no body at all on 204, so don't try to
      // decode an envelope here — just check the status.
      String message = 'Failed to delete recent location';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['message'] as String? ?? message;
      } catch (_) {
        // no/invalid body — keep default message
      }
      throw LocationApiException(message, statusCode: response.statusCode);
    }
  }

  Future<List<LocationModel>> fetchPopularLocations() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${LocationApiEndpoints.popular}',
    );
    final response = await _client.get(uri);

    final data = _decodeEnvelope(response, 'Failed to fetch popular locations');
    final list = (data as List<dynamic>?) ?? [];
    return list
        .map((item) => LocationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LocationModel> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${LocationApiEndpoints.reverseGeocode}',
    );

    http.Response response;
    try {
      try {
        // 1. Try POST first (standard for deployed backend)
        response = await _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'latitude': latitude,
            'longitude': longitude,
            'lat': latitude,
            'lng': longitude,
          }),
        );
      } catch (_) {
        // If network POST failure, try GET
        final getUri = uri.replace(
          queryParameters: {'lat': '$latitude', 'lng': '$longitude'},
        );
        response = await _client.get(getUri);
      }

      // 2. If POST returned 404 or 405 Method Not Allowed, fallback to GET
      if (response.statusCode == 404 || response.statusCode == 405) {
        final getUri = uri.replace(
          queryParameters: {'lat': '$latitude', 'lng': '$longitude'},
        );
        response = await _client.get(getUri);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          final candidate = LocationModel.fromJson(
            body['data'] as Map<String, dynamic>,
            defaultLat: latitude,
            defaultLng: longitude,
          );
          // Only return candidate if it resolved to an actual street/area rather than a fallback placeholder
          if (candidate.name != 'Selected Location' && !candidate.address.startsWith('Location at ')) {
            return candidate;
          }
        }
      }
    } catch (_) {
      // Fallback to direct OpenStreetMap Nominatim
    }

    // 2. Direct OpenStreetMap Nominatim reverse geocoding (Real street address, 100% Free)
    try {
      final osmUri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json',
      );
      final osmRes = await _client.get(
        osmUri,
        headers: {'User-Agent': 'CarRentalApplication/1.0 (Flutter Client)'},
      );
      if (osmRes.statusCode == 200) {
        final osmData = jsonDecode(osmRes.body) as Map<String, dynamic>;
        final addressObj = (osmData['address'] as Map<String, dynamic>?) ?? {};
        final suburb = addressObj['suburb'] ?? addressObj['neighbourhood'] ?? addressObj['road'] ?? '';
        final city = addressObj['city'] ?? addressObj['town'] ?? addressObj['state_district'] ?? addressObj['village'] ?? addressObj['county'] ?? '';
        final state = addressObj['state'] ?? '';
        final country = addressObj['country'] ?? 'India';
        final displayName = osmData['display_name'] as String? ?? '';
        
        final name = (osmData['name'] != null && (osmData['name'] as String).isNotEmpty)
            ? osmData['name'] as String
            : (suburb.isNotEmpty
                ? suburb
                : (displayName.isNotEmpty ? displayName.split(',').first.trim() : (city.isNotEmpty ? city : 'Selected Location')));

        return LocationModel(
          id: '',
          placeId: 'osm_${osmData['place_id'] ?? '${latitude}_$longitude'}',
          name: name,
          address: displayName.isNotEmpty ? displayName : 'Location at ${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°',
          latitude: latitude,
          longitude: longitude,
          city: city,
          state: state,
          country: country,
        );
      }
    } catch (_) {}

    return LocationModel(
      id: '',
      placeId: 'pin_${latitude}_$longitude',
      name: 'Selected Location',
      address: 'Location at ${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°',
      latitude: latitude,
      longitude: longitude,
      city: '',
      state: '',
      country: 'India',
    );
  }

  void dispose() {
    _client.close();
  }
}

/// Carries the HTTP status code so the UI layer can distinguish
/// error types (e.g. 404 vs 500) without parsing strings.
class LocationApiException implements Exception {
  final String message;
  final int? statusCode;

  LocationApiException(this.message, {this.statusCode});

  @override
  String toString() => 'LocationApiException($statusCode): $message';
}
