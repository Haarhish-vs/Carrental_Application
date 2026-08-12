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
  final String ownerId;
  final String? carType;
  final double? distanceKm;
  final String? pickupLocation;
  final double? depositAmount;
  final int? minimumRentalDays;
  final int? reviewsCount;
  final String? ownerName;
  final String? ownerImageUrl;

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
    required this.ownerId,
    this.carType,
    this.distanceKm,
    this.pickupLocation,
    this.depositAmount,
    this.minimumRentalDays,
    this.reviewsCount,
    this.ownerName,
    this.ownerImageUrl,
  });

  CarModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<String>? images,
    String? transmission,
    String? fuelType,
    int? seats,
    double? rating,
    double? pricePerDay,
    String? city,
    String? status,
    bool? isAvailable,
    String? ownerId,
    String? carType,
    double? distanceKm,
    String? pickupLocation,
    double? depositAmount,
    int? minimumRentalDays,
    int? reviewsCount,
    String? ownerName,
    String? ownerImageUrl,
  }) {
    return CarModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      seats: seats ?? this.seats,
      rating: rating ?? this.rating,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      city: city ?? this.city,
      status: status ?? this.status,
      isAvailable: isAvailable ?? this.isAvailable,
      ownerId: ownerId ?? this.ownerId,
      carType: carType ?? this.carType,
      distanceKm: distanceKm ?? this.distanceKm,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      depositAmount: depositAmount ?? this.depositAmount,
      minimumRentalDays: minimumRentalDays ?? this.minimumRentalDays,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      ownerName: ownerName ?? this.ownerName,
      ownerImageUrl: ownerImageUrl ?? this.ownerImageUrl,
    );
  }

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
        double.tryParse(json['rating']?.toString() ?? '') ?? 0.0;
    final String city = json['city']?.toString() ?? 'Unknown City';
    final String status = json['status']?.toString() ?? 'unknown';
    final bool isAvailable =
        (json['is_available'] != false && json['isAvailable'] != false) &&
        json['status']?.toString().toLowerCase() == 'active';
    final String ownerId = json['owner_id']?.toString() ?? json['ownerId']?.toString() ?? '';

    final String? carType = json['car_type']?.toString() ?? json['carType']?.toString();
    final double? distanceKm = json['distanceKm'] != null
        ? double.tryParse(json['distanceKm'].toString())
        : (json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null);
    final String? pickupLocation = json['pickup_location']?.toString() ?? json['pickupLocation']?.toString();
    final double? depositAmount = double.tryParse(json['deposit_amount']?.toString() ?? json['depositAmount']?.toString() ?? '');
    final int? minimumRentalDays = int.tryParse(json['minimum_rental_days']?.toString() ?? json['minimumRentalDays']?.toString() ?? '');
    final int? reviewsCount = int.tryParse(json['reviews_count']?.toString() ?? json['reviewsCount']?.toString() ?? '');

    String? ownerName;
    String? ownerImageUrl;
    if (json['owner'] is Map) {
      final ownerMap = json['owner'] as Map;
      ownerName = ownerMap['full_name']?.toString() ?? ownerMap['fullName']?.toString();
      ownerImageUrl = ownerMap['profile_image_url']?.toString() ?? ownerMap['profileImageUrl']?.toString() ?? ownerMap['avatar_url']?.toString();
    } else {
      ownerName = json['owner_name']?.toString() ?? json['ownerName']?.toString();
      ownerImageUrl = json['owner_image_url']?.toString() ?? json['ownerImageUrl']?.toString();
    }

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
      ownerId: ownerId,
      carType: carType,
      distanceKm: distanceKm,
      pickupLocation: pickupLocation,
      depositAmount: depositAmount,
      minimumRentalDays: minimumRentalDays,
      reviewsCount: reviewsCount,
      ownerName: ownerName,
      ownerImageUrl: ownerImageUrl,
    );
  }
}
