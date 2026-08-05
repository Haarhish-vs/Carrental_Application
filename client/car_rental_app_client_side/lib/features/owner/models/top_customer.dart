/// Dummy model for the Customer Analytics section (a renter as seen
/// by the owner).
class TopCustomer {
  const TopCustomer({
    required this.name,
    required this.totalBookings,
    required this.isRepeat,
    required this.totalSpent,
  });

  final String name;
  final int totalBookings;
  final bool isRepeat;
  final double totalSpent;
}
