import 'package:flutter/material.dart';
import 'package:car_rental_app_client_side/core/theme/app_colors.dart';
import 'package:car_rental_app_client_side/features/location/presentation/location_flow.dart';
import 'package:car_rental_app_client_side/features/home/presentation/screens/car_detail_screen.dart';
import 'package:car_rental_app_client_side/features/search/data/models/search_parameters.dart';
import 'package:car_rental_app_client_side/features/search/presentation/providers/search_cars_provider.dart';
import 'package:car_rental_app_client_side/features/search/presentation/widgets/car_loading_skeleton.dart';
import 'package:car_rental_app_client_side/features/search/presentation/widgets/car_result_card.dart';
import 'package:car_rental_app_client_side/features/search/presentation/widgets/empty_cars_view.dart';
import 'package:car_rental_app_client_side/features/search/presentation/widgets/filter_bottom_sheet.dart';
import 'package:car_rental_app_client_side/features/search/presentation/widgets/search_cars_error_view.dart';
import 'package:car_rental_app_client_side/features/search/presentation/widgets/search_summary_card.dart';
import 'package:car_rental_app_client_side/features/search/presentation/widgets/sort_bottom_sheet.dart';

class SearchCarsScreen extends StatefulWidget {
  final SearchParameters initialParams;

  const SearchCarsScreen({
    super.key,
    required this.initialParams,
  });

  @override
  State<SearchCarsScreen> createState() => _SearchCarsScreenState();
}

class _SearchCarsScreenState extends State<SearchCarsScreen> {
  late final SearchCarsProvider _provider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _provider = SearchCarsProvider();
    _provider.init(widget.initialParams);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _provider.loadMore();
    }
  }

  Future<void> _handleChangeLocation() async {
    final selectedLocation = await LocationFlow.start(context);
    if (selectedLocation != null && mounted) {
      await _provider.updateLocation(selectedLocation);
    }
  }

  DateTime _parseDate(String dateStr) {
    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } else if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      }
    } catch (_) {}
    return DateTime.now();
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final upper = timeStr.toUpperCase();
      if (upper.contains('AM') || upper.contains('PM')) {
        final isPm = upper.contains('PM');
        final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = clean.split(':');
        int hour = int.parse(parts[0]);
        final min = parts.length > 1 ? int.parse(parts[1]) : 0;
        if (isPm && hour < 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: min);
      } else if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}
    return const TimeOfDay(hour: 10, minute: 0);
  }

  Future<void> _handlePickDate({required bool isPickup}) async {
    final currentParams = _provider.params ?? widget.initialParams;
    final now = DateTime.now();
    final initial = isPickup
        ? _parseDate(currentParams.pickupDate)
        : _parseDate(currentParams.returnDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked == null || !mounted) return;

    final formatted =
        '${picked.day.toString().padLeft(2, '0')}/'
        '${picked.month.toString().padLeft(2, '0')}/${picked.year}';

    if (isPickup) {
      String newReturnDate = currentParams.returnDate;
      final pickupDt = picked;
      final currentReturnDt = _parseDate(currentParams.returnDate);
      if (currentReturnDt.isBefore(pickupDt)) {
        final nextDay = pickupDt.add(const Duration(days: 1));
        newReturnDate =
            '${nextDay.day.toString().padLeft(2, '0')}/'
            '${nextDay.month.toString().padLeft(2, '0')}/${nextDay.year}';
      }
      await _provider.updateDatesAndTimes(
        pickupDate: formatted,
        returnDate: newReturnDate,
      );
    } else {
      await _provider.updateDatesAndTimes(
        returnDate: formatted,
      );
    }
  }

  Future<void> _handlePickTime({required bool isPickup}) async {
    final currentParams = _provider.params ?? widget.initialParams;
    final initial = isPickup
        ? _parseTime(currentParams.pickupTime)
        : _parseTime(currentParams.returnTime);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked == null || !mounted) return;

    final formatted = picked.format(context);

    if (isPickup) {
      await _provider.updateDatesAndTimes(pickupTime: formatted);
    } else {
      await _provider.updateDatesAndTimes(returnTime: formatted);
    }
  }

  void _openSortSheet() {
    SortBottomSheet.show(
      context,
      currentSort: _provider.appliedFilters.sort,
      onSelectSort: (newSort) {
        _provider.setSortAndApply(newSort);
      },
    );
  }

  void _openFilterSheet() {
    FilterBottomSheet.show(context, _provider);
  }

  String _getSortLabel(String key) {
    final match = SortBottomSheet.options.firstWhere(
      (opt) => opt.key == key,
      orElse: () => const SortOption(key: 'recommended', label: 'Recommended'),
    );
    return match.label;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Search Cars',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _provider,
            builder: (context, _) {
              final hasActive = _provider.appliedFilters.hasActiveFilters;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
                    onPressed: _openFilterSheet,
                    tooltip: 'Filter',
                  ),
                  if (hasActive)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _provider,
          builder: (context, _) {
            final params = _provider.params ?? widget.initialParams;
            final status = _provider.status;
            final count = _provider.totalCount;
            final cars = _provider.cars;
            final sortLabel = _getSortLabel(_provider.appliedFilters.sort);

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _provider.search(isRefresh: true),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. Search Summary Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: SearchSummaryCard(
                        params: params,
                        onChangeLocation: _handleChangeLocation,
                        onPickupDateTap: () => _handlePickDate(isPickup: true),
                        onPickupTimeTap: () => _handlePickTime(isPickup: true),
                        onReturnDateTap: () => _handlePickDate(isPickup: false),
                        onReturnTimeTap: () => _handlePickTime(isPickup: false),
                        onChangeDates: () => _handlePickDate(isPickup: true),
                      ),
                    ),
                  ),

                  // 2. Count and Sort Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            status == SearchCarsStatus.loading
                                ? 'Searching cars...'
                                : '$count ${count == 1 ? 'Car' : 'Cars'} Found',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          InkWell(
                            onTap: _openSortSheet,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    'Sort by: $sortLabel',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Dynamic Result List / Skeleton / Empty / Error States
                  if (status == SearchCarsStatus.loading && cars.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: CarLoadingSkeleton(),
                      ),
                    )
                  else if (status == SearchCarsStatus.error)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: SearchCarsErrorView(
                          message: _provider.errorMessage,
                          onRetry: () => _provider.search(),
                        ),
                      ),
                    )
                  else if (status == SearchCarsStatus.empty || (status == SearchCarsStatus.success && cars.isEmpty))
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: EmptyCarsView(
                          hasActiveFilters: _provider.appliedFilters.hasActiveFilters,
                          onResetFilters: () {
                            _provider.clearTempFilters();
                            _provider.applyFilters();
                          },
                          onChangeLocation: _handleChangeLocation,
                        ),
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final car = cars[index];
                            return CarResultCard(
                              car: car,
                              onViewDetails: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CarDetailScreen(car: car),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: cars.length,
                        ),
                      ),
                    ),

                    // Pagination Loading Indicator at Bottom
                    if (_provider.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],

                  // Extra bottom padding for comfortable scrolling
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
