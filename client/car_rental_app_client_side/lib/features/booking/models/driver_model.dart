import 'package:equatable/equatable.dart';

class Driver extends Equatable {
  final String id;
  final String name;
  final double rating;
  final int experienceYears;
  final List<String> languages;
  final bool isVerified;
  final double pricePerDay;
  final String imageUrl;

  // New fields for availability & location-based matching
  final List<String> serviceLocations;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final int tripsCompleted;

  const Driver({
    required this.id,
    required this.name,
    required this.rating,
    required this.experienceYears,
    required this.languages,
    required this.isVerified,
    required this.pricePerDay,
    required this.imageUrl,
    this.serviceLocations = const [],
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.isAvailable = true,
    this.availableFrom,
    this.availableUntil,
    this.tripsCompleted = 100,
  });

  Driver copyWith({
    String? id,
    String? name,
    double? rating,
    int? experienceYears,
    List<String>? languages,
    bool? isVerified,
    double? pricePerDay,
    String? imageUrl,
    List<String>? serviceLocations,
    double? latitude,
    double? longitude,
    bool? isAvailable,
    DateTime? Function()? availableFrom,
    DateTime? Function()? availableUntil,
    int? tripsCompleted,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      experienceYears: experienceYears ?? this.experienceYears,
      languages: languages ?? this.languages,
      isVerified: isVerified ?? this.isVerified,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      imageUrl: imageUrl ?? this.imageUrl,
      serviceLocations: serviceLocations ?? this.serviceLocations,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailable: isAvailable ?? this.isAvailable,
      availableFrom: availableFrom != null
          ? availableFrom()
          : this.availableFrom,
      availableUntil: availableUntil != null
          ? availableUntil()
          : this.availableUntil,
      tripsCompleted: tripsCompleted ?? this.tripsCompleted,
    );
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      name: json['name'] as String,
      rating: (json['rating'] as num).toDouble(),
      experienceYears: json['experienceYears'] as int,
      languages: List<String>.from(json['languages'] as List),
      isVerified: json['isVerified'] as bool,
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      serviceLocations: json['serviceLocations'] != null
          ? List<String>.from(json['serviceLocations'] as List)
          : const [],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : 0.0,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : 0.0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      availableFrom: json['availableFrom'] != null
          ? DateTime.parse(json['availableFrom'] as String)
          : null,
      availableUntil: json['availableUntil'] != null
          ? DateTime.parse(json['availableUntil'] as String)
          : null,
      tripsCompleted: json['tripsCompleted'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'experienceYears': experienceYears,
      'languages': languages,
      'isVerified': isVerified,
      'pricePerDay': pricePerDay,
      'imageUrl': imageUrl,
      'serviceLocations': serviceLocations,
      'latitude': latitude,
      'longitude': longitude,
      'isAvailable': isAvailable,
      'availableFrom': availableFrom?.toIso8601String(),
      'availableUntil': availableUntil?.toIso8601String(),
      'tripsCompleted': tripsCompleted,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    rating,
    experienceYears,
    languages,
    isVerified,
    pricePerDay,
    imageUrl,
    serviceLocations,
    latitude,
    longitude,
    isAvailable,
    availableFrom,
    availableUntil,
    tripsCompleted,
  ];
}
