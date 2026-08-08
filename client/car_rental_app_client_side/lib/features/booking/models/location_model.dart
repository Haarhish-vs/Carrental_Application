import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const LocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  List<Object?> get props => [id, name, address, latitude, longitude];

  // Recommended static mock list of hubs
  static const List<LocationModel> mockLocations = [
    LocationModel(
      id: "coimbatore_gandhipuram",
      name: "Gandhipuram Hub",
      address: "Gandhipuram, Coimbatore",
      latitude: 11.0168,
      longitude: 76.9558,
    ),
    LocationModel(
      id: "coimbatore_rspuram",
      name: "RS Puram Hub",
      address: "RS Puram, Coimbatore",
      latitude: 11.0115,
      longitude: 76.9443,
    ),
    LocationModel(
      id: "coimbatore_airport",
      name: "Coimbatore Airport Hub",
      address: "Peelamedu, Coimbatore",
      latitude: 11.0298,
      longitude: 77.0434,
    ),
  ];
}
