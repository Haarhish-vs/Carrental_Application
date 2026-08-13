import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/car_model.dart';
import '../widgets/car_card.dart';
import 'car_detail_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../owner/data/services/car_api_service.dart';

class AllRecommendedCarsScreen extends StatefulWidget {
  final DateTime? initialPickupDate;
  final DateTime? initialReturnDate;

  const AllRecommendedCarsScreen({
    super.key,
    this.initialPickupDate,
    this.initialReturnDate,
  });

  @override
  State<AllRecommendedCarsScreen> createState() => _AllRecommendedCarsScreenState();
}

class _AllRecommendedCarsScreenState extends State<AllRecommendedCarsScreen> {
  final CarApiService _carApiService = CarApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<CarModel> _cars = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _limit = 6;
  bool _hasMore = true;

  // Filters state
  String _searchLocation = '';
  String? _selectedFuelType;
  String? _selectedTransmission;
  int? _selectedSeats;
  double? _minPrice;
  double? _maxPrice;

  // Available filter options from backend
  Map<String, dynamic> _filterOptions = {};
  bool _isLoadingFilters = true;

  @override
  void initState() {
    super.initState();
    _fetchFilterOptions();
    _fetchCars(refresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchFilterOptions() async {
    final options = await _carApiService.getFilterOptions();
    if (mounted) {
      setState(() {
        _filterOptions = options;
        _isLoadingFilters = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchLocation = query;
        });
        _fetchCars(refresh: true);
      }
    });
  }

  Future<void> _fetchCars({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _cars = [];
        _isLoading = true;
        _hasMore = true;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final offset = (_currentPage - 1) * _limit;
      final response = await _carApiService.getVehicles(
        limit: _limit,
        offset: offset,
        city: _searchLocation, // Using city for location search based on DB
        fuelType: _selectedFuelType,
        transmission: _selectedTransmission,
        seats: _selectedSeats,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );

      final newCars = response
          .map<CarModel>((data) => CarModel.fromJson(data))
          .where((car) => car.isAvailable)
          .toList();

      // Ensure consistent local sort visually
      newCars.sort((a, b) => b.rating.compareTo(a.rating));

      if (mounted) {
        setState(() {
          if (refresh) {
            _cars = newCars;
          } else {
            _cars.addAll(newCars);
          }
          _hasMore = response.length == _limit;
          if (refresh) _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching cars: $e');
      if (mounted) {
        setState(() {
          if (refresh) _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _loadMore() {
    if (!_isLoadingMore && _hasMore) {
      setState(() {
        _currentPage++;
      });
      _fetchCars();
    }
  }

  void _openCarDetail(BuildContext context, CarModel car) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CarDetailScreen(
          car: car,
          initialPickupDate: widget.initialPickupDate,
          initialReturnDate: widget.initialReturnDate,
        ),
      ),
    );
  }

  void _handleBookNow(BuildContext context, CarModel car) {
    if (AuthService.isAuthenticated &&
        AuthService.currentUser != null &&
        AuthService.currentUser!['id'] == car.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot book your own vehicle'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    _openCarDetail(context, car);
  }

  void _showFilterModal() {
    if (_isLoadingFilters) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading filters... please wait.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        options: _filterOptions,
        initialFuel: _selectedFuelType,
        initialTransmission: _selectedTransmission,
        initialSeats: _selectedSeats,
        onApply: (fuel, transmission, seats) {
          setState(() {
            _selectedFuelType = fuel;
            _selectedTransmission = transmission;
            _selectedSeats = seats;
          });
          _fetchCars(refresh: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.sizeOf(context);
    final double screenWidth = mediaQuery.width;

    final double scale = (screenWidth / 375.0).clamp(0.8, 1.25);
    final double gridPadding = (16.0 * scale).clamp(12.0, 24.0);
    final double spacing = (12.0 * scale).clamp(8.0, 16.0);

    final int crossAxisCount = screenWidth >= 900
        ? 4
        : (screenWidth >= 600 ? 3 : 2);

    final double totalHorizontalSpacing =
        (gridPadding * 2) + (spacing * (crossAxisCount - 1));
    final double cardWidth = (screenWidth - totalHorizontalSpacing) / crossAxisCount;
    final double imageHeight = (screenWidth * 0.32).clamp(100.0, 140.0);
    final double cardContentHeight = 105.0 * scale;
    final double estimatedCardHeight = imageHeight + cardContentHeight;
    final double dynamicAspectRatio = (cardWidth / estimatedCardHeight).clamp(0.46, 0.72);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Top Rated Cars',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18 * scale,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // Search Box with Filter Icon
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(gridPadding, 8, gridPadding, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by Location...',
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14 * scale),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, color: AppColors.primary),
                  onPressed: _showFilterModal,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cars.isEmpty
                    ? Center(
                        child: Text(
                          'No matching cars found.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14 * scale,
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          GridView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(gridPadding),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: spacing,
                              crossAxisSpacing: spacing,
                              childAspectRatio: dynamicAspectRatio,
                            ),
                            itemCount: _cars.length,
                            itemBuilder: (context, index) {
                              final car = _cars[index];
                              return CarCard(
                                car: car,
                                width: double.infinity,
                                onCarTap: () => _openCarDetail(context, car),
                                onBookNow: () => _handleBookNow(context, car),
                              );
                            },
                          ),
                          if (_isLoadingMore)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black12, blurRadius: 4)
                                    ],
                                  ),
                                  child: const CircularProgressIndicator(),
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> options;
  final String? initialFuel;
  final String? initialTransmission;
  final int? initialSeats;
  final void Function(String?, String?, int?) onApply;

  const _FilterBottomSheet({
    required this.options,
    this.initialFuel,
    this.initialTransmission,
    this.initialSeats,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _fuel;
  String? _transmission;
  int? _seats;

  @override
  void initState() {
    super.initState();
    _fuel = widget.initialFuel;
    _transmission = widget.initialTransmission;
    _seats = widget.initialSeats;
  }

  @override
  Widget build(BuildContext context) {
    final fuelTypes = (widget.options['fuelTypes'] as List<dynamic>?)?.cast<String>() ?? [];
    final transmissions = (widget.options['transmissions'] as List<dynamic>?)?.cast<String>() ?? [];
    final seatsList = (widget.options['seats'] as List<dynamic>?)?.cast<int>() ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Cars',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          
          if (fuelTypes.isNotEmpty) ...[
            const Text('Fuel Type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: fuelTypes.map((f) {
                final isSelected = _fuel == f;
                return ChoiceChip(
                  label: Text(f),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                  onSelected: (val) {
                    setState(() => _fuel = val ? f : null);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          if (transmissions.isNotEmpty) ...[
            const Text('Transmission', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: transmissions.map((t) {
                final isSelected = _transmission == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                  onSelected: (val) {
                    setState(() => _transmission = val ? t : null);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          if (seatsList.isNotEmpty) ...[
            const Text('Seating Capacity', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: seatsList.map((s) {
                final isSelected = _seats == s;
                return ChoiceChip(
                  label: Text('$s Seats'),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                  onSelected: (val) {
                    setState(() => _seats = val ? s : null);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_fuel, _transmission, _seats);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

