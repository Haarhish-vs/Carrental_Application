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

  const Driver({
    required this.id,
    required this.name,
    required this.rating,
    required this.experienceYears,
    required this.languages,
    required this.isVerified,
    required this.pricePerDay,
    required this.imageUrl,
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
    };
  }

  @override
  List<Object?> get props => [id, name, rating, experienceYears, languages, isVerified, pricePerDay, imageUrl];
}
