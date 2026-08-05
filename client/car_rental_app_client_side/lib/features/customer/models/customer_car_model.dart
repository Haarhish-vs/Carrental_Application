import 'package:flutter/foundation.dart';

@immutable
class CustomerCarModel {
  const CustomerCarModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.imageUrl,
    required this.pricePerDay,
    required this.rating,
    required this.reviewCount,
    required this.transmission,
    required this.fuelType,
    required this.seats,
    required this.location,
    this.isFeatured = false,
    this.isPopular = false,
    this.isLuxury = false,
    this.isElectric = false,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final double pricePerDay;
  final double rating;
  final int reviewCount;
  final String transmission;
  final String fuelType;
  final int seats;
  final String location;
  final bool isFeatured;
  final bool isPopular;
  final bool isLuxury;
  final bool isElectric;
  final bool isAvailable;
}
