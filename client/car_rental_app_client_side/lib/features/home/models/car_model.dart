class CarModel {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> images;
  final String transmission;
  final String fuelType;
  final int seats;
  final double rating;
  final double pricePerDay;
  final String city;
  final String status;
  final bool isAvailable;

  const CarModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.images,
    required this.transmission,
    required this.fuelType,
    required this.seats,
    required this.rating,
    required this.pricePerDay,
    required this.city,
    required this.status,
    this.isAvailable = true,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    final String id = json['id']?.toString() ?? '';
    final String brand = json['brand']?.toString() ?? '';
    final String model = json['model']?.toString() ?? '';
    final String name = [
      brand,
      model,
    ].where((part) => part.isNotEmpty).join(' ').trim();

    String imageUrl = '';
    final List<String> imagesList = [];
    final imagesJson = json['images'];
    if (imagesJson is List) {
      for (final item in imagesJson) {
        if (item is String) {
          imagesList.add(item);
        } else if (item is Map<String, dynamic>) {
          final url =
              item['url']?.toString() ?? item['secure_url']?.toString() ?? '';
          if (url.isNotEmpty) {
            imagesList.add(url);
          }
        }
      }
    }
    if (imagesList.isNotEmpty) {
      imageUrl = imagesList.first;
    } else {
      final fallbackUrl =
          json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '';
      if (fallbackUrl.isNotEmpty) {
        imageUrl = fallbackUrl;
        imagesList.add(fallbackUrl);
      }
    }

    final String transmission = json['transmission']?.toString() ?? 'Automatic';
    final String fuelType =
        json['fuel_type']?.toString() ??
        json['fuelType']?.toString() ??
        'Petrol';
    final int seats =
        int.tryParse(
          json['seats']?.toString() ??
              json['seatingCapacity']?.toString() ??
              '',
        ) ??
        4;
    final double pricePerDay =
        double.tryParse(
          json['price_per_day']?.toString() ??
              json['dailyPrice']?.toString() ??
              '',
        ) ??
        0.0;
    final double rating =
        double.tryParse(json['rating']?.toString() ?? '') ?? 4.5;
    final String city = json['city']?.toString() ?? 'Unknown City';
    final String status = json['status']?.toString() ?? 'unknown';
    final bool isAvailable =
        (json['is_available'] != false && json['isAvailable'] != false) &&
        json['status']?.toString().toLowerCase() == 'active';

    return CarModel(
      id: id,
      name: name.isNotEmpty ? name : 'Car',
      imageUrl: imageUrl,
      images: imagesList,
      transmission: transmission,
      fuelType: fuelType,
      seats: seats,
      rating: rating,
      pricePerDay: pricePerDay,
      city: city,
      status: status,
      isAvailable: isAvailable,
    );
  }
}
