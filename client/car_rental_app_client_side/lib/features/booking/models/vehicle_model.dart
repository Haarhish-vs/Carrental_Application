import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final double pricePerDay;
  final List<String> specifications;
  final double rating;

  const Vehicle({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.pricePerDay,
    required this.specifications,
    required this.rating,
  });

  Vehicle copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? pricePerDay,
    List<String>? specifications,
    double? rating,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      specifications: specifications ?? this.specifications,
      rating: rating ?? this.rating,
    );
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
      specifications: List<String>.from(json['specifications'] as List),
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'pricePerDay': pricePerDay,
      'specifications': specifications,
      'rating': rating,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    imageUrl,
    pricePerDay,
    specifications,
    rating,
  ];
}
