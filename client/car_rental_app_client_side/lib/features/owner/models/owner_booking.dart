class OwnerBooking {
  const OwnerBooking({
    required this.id,
    required this.guestName,
    required this.vehicleName,
    required this.startDate,
    required this.endDate,
    required this.total,
  });

  final String id;
  final String guestName;
  final String vehicleName;
  final DateTime startDate;
  final DateTime endDate;
  final double total;
}
