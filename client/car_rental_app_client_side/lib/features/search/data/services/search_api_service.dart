import 'package:flutter/foundation.dart';
import 'package:car_rental_app_client_side/features/owner/data/services/car_api_service.dart';
import 'package:car_rental_app_client_side/features/search/data/models/filter_options_model.dart';
import 'package:car_rental_app_client_side/features/search/data/models/search_parameters.dart';

class SearchApiService {
  final CarApiService _apiService;

  SearchApiService({CarApiService? apiService})
      : _apiService = apiService ?? CarApiService();

  /// Retrieve dynamic filter options from the database
  Future<FilterOptionsModel> getFilterOptions() async {
    try {
      final data = await _apiService.getFilterOptions();
      return FilterOptionsModel.fromJson(data);
    } catch (e) {
      debugPrint('⚠️ [SearchApiService] Failed to load filter options: $e');
      // Return default fallback model on network issue so UI doesn't crash
      return const FilterOptionsModel();
    }
  }

  /// Search available vehicles matching the criteria
  Future<SearchCarsResponse> searchCars({
    required SearchParameters params,
    SearchFilterState? filters,
    int page = 1,
    int limit = 10,
  }) async {
    final payload = params.toApiJson(
      filters: filters,
      page: page,
      limit: limit,
    );

    debugPrint('🚗 [SearchApiService] Searching cars with payload: $payload');
    final data = await _apiService.searchCars(payload);
    return SearchCarsResponse.fromJson(data);
  }
}
