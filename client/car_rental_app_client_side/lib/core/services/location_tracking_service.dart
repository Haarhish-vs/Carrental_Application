import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/owner/data/services/car_api_service.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  StreamSubscription<Position>? _positionStreamSub;
  String? _activeBookingId;
  DateTime? _lastSentTime;

  /// Start tracking GPS location for an active booking ID
  Future<void> startTracking(String bookingId) async {
    if (bookingId.isEmpty) return;

    if (_activeBookingId == bookingId && _positionStreamSub != null) {
      // Force an immediate location push if already tracking
      _lastSentTime = null;
      _pushCurrentLocation();
      return;
    }

    stopTracking(); // Stop any previous tracking session
    _activeBookingId = bookingId;
    _lastSentTime = null; // Reset so initial position sends immediately

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permissions are permanently denied.');
        return;
      }

      // Stream position updates with high accuracy and small distance filter
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Send update every 3 meters
      );

      _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          _onLocationUpdated(position);
        },
        onError: (err) {
          debugPrint('❌ Error tracking location stream: $err');
        },
      );

      // Immediately push initial current position
      await _pushCurrentLocation();
      debugPrint('📍 Live GPS location tracking active for booking: $bookingId');
    } catch (e) {
      debugPrint('⚠️ Error starting location tracking: $e');
    }
  }

  Future<void> _pushCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _onLocationUpdated(position, force: true);
    } catch (e) {
      debugPrint('⚠️ Error getting current position: $e');
    }
  }

  void _onLocationUpdated(Position position, {bool force = false}) {
    if (_activeBookingId == null) return;

    // Rate-limit API calls to once every 3 seconds unless forced
    final now = DateTime.now();
    if (!force && _lastSentTime != null && now.difference(_lastSentTime!).inSeconds < 3) {
      return;
    }
    _lastSentTime = now;

    CarApiService().updateBookingLocation(_activeBookingId!, position.latitude, position.longitude).then((_) {
      debugPrint('🛰️ Pushed live location [${position.latitude}, ${position.longitude}] for booking $_activeBookingId');
    }).catchError((err) {
      debugPrint('⚠️ Failed to push location update: $err');
    });
  }

  /// Stop live location tracking
  void stopTracking() {
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    _activeBookingId = null;
    _lastSentTime = null;
    debugPrint('🛑 Live location tracking stopped.');
  }
}
