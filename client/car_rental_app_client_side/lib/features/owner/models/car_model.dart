enum CarStatus { available, rented, maintenance, inactive }

/// Dummy fleet model for the Car Analytics section. Sits alongside
/// the existing `OwnerBooking` model in this same folder.
class CarModel {
  const CarModel({
    required this.name,
    required this.plateNumber,
    required this.status,
    required this.totalRentals,
    required this.utilization,
    required this.rating,
    required this.kilometersDriven,
  });

  final String name;
  final String plateNumber;
  final CarStatus status;
  final int totalRentals;
  final double utilization; // 0..1
  final double rating;
  final int kilometersDriven;
}
