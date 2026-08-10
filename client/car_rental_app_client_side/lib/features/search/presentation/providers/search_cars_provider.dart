import 'package:flutter/foundation.dart';
import 'package:car_rental_app_client_side/features/location/data/models/location_model.dart';
import 'package:car_rental_app_client_side/features/home/models/car_model.dart';
import 'package:car_rental_app_client_side/features/search/data/models/filter_options_model.dart';
import 'package:car_rental_app_client_side/features/search/data/models/search_parameters.dart';
import 'package:car_rental_app_client_side/features/search/data/services/search_api_service.dart';

enum SearchCarsStatus { initial, loading, success, empty, error }

class SearchCarsProvider extends ChangeNotifier {
  final SearchApiService _apiService;

  SearchCarsProvider({SearchApiService? apiService})
      : _apiService = apiService ?? SearchApiService();

  SearchParameters? _params;
  SearchParameters? get params => _params;

  FilterOptionsModel _filterOptions = const FilterOptionsModel();
  FilterOptionsModel get filterOptions => _filterOptions;

  SearchFilterState _appliedFilters = const SearchFilterState();
  SearchFilterState get appliedFilters => _appliedFilters;

  SearchFilterState _tempFilters = const SearchFilterState();
  SearchFilterState get tempFilters => _tempFilters;

  List<CarModel> _cars = [];
  List<CarModel> get cars => _cars;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  bool get hasMore => _currentPage < _totalPages;

  SearchCarsStatus _status = SearchCarsStatus.initial;
  SearchCarsStatus get status => _status;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Initializes the search flow with parameters from Home Screen
  Future<void> init(SearchParameters initialParams) async {
    _params = initialParams;
    _status = SearchCarsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // 1. Fetch dynamic filter options from backend
    _filterOptions = await _apiService.getFilterOptions();

    // 2. Initialize default filter state with backend price bounds
    _appliedFilters = SearchFilterState(
      minPrice: _filterOptions.minPrice,
      maxPrice: _filterOptions.maxPrice,
      sort: 'recommended',
    );
    _tempFilters = _appliedFilters;

    // 3. Execute initial search
    await search();
  }

  /// Updates location and re-runs search with existing dates, times, filters & sort
  Future<void> updateLocation(LocationModel newLocation) async {
    if (_params == null) return;
    _params = _params!.copyWith(location: newLocation);
    await search();
  }

  /// Performs or refreshes the search using current params, filters, and sort
  Future<void> search({bool isRefresh = false}) async {
    if (_params == null) return;

    if (!isRefresh) {
      _status = SearchCarsStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _currentPage = 1;
      final response = await _apiService.searchCars(
        params: _params!,
        filters: _appliedFilters,
        page: 1,
      );

      _cars = response.cars;
      _totalCount = response.total;
      _currentPage = response.page;
      _totalPages = response.totalPages;

      if (_cars.isEmpty) {
        _status = SearchCarsStatus.empty;
      } else {
        _status = SearchCarsStatus.success;
      }
      _errorMessage = null;
    } catch (e) {
      debugPrint('❌ [SearchCarsProvider] Search error: $e');
      _status = SearchCarsStatus.error;
      _errorMessage = 'Something went wrong while searching for available cars.';
    } finally {
      notifyListeners();
    }
  }

  /// Infinite scroll / pagination: loads next page of cars
  Future<void> loadMore() async {
    if (_params == null || _isLoadingMore || !hasMore || _status == SearchCarsStatus.loading) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _apiService.searchCars(
        params: _params!,
        filters: _appliedFilters,
        page: nextPage,
      );

      _cars.addAll(response.cars);
      _currentPage = response.page;
      _totalPages = response.totalPages;
      _totalCount = response.total;
    } catch (e) {
      debugPrint('⚠️ [SearchCarsProvider] Pagination error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // FILTER MODAL STATE MANAGEMENT (Temporary vs Applied)
  // ---------------------------------------------------------------------------

  /// Prepares temporary filter state before displaying Filter Bottom Sheet
  void openFilterSheet() {
    _tempFilters = _appliedFilters.copyWith();
    notifyListeners();
  }

  void setTempCarType(String? type) {
    if (type == null || type.toLowerCase() == 'all') {
      _tempFilters = _tempFilters.copyWith(clearCarType: true);
    } else {
      _tempFilters = _tempFilters.copyWith(carType: type);
    }
    notifyListeners();
  }

  void setTempTransmission(String? transmission) {
    if (transmission == null || transmission.toLowerCase() == 'all') {
      _tempFilters = _tempFilters.copyWith(clearTransmission: true);
    } else {
      _tempFilters = _tempFilters.copyWith(transmission: transmission);
    }
    notifyListeners();
  }

  void setTempFuelType(String? fuelType) {
    if (fuelType == null || fuelType.toLowerCase() == 'all') {
      _tempFilters = _tempFilters.copyWith(clearFuelType: true);
    } else {
      _tempFilters = _tempFilters.copyWith(fuelType: fuelType);
    }
    notifyListeners();
  }

  void setTempSeats(int? seats) {
    if (seats == null || seats == 0) {
      _tempFilters = _tempFilters.copyWith(clearSeats: true);
    } else {
      _tempFilters = _tempFilters.copyWith(seats: seats);
    }
    notifyListeners();
  }

  void setTempPriceRange(double min, double max) {
    _tempFilters = _tempFilters.copyWith(minPrice: min, maxPrice: max);
    notifyListeners();
  }

  void setTempSort(String sort) {
    _tempFilters = _tempFilters.copyWith(sort: sort);
    notifyListeners();
  }

  /// Resets temporary filters to database defaults (All, full price range, Recommended)
  void clearTempFilters() {
    _tempFilters = SearchFilterState(
      minPrice: _filterOptions.minPrice,
      maxPrice: _filterOptions.maxPrice,
      sort: 'recommended',
    );
    notifyListeners();
  }

  /// Applies temporary filters and triggers a new search
  Future<void> applyFilters() async {
    _appliedFilters = _tempFilters.copyWith();
    await search();
  }

  /// Changes sort directly and triggers a new search
  Future<void> setSortAndApply(String sort) async {
    _appliedFilters = _appliedFilters.copyWith(sort: sort);
    _tempFilters = _tempFilters.copyWith(sort: sort);
    await search();
  }
}
