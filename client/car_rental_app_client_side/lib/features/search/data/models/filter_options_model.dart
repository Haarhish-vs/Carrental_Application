/// Database-driven dynamic filter options returned by GET /api/cars/filter-options
class FilterOptionsModel {
  final List<String> carTypes;
  final List<String> transmissions;
  final List<String> fuelTypes;
  final List<int> seatOptions;
  final double minPrice;
  final double maxPrice;

  const FilterOptionsModel({
    this.carTypes = const [],
    this.transmissions = const [],
    this.fuelTypes = const [],
    this.seatOptions = const [],
    this.minPrice = 0.0,
    this.maxPrice = 10000.0,
  });

  factory FilterOptionsModel.fromJson(Map<String, dynamic> json) {
    final filters = json['filters'] as Map<String, dynamic>? ?? json;

    final List<String> carTypesList = [];
    if (filters['carTypes'] is List) {
      for (final item in filters['carTypes']) {
        if (item != null && item.toString().trim().isNotEmpty) {
          carTypesList.add(item.toString().trim());
        }
      }
    }

    final List<String> transList = [];
    if (filters['transmissions'] is List) {
      for (final item in filters['transmissions']) {
        if (item != null && item.toString().trim().isNotEmpty) {
          transList.add(item.toString().trim());
        }
      }
    }

    final List<String> fuelList = [];
    if (filters['fuelTypes'] is List) {
      for (final item in filters['fuelTypes']) {
        if (item != null && item.toString().trim().isNotEmpty) {
          fuelList.add(item.toString().trim());
        }
      }
    }

    final List<int> seatList = [];
    if (filters['seatOptions'] is List) {
      for (final item in filters['seatOptions']) {
        final val = int.tryParse(item.toString());
        if (val != null && val > 0) {
          seatList.add(val);
        }
      }
    }
    seatList.sort();

    double minP = 0.0;
    double maxP = 10000.0;
    final priceRange = filters['priceRange'];
    if (priceRange is Map) {
      minP = double.tryParse(priceRange['min']?.toString() ?? '') ?? 0.0;
      maxP = double.tryParse(priceRange['max']?.toString() ?? '') ?? 10000.0;
    }

    if (maxP <= minP) {
      maxP = minP + 1000.0;
    }

    return FilterOptionsModel(
      carTypes: carTypesList,
      transmissions: transList,
      fuelTypes: fuelList,
      seatOptions: seatList,
      minPrice: minP,
      maxPrice: maxP,
    );
  }
}

/// Filter state holding selected filters for search query
class SearchFilterState {
  final String? carType;
  final String? transmission;
  final String? fuelType;
  final int? seats;
  final double? minPrice;
  final double? maxPrice;
  final String sort;

  const SearchFilterState({
    this.carType,
    this.transmission,
    this.fuelType,
    this.seats,
    this.minPrice,
    this.maxPrice,
    this.sort = 'recommended',
  });

  bool get hasActiveFilters =>
      (carType != null && carType!.isNotEmpty) ||
      (transmission != null && transmission!.isNotEmpty) ||
      (fuelType != null && fuelType!.isNotEmpty) ||
      seats != null ||
      minPrice != null ||
      maxPrice != null;

  SearchFilterState copyWith({
    String? carType,
    bool clearCarType = false,
    String? transmission,
    bool clearTransmission = false,
    String? fuelType,
    bool clearFuelType = false,
    int? seats,
    bool clearSeats = false,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    String? sort,
  }) {
    return SearchFilterState(
      carType: clearCarType ? null : (carType ?? this.carType),
      transmission: clearTransmission ? null : (transmission ?? this.transmission),
      fuelType: clearFuelType ? null : (fuelType ?? this.fuelType),
      seats: clearSeats ? null : (seats ?? this.seats),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
    );
  }

  Map<String, dynamic> toApiFilters() {
    final map = <String, dynamic>{};
    if (carType != null && carType!.isNotEmpty && carType!.toLowerCase() != 'all') {
      map['carType'] = carType;
    }
    if (transmission != null && transmission!.isNotEmpty && transmission!.toLowerCase() != 'all') {
      map['transmission'] = transmission;
    }
    if (fuelType != null && fuelType!.isNotEmpty && fuelType!.toLowerCase() != 'all') {
      map['fuelType'] = fuelType;
    }
    if (seats != null && seats! > 0) {
      map['seats'] = seats;
    }
    if (minPrice != null) {
      map['minPrice'] = minPrice;
    }
    if (maxPrice != null) {
      map['maxPrice'] = maxPrice;
    }
    return map;
  }
}
