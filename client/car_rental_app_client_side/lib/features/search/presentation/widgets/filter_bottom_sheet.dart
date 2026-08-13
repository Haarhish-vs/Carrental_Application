import 'package:flutter/material.dart';
import 'package:car_rental_app_client_side/core/theme/app_colors.dart';
import 'package:car_rental_app_client_side/features/search/presentation/providers/search_cars_provider.dart';
import 'package:car_rental_app_client_side/features/search/presentation/widgets/filter_option_chip.dart';

class FilterBottomSheet extends StatefulWidget {
  final SearchCarsProvider provider;

  const FilterBottomSheet({super.key, required this.provider});

  static Future<void> show(BuildContext context, SearchCarsProvider provider) {
    provider.openFilterSheet();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FilterBottomSheet(provider: provider),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late SearchCarsProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, child) {
        final options = _provider.filterOptions;
        final temp = _provider.tempFilters;

        final minPriceBound = options.minPrice > 0 ? options.minPrice : 0.0;
        final maxPriceBound = options.maxPrice > minPriceBound ? options.maxPrice : (minPriceBound + 10000.0);

        final currentMin = (temp.minPrice != null && temp.minPrice! >= minPriceBound && temp.minPrice! <= maxPriceBound)
            ? temp.minPrice!
            : minPriceBound;

        final currentMax = (temp.maxPrice != null && temp.maxPrice! <= maxPriceBound && temp.maxPrice! >= currentMin)
            ? temp.maxPrice!
            : maxPriceBound;

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              // Modal drag handle & Title Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        InkWell(
                          onTap: () => _provider.clearTempFilters(),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              'Clear All',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),

              // Scrollable Filter Options Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. CAR TYPE
                      _buildSectionHeader('CAR TYPE'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilterOptionChip(
                            label: 'All',
                            isSelected: temp.carType == null || temp.carType!.isEmpty,
                            onTap: () => _provider.setTempCarType(null),
                          ),
                          ...options.carTypes.map((type) {
                            final isSelected = temp.carType?.toLowerCase() == type.toLowerCase();
                            return FilterOptionChip(
                              label: type,
                              isSelected: isSelected,
                              onTap: () => _provider.setTempCarType(isSelected ? null : type),
                            );
                          }),
                        ],
                      ),

                      // 2. TRANSMISSION
                      _buildSectionHeader('TRANSMISSION'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilterOptionChip(
                            label: 'All',
                            isSelected: temp.transmission == null || temp.transmission!.isEmpty,
                            onTap: () => _provider.setTempTransmission(null),
                          ),
                          ...options.transmissions.map((trans) {
                            final isSelected = temp.transmission?.toLowerCase() == trans.toLowerCase();
                            return FilterOptionChip(
                              label: trans,
                              isSelected: isSelected,
                              onTap: () => _provider.setTempTransmission(isSelected ? null : trans),
                            );
                          }),
                        ],
                      ),

                      // 3. FUEL TYPE
                      _buildSectionHeader('FUEL TYPE'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilterOptionChip(
                            label: 'All',
                            isSelected: temp.fuelType == null || temp.fuelType!.isEmpty,
                            onTap: () => _provider.setTempFuelType(null),
                          ),
                          ...options.fuelTypes.map((fuel) {
                            final isSelected = temp.fuelType?.toLowerCase() == fuel.toLowerCase();
                            return FilterOptionChip(
                              label: fuel,
                              isSelected: isSelected,
                              onTap: () => _provider.setTempFuelType(isSelected ? null : fuel),
                            );
                          }),
                        ],
                      ),

                      // 4. SEATS
                      _buildSectionHeader('SEATS'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilterOptionChip(
                            label: 'All',
                            isSelected: temp.seats == null || temp.seats == 0,
                            onTap: () => _provider.setTempSeats(null),
                          ),
                          ...options.seatOptions.map((seats) {
                            final label = seats >= 7 ? '$seats+ Seater' : '$seats Seater';
                            final isSelected = temp.seats == seats;
                            return FilterOptionChip(
                              label: label,
                              isSelected: isSelected,
                              onTap: () => _provider.setTempSeats(isSelected ? null : seats),
                            );
                          }),
                        ],
                      ),

                      // 5. PRICE RANGE
                      _buildSectionHeader('PRICE RANGE'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${currentMin.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '₹${currentMax.toStringAsFixed(0)}+',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      RangeSlider(
                        values: RangeValues(currentMin, currentMax),
                        min: minPriceBound,
                        max: maxPriceBound,
                        divisions: (maxPriceBound - minPriceBound) > 100 ? ((maxPriceBound - minPriceBound) ~/ 100) : 10,
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.grey.shade200,
                        labels: RangeLabels(
                          '₹${currentMin.toStringAsFixed(0)}',
                          '₹${currentMax.toStringAsFixed(0)}',
                        ),
                        onChanged: (values) {
                          _provider.setTempPriceRange(values.start, values.end);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky Action Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _provider.applyFilters();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
