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
          const SizedBox(width: 4),
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
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      // Floating Bottom Action Bar (Map View & Sort)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Map View coming soon')),
                    );
                  },
                  icon: const Icon(Icons.map_outlined, size: 18, color: AppColors.primary),
                  label: const Text(
                    'Map View',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openSortSheet,
                  icon: const Icon(Icons.sort_rounded, size: 18),
                  label: const Text(
                    'Sort',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
