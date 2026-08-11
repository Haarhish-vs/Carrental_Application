/// Per-vehicle usage summary — how many trips a customer has taken in a
/// given vehicle, and (when the backend provides it) that vehicle's
/// odometer reading as a stand-in for "distance covered".
///
/// [distanceKm] is intentionally nullable: the current booking API does
/// not return a per-trip distance field, only the vehicle's
/// `odometerReading` at listing time. We surface that when present
/// instead of inventing a number, and simply hide the distance row in
/// the UI when it isn't available. Once the backend adds a real
/// per-trip distance field, populate it here and the UI updates for
/// free.
class VehicleUsage {
  const VehicleUsage({
    required this.vehicleName,
    required this.tripCount,
    this.distanceKm,
  });

  final String vehicleName;
  final int tripCount;
  final double? distanceKm;
}

/// Compact "Trip Insights" summary — total trips plus most/least used
/// vehicle, computed directly from the customer's real bookings list
/// (no mock data).
class TripInsights {
  const TripInsights({
    required this.totalTrips,
    required this.usageByVehicle,
    this.mostUsed,
    this.leastUsed,
  });

  final int totalTrips;
  final List<VehicleUsage> usageByVehicle;
  final VehicleUsage? mostUsed;
  final VehicleUsage? leastUsed;

  static const empty = TripInsights(totalTrips: 0, usageByVehicle: []);

  /// Builds insights from the same `getMyBookings()` response the My
  /// Bookings ("My Trips") screen already fetches.
  factory TripInsights.fromBookings(List<Map<String, dynamic>> bookings) {
    if (bookings.isEmpty) return empty;

    final Map<String, VehicleUsage> byVehicle = {};

    for (final booking in bookings) {
      final vehicle = booking['vehicle'] as Map<String, dynamic>? ?? const {};
      final brand = vehicle['brand']?.toString() ?? '';
      final model = vehicle['model']?.toString() ?? '';
      final name = [brand, model].where((p) => p.isNotEmpty).join(' ').trim();
      final displayName = name.isEmpty ? 'Vehicle' : name;

      final rawOdometer = vehicle['odometerReading'] ?? vehicle['odometer_reading'];
      final distance = rawOdometer is num
          ? rawOdometer.toDouble()
          : double.tryParse(rawOdometer?.toString() ?? '');

      final existing = byVehicle[displayName];
      byVehicle[displayName] = VehicleUsage(
        vehicleName: displayName,
        tripCount: (existing?.tripCount ?? 0) + 1,
        distanceKm: existing?.distanceKm ?? distance,
      );
    }

    final list = byVehicle.values.toList()
      ..sort((a, b) => b.tripCount.compareTo(a.tripCount));

    return TripInsights(
      totalTrips: bookings.length,
      usageByVehicle: list,
      mostUsed: list.isNotEmpty ? list.first : null,
      leastUsed: list.length > 1 ? list.last : null,
    );
  }
}
