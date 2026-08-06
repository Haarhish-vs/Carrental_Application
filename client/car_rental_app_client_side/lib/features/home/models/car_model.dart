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

  factory CarModel.fromJson(Map<String, dynamic> json) {
    final String id = json['id']?.toString() ?? '';
    final String brand = json['brand']?.toString() ?? '';
    final String model = json['model']?.toString() ?? '';
    final String name = [brand, model].where((part) => part.isNotEmpty).join(' ').trim();

    String imageUrl = '';
    final images = json['images'];
    if (images is List && images.isNotEmpty) {
      final firstImage = images.first;
      if (firstImage is String) {
        imageUrl = firstImage;
      } else if (firstImage is Map<String, dynamic>) {
        imageUrl = firstImage['url']?.toString() ?? firstImage['secure_url']?.toString() ?? '';
      }
    }
    if (imageUrl.isEmpty) {
      imageUrl = json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '';
    }

    final String transmission = json['transmission']?.toString() ?? 'Automatic';
    final String fuelType = json['fuel_type']?.toString() ?? json['fuelType']?.toString() ?? 'Petrol';
    final int seats = int.tryParse(json['seats']?.toString() ?? json['seatingCapacity']?.toString() ?? '') ?? 4;
    final double pricePerDay = double.tryParse(json['price_per_day']?.toString() ?? json['dailyPrice']?.toString() ?? '') ?? 0.0;
    final double rating = double.tryParse(json['rating']?.toString() ?? '') ?? 4.5;

    return CarModel(
      id: id,
      name: name.isNotEmpty ? name : 'Car',
      imageUrl: imageUrl,
      transmission: transmission,
      fuelType: fuelType,
      seats: seats,
      rating: rating,
      pricePerDay: pricePerDay,
    );
  }
}
