import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/location_model.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/services/location_api_service.dart';

/// Generic status for any async section of state managed by this provider.
enum LocationLoadStatus { idle, loading, success, error }

/// Distinguishes *why* current-location resolution failed, so the UI
/// layer can decide between a SnackBar (generic/API failure) and an
/// AlertDialog (permission / service issues) without parsing strings.
enum CurrentLocationErrorType {
  none,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  reverseGeocodeFailed,
  unknown,
}

/// Holds all state for the Location feature. Pure business logic —
/// no BuildContext, no Navigator, no widgets. UI reads state via
/// ChangeNotifier and calls these methods; it decides how to present
/// loading/error states.
class LocationProvider extends ChangeNotifier {
  final LocationRepository _repository;
  Timer? _debounce;

  LocationProvider({required LocationRepository repository}) : _repository = repository;

  // ---------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------

  List<LocationModel> searchResults = [];
  LocationLoadStatus searchStatus = LocationLoadStatus.idle;
  String? searchError;

  /// Call on every keystroke from the search field. Debounces internally
  /// (500ms) — do not add extra delay logic in the UI layer.
  void searchLocations(String query) {
    _debounce?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      searchResults = [];
      searchStatus = LocationLoadStatus.idle;
      searchError = null;
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () => _performSearch(trimmed));
  }

  Future<void> _performSearch(String query) async {
    searchStatus = LocationLoadStatus.loading;
    searchError = null;
    notifyListeners();

    try {
      final results = await _repository.searchLocations(query);
      searchResults = results;
      searchStatus = LocationLoadStatus.success;
    } on LocationApiException catch (e) {
      searchError = e.message;
      searchStatus = LocationLoadStatus.error;
    } catch (e) {
      searchError = 'Something went wrong while searching.';
      searchStatus = LocationLoadStatus.error;
    }
    notifyListeners();
  }

  /// Clears search results/state immediately (e.g. when the user taps
  /// the clear button). Cancels any pending debounced search too.
  void clearSearch() {
    _debounce?.cancel();
    searchResults = [];
    searchStatus = LocationLoadStatus.idle;
    searchError = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Recent Locations
  // ---------------------------------------------------------------------

  List<LocationModel> recentLocations = [];
  LocationLoadStatus recentStatus = LocationLoadStatus.idle;
  String? recentError;

  Future<void> loadRecentLocations() async {
    recentStatus = LocationLoadStatus.loading;
    recentError = null;
    notifyListeners();

    try {
      recentLocations = await _repository.getRecentLocations();
      recentStatus = LocationLoadStatus.success;
    } on LocationApiException catch (e) {
      recentError = e.message;
      recentStatus = LocationLoadStatus.error;
    } catch (e) {
      recentError = 'Could not load recent locations.';
      recentStatus = LocationLoadStatus.error;
    }
    notifyListeners();
  }

  /// Persists [location] to the backend's recent-locations list and
  /// updates local state without a full reload. Safe to call for any
  /// location the user selects (search result, current location, or
  /// a dropped map pin) — callers do not need to worry about dedup.
  Future<void> saveRecentLocation(LocationModel location) async {
    try {
      await _repository.saveRecentLocation(location);

      recentLocations = [
        location,
        ...recentLocations.where((existing) => existing.placeId != location.placeId),
      ];
      notifyListeners();
    } on LocationApiException {
      // Saving to "recent" is a background convenience action — a
      // failure here should not block the user's selection flow.
      // Local list is left untouched; next loadRecentLocations() will
      // reconcile with the backend.
    } catch (_) {
      // Same reasoning as above — swallow silently.
    }
  }

  Future<void> deleteRecentLocation(String id) async {
    final previous = recentLocations;
    recentLocations = recentLocations.where((location) => location.id != id).toList();
    notifyListeners();

    try {
      await _repository.deleteRecentLocation(id);
    } on LocationApiException catch (e) {
      // Roll back on failure so the UI doesn't show a stale/incorrect list.
      recentLocations = previous;
      recentError = e.message;
      notifyListeners();
    } catch (e) {
      recentLocations = previous;
      recentError = 'Could not delete this location.';
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------
  // Popular Locations
  // ---------------------------------------------------------------------

  List<LocationModel> popularLocations = [];
  LocationLoadStatus popularStatus = LocationLoadStatus.idle;
  String? popularError;

  Future<void> loadPopularLocations() async {
    popularStatus = LocationLoadStatus.loading;
    popularError = null;
    notifyListeners();

    try {
      popularLocations = await _repository.getPopularLocations();
      popularStatus = LocationLoadStatus.success;
    } on LocationApiException catch (e) {
      popularError = e.message;
      popularStatus = LocationLoadStatus.error;
    } catch (e) {
      popularError = 'Could not load popular locations.';
      popularStatus = LocationLoadStatus.error;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Current Location
  // ---------------------------------------------------------------------

  LocationModel? currentLocation;
  LocationLoadStatus currentLocationStatus = LocationLoadStatus.idle;
  String? currentLocationError;
  CurrentLocationErrorType currentLocationErrorType = CurrentLocationErrorType.none;

  /// Runs the full flow: service check -> permission check/request ->
  /// GPS fix -> backend reverse geocode -> [currentLocation] populated.
  /// UI is responsible for presenting [currentLocationErrorType]
  /// appropriately (dialog vs snackbar) and for the "confirm" bottom
  /// sheet step — this method only resolves the location.
  Future<void> requestCurrentLocation() async {
    currentLocationStatus = LocationLoadStatus.loading;
    currentLocationError = null;
    currentLocationErrorType = CurrentLocationErrorType.none;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        currentLocationErrorType = CurrentLocationErrorType.serviceDisabled;
        currentLocationError = 'Location services are disabled.';
        currentLocationStatus = LocationLoadStatus.error;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          currentLocationErrorType = CurrentLocationErrorType.permissionDenied;
          currentLocationError = 'Location permission was denied.';
          currentLocationStatus = LocationLoadStatus.error;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        currentLocationErrorType = CurrentLocationErrorType.permissionDeniedForever;
        currentLocationError = 'Location permission is permanently denied.';
        currentLocationStatus = LocationLoadStatus.error;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      try {
        final resolved = await _repository.reverseGeocode(position.latitude, position.longitude);
        currentLocation = resolved;
        currentLocationStatus = LocationLoadStatus.success;
      } on LocationApiException catch (e) {
        currentLocationErrorType = CurrentLocationErrorType.reverseGeocodeFailed;
        currentLocationError = e.message;
        currentLocationStatus = LocationLoadStatus.error;
      }
    } catch (e) {
      currentLocationErrorType = CurrentLocationErrorType.unknown;
      currentLocationError = 'Could not detect your current location.';
      currentLocationStatus = LocationLoadStatus.error;
    }
    notifyListeners();
  }

  /// Resets current-location state (e.g. when the user dismisses the
  /// confirmation bottom sheet via "Choose Another Location").
  void clearCurrentLocation() {
    currentLocation = null;
    currentLocationStatus = LocationLoadStatus.idle;
    currentLocationError = null;
    currentLocationErrorType = CurrentLocationErrorType.none;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Map Reverse Geocoding
  // ---------------------------------------------------------------------

  LocationModel? mapResolvedLocation;
  LocationLoadStatus mapReverseGeocodeStatus = LocationLoadStatus.idle;
  String? mapReverseGeocodeError;

  /// Called whenever the map's center point settles (e.g. on camera
  /// idle). Resolves and stores the address so the map screen's bottom
  /// sheet can always show the current center's address before the
  /// user taps Confirm.
  Future<LocationModel?> reverseGeocode(double latitude, double longitude) async {
    mapReverseGeocodeStatus = LocationLoadStatus.loading;
    mapReverseGeocodeError = null;
    notifyListeners();

    try {
      final resolved = await _repository.reverseGeocode(latitude, longitude);
      mapResolvedLocation = resolved;
      mapReverseGeocodeStatus = LocationLoadStatus.success;
      notifyListeners();
      return resolved;
    } on LocationApiException catch (e) {
      mapReverseGeocodeError = e.message;
      mapReverseGeocodeStatus = LocationLoadStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      mapReverseGeocodeError = 'Could not resolve this location.';
      mapReverseGeocodeStatus = LocationLoadStatus.error;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}