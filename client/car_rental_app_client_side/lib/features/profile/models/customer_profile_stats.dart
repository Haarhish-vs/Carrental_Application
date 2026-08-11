/// Compact customer activity statistics for the Customer Profile screen.
/// Computed directly from the real `getMyBookings()` response — no
/// mock data involved.
class CustomerProfileStats {
  const CustomerProfileStats({
    required this.totalBookings,
    required this.currentlyRented,
    required this.completedTrips,
  });

  final int totalBookings;
  final int currentlyRented;
  final int completedTrips;

  static const empty = CustomerProfileStats(
    totalBookings: 0,
    currentlyRented: 0,
    completedTrips: 0,
  );

  factory CustomerProfileStats.fromBookings(List<Map<String, dynamic>> bookings) {
    var currentlyRented = 0;
    var completed = 0;

    for (final b in bookings) {
      final status = b['status']?.toString().toLowerCase() ?? '';
      if (status == 'active' || status == 'confirmed') currentlyRented++;
      if (status == 'completed') completed++;
    }

    return CustomerProfileStats(
      totalBookings: bookings.length,
      currentlyRented: currentlyRented,
      completedTrips: completed,
    );
  }
}
