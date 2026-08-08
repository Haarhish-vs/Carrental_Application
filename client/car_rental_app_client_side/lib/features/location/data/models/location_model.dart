/// Matches the backend's location response exactly.
/// No frontend-only fields are mixed in here — anything UI-specific
/// (e.g. which list a location came from) is handled outside this model.
class LocationModel {
  final String? id;
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String country;

  const LocationModel({
    this.id,
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.country,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String?,
      placeId: json['placeId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'placeId': placeId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
    };
  }

  LocationModel copyWith({
    String? id,
    String? placeId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? city,
    String? state,
    String? country,
  }) {
    return LocationModel(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationModel && other.placeId == placeId && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(placeId, latitude, longitude);
}