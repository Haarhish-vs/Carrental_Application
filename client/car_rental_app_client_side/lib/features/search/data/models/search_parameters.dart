import 'package:car_rental_app_client_side/features/location/data/models/location_model.dart';
import 'package:car_rental_app_client_side/features/home/models/car_model.dart';
import 'package:car_rental_app_client_side/features/search/data/models/filter_options_model.dart';

/// Holds the active search parameters received from Home or updated in Search screen
class SearchParameters {
  final LocationModel location;
  final String pickupDate;
  final String pickupTime;
  final String returnDate;
  final String returnTime;

  const SearchParameters({
    required this.location,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
  });

  SearchParameters copyWith({
    LocationModel? location,
    String? pickupDate,
    String? pickupTime,
    String? returnDate,
    String? returnTime,
  }) {
    return SearchParameters(
      location: location ?? this.location,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTime: pickupTime ?? this.pickupTime,
      returnDate: returnDate ?? this.returnDate,
      returnTime: returnTime ?? this.returnTime,
    );
  }

  /// Normalizes DD/MM/YYYY to YYYY-MM-DD if needed
  static String normalizeDate(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('/')) {
      final parts = trimmed.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    }
    return trimmed;
  }

  /// Normalizes "10:00 AM" / "02:30 PM" to "HH:mm" 24h format if needed
  static String normalizeTime(String input) {
    final trimmed = input.trim();
    final upper = trimmed.toUpperCase();
    if (upper.contains('AM') || upper.contains('PM')) {
      final isPm = upper.contains('PM');
      final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = clean.split(':');
      if (parts.isNotEmpty) {
        int hour = int.tryParse(parts[0].trim()) ?? 0;
        final minute = parts.length > 1 ? parts[1].trim() : '00';
        if (isPm && hour < 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        return '${hour.toString().padLeft(2, '0')}:$minute';
      }
    }
    return trimmed;
  }

  Map<String, dynamic> toApiJson({
    SearchFilterState? filters,
    int page = 1,
    int limit = 10,
  }) {
    return {
      'location': {
        'name': location.name,
        'city': location.city.isNotEmpty ? location.city : location.name,
        'address': location.address,
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'pickupDate': normalizeDate(pickupDate),
      'pickupTime': normalizeTime(pickupTime),
      'returnDate': normalizeDate(returnDate),
      'returnTime': normalizeTime(returnTime),
      if (filters != null) 'filters': filters.toApiFilters(),
      if (filters != null) 'sort': filters.sort,
      'page': page,
      'limit': limit,
    };
  }
}

/// Response returned from the Search Cars API
class SearchCarsResponse {
  final bool success;
  final int count;
  final List<CarModel> cars;
  final String? message;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const SearchCarsResponse({
    required this.success,
    required this.count,
    required this.cars,
    this.message,
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.totalPages = 1,
  });

  factory SearchCarsResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? true;
    final count = int.tryParse(json['count']?.toString() ?? '') ?? 0;
    final message = json['message']?.toString();

    final List<CarModel> carsList = [];
    final rawCars = json['cars'] ?? json['data'];
    if (rawCars is List) {
      for (final item in rawCars) {
        if (item is Map<String, dynamic>) {
          carsList.add(CarModel.fromJson(item));
        } else if (item is Map) {
          carsList.add(CarModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    int page = 1;
    int limit = 10;
    int total = carsList.length;
    int totalPages = 1;

    final pagination = json['pagination'];
    if (pagination is Map) {
      page = int.tryParse(pagination['page']?.toString() ?? '') ?? 1;
      limit = int.tryParse(pagination['limit']?.toString() ?? '') ?? 10;
      total = int.tryParse(pagination['total']?.toString() ?? '') ?? count;
      totalPages = int.tryParse(pagination['totalPages']?.toString() ?? '') ?? 1;
    } else {
      total = count > 0 ? count : carsList.length;
    }

    return SearchCarsResponse(
      success: success,
      count: count,
      cars: carsList,
      message: message,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }
}
