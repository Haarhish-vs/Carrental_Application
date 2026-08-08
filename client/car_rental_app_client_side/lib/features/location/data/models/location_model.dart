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

  factory LocationModel.fromJson(Map<String, dynamic> json, {double? defaultLat, double? defaultLng}) {
    return LocationModel(
      id: json['id'] as String?,
      placeId: (json['placeId'] ?? json['place_id'] ?? '') as String,
      name: (json['name'] ?? json['formattedAddress']?.toString().split(',').first ?? json['address'] ?? json['city'] ?? 'Selected Location') as String,
      address: (json['address'] ?? json['formattedAddress'] ?? '') as String,
      latitude: (json['latitude'] ?? json['lat'] ?? defaultLat ?? 0.0 as num).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? defaultLng ?? 0.0 as num).toDouble(),
      city: (json['city'] ?? '') as String,
      state: (json['state'] ?? '') as String,
      country: (json['country'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    final effectivePlaceId = placeId.isNotEmpty ? placeId : 'pin_${latitude}_$longitude';
    final effectiveName = name.isNotEmpty ? name : (address.isNotEmpty ? address : 'Selected Location');
    final effectiveAddress = address.isNotEmpty ? address : effectiveName;
    return {
      if (id != null) 'id': id,
      'placeId': effectivePlaceId,
      'name': effectiveName,
      'address': effectiveAddress,
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