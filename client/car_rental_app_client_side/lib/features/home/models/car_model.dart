class CarModel {
  final String id;
  final String name;
  final String imageUrl;
  final String transmission;
  final String fuelType;
  final int seats;
  final double rating;
  final double pricePerDay;

  const CarModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.transmission,
    required this.fuelType,
    required this.seats,
    required this.rating,
    required this.pricePerDay,
  });
}