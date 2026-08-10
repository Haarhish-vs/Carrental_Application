import '../models/location_model.dart';
import '../services/location_api_service.dart';

/// All HTTP calls stay behind this layer — Provider never talks to
/// LocationApiService directly.
class LocationRepository {
  final LocationApiService _apiService;

  LocationRepository({required LocationApiService apiService})
    : _apiService = apiService;

  Future<List<LocationModel>> searchLocations(String query) {
    return _apiService.searchLocations(query);
  }

  Future<List<LocationModel>> getRecentLocations() {
    return _apiService.fetchRecentLocations();
  }

  Future<void> saveRecentLocation(LocationModel location) {
    return _apiService.saveRecentLocation(location);
  }

  Future<void> deleteRecentLocation(String id) {
    return _apiService.deleteRecentLocation(id);
  }

  Future<List<LocationModel>> getPopularLocations() {
    return _apiService.fetchPopularLocations();
  }

  Future<LocationModel> reverseGeocode(double latitude, double longitude) {
    return _apiService.reverseGeocode(latitude, longitude);
  }
}
