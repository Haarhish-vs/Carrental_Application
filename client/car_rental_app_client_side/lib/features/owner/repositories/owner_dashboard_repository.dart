import '../models/owner_booking.dart';

abstract interface class OwnerDashboardRepository {
  Future<List<OwnerBooking>> getRecentBookings();
}
