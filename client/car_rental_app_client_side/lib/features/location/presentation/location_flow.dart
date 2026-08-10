import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/location_model.dart';
import '../data/repositories/location_repository.dart';
import '../data/services/location_api_service.dart';
import 'providers/location_provider.dart';
import 'screens/location_screen.dart';

/// Single entry point for the whole location-selection flow.
///
/// Creates ONE LocationProvider for the entire flow (search, current
/// location, map, confirmation) and disposes it once the flow ends —
/// whichever screen it ends on. Every screen pushed as part of this
/// flow re-attaches this same instance via ChangeNotifierProvider.value,
/// which is what fixes ProviderNotFoundException across nested pushes.
class LocationFlow {
  LocationFlow._();

  static Future<LocationModel?> start(BuildContext context) async {
    final provider = LocationProvider(
      repository: LocationRepository(apiService: LocationApiService()),
    );

    final result = await Navigator.of(context).push<LocationModel>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<LocationProvider>.value(
          value: provider,
          child: const LocationScreen(),
        ),
      ),
    );

    provider.dispose();
    return result;
  }
}
