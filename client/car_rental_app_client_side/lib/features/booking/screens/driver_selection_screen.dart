import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../models/booking_step.dart';
import '../models/driver_model.dart';
import '../models/location_model.dart';
import '../providers/booking_provider.dart';
import '../repositories/driver_repository.dart';
import '../widgets/cards/driver_card.dart';
import '../widgets/cards/driver_card_skeleton.dart';
import '../widgets/bottom_sheets/location_search_sheet.dart';

class DriverSelectionScreen extends ConsumerStatefulWidget {
  const DriverSelectionScreen({super.key});

  @override
  ConsumerState<DriverSelectionScreen> createState() =>
      _DriverSelectionScreenState();
}

class _DriverSelectionScreenState extends ConsumerState<DriverSelectionScreen> {
  String _selectedSort = "Recommended";
  bool _onlyVerified = false;
  String _selectedLanguage = "All";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingFlowProvider.notifier).setStep(BookingStep.driver);
    });
  }

  void _validateAndNavigate() {
    final state = ref.read(bookingFlowProvider);
    if (state.driver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please select a driver to proceed",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
      return;
    }

    ref.read(bookingFlowProvider.notifier).nextStep();
    context.push(AppRoutes.additionalServices);
  }

  void _showLocationSheet() async {
    final selectedLoc = await showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          const LocationSearchSheet(title: "Select Pickup Hub"),
    );
    if (selectedLoc != null && mounted) {
      ref.read(bookingFlowProvider.notifier).setLocations(pickup: selectedLoc);
      ref.invalidate(driversListProvider);
    }
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );
      if (pickedTime == null || !mounted) return;

      final selectedDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      final currentReturn = ref.read(bookingFlowProvider).returnDateTime;
      final newReturn =
          currentReturn ?? selectedDateTime.add(const Duration(days: 3));

      ref
          .read(bookingFlowProvider.notifier)
          .setDateTimes(
            pickup: selectedDateTime,
            returnDT: newReturn.isBefore(selectedDateTime)
                ? selectedDateTime.add(const Duration(days: 1))
                : newReturn,
          );
      ref.invalidate(driversListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final driversListAsync = ref.watch(driversListProvider);

    // State 1: Location Missing
    if (flowState.pickupLocation == null) {
      return AppScaffold(
        title: "Driver Assignment",
        body: _buildLocationMissingView(),
      );
    }

    // State 2: Date/Time Missing
    if (flowState.pickupDateTime == null) {
      return AppScaffold(
        title: "Driver Assignment",
        body: _buildDateTimeMissingView(),
      );
    }

    return AppScaffold(
      title: "Driver Assignment",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subheader Info
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Drivers available near ${flowState.pickupLocation!.name}",
                        style: AppTextStyles.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ref
                            .read(bookingFlowProvider.notifier)
                            .clearErrorMessage();
                        ref.invalidate(driversListProvider);
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.accent,
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text(
                        "Refresh",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Availability checked just now",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.slate400,
                        fontSize: 10,
                      ),
                    ),
                    if (flowState.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          flowState.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Filters / Sorters Toolbar
          _buildFiltersToolbar(),

          // Main List Content (States 3, 4, 5)
          Expanded(
            child: driversListAsync.when(
              data: (drivers) {
                // Apply optional filters and sorting
                var displayList = List<Driver>.from(drivers);

                // Filter by Verified
                if (_onlyVerified) {
                  displayList = displayList.where((d) => d.isVerified).toList();
                }

                // Filter by Language
                if (_selectedLanguage != "All") {
                  displayList = displayList
                      .where((d) => d.languages.contains(_selectedLanguage))
                      .toList();
                }

                // Sort
                if (_selectedSort == "Recommended") {
                  displayList.sort((a, b) {
                    final ratingCompare = b.rating.compareTo(a.rating);
                    if (ratingCompare != 0) return ratingCompare;

                    final distA = MockDriverRepository.calculateDistance(
                      a.latitude,
                      a.longitude,
                      flowState.pickupLocation!.latitude,
                      flowState.pickupLocation!.longitude,
                    );
                    final distB = MockDriverRepository.calculateDistance(
                      b.latitude,
                      b.longitude,
                      flowState.pickupLocation!.latitude,
                      flowState.pickupLocation!.longitude,
                    );
                    final distCompare = distA.compareTo(distB);
                    if (distCompare != 0) return distCompare;

                    return b.experienceYears.compareTo(a.experienceYears);
                  });
                } else if (_selectedSort == "Highest Rated") {
                  displayList.sort((a, b) => b.rating.compareTo(a.rating));
                } else if (_selectedSort == "Nearest") {
                  displayList.sort((a, b) {
                    final distA = MockDriverRepository.calculateDistance(
                      a.latitude,
                      a.longitude,
                      flowState.pickupLocation!.latitude,
                      flowState.pickupLocation!.longitude,
                    );
                    final distB = MockDriverRepository.calculateDistance(
                      b.latitude,
                      b.longitude,
                      flowState.pickupLocation!.latitude,
                      flowState.pickupLocation!.longitude,
                    );
                    return distA.compareTo(distB);
                  });
                } else if (_selectedSort == "Lowest Price") {
                  displayList.sort(
                    (a, b) => a.pricePerDay.compareTo(b.pricePerDay),
                  );
                }

                if (displayList.isEmpty) {
                  return _buildNoDriversAvailableView();
                }

                // Identify the recommended driver ID (the best overall from original list)
                final recommendedDriverId = drivers.isNotEmpty
                    ? drivers.first.id
                    : null;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final driver = displayList[index];
                    final isSelected = flowState.driver?.id == driver.id;
                    final isRec = recommendedDriverId == driver.id;
                    final distance = MockDriverRepository.calculateDistance(
                      driver.latitude,
                      driver.longitude,
                      flowState.pickupLocation!.latitude,
                      flowState.pickupLocation!.longitude,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: DriverCard(
                        driver: driver,
                        isSelected: isSelected,
                        isRecommended: isRec,
                        distance: distance,
                        onTap: () {
                          if (isSelected) {
                            ref
                                .read(bookingFlowProvider.notifier)
                                .selectDriver(null);
                          } else {
                            ref
                                .read(bookingFlowProvider.notifier)
                                .selectDriver(driver);
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: 3,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: DriverCardSkeleton(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const Gap(AppSpacing.sm),
                      Text(
                        "Couldn't check driver availability.",
                        style: AppTextStyles.subtitle1.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => ref.refresh(driversListProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Try Again"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom CTA Actions
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(bookingFlowProvider.notifier).prevStep();
                      context.pop();
                    },
                    child: const Text("Back"),
                  ),
                ),
                const Gap(12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _validateAndNavigate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Continue"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMissingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 64,
              color: AppColors.slate300,
            ),
            const Gap(AppSpacing.md),
            Text(
              "Choose Pickup Location",
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Text(
              "Select where you want the driver to pick you up.",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.slate500,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.xl),
            ElevatedButton(
              onPressed: _showLocationSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
              ),
              child: const Text("Choose Location"),
            ),
            const Gap(AppSpacing.lg),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeMissingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: AppColors.slate300,
            ),
            const Gap(AppSpacing.md),
            Text(
              "Choose Pickup Time",
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Text(
              "Select your pickup date and time to see available drivers.",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.slate500,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.xl),
            ElevatedButton(
              onPressed: _showDatePicker,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
              ),
              child: const Text("Choose Date & Time"),
            ),
            const Gap(AppSpacing.lg),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDriversAvailableView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: AppColors.slate300,
            ),
            const Gap(AppSpacing.md),
            Text(
              "No drivers available",
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Text(
              "We couldn't find available drivers for this location and time.",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.slate500,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _showLocationSheet,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(140, 48),
                  ),
                  child: const Text("Change Location"),
                ),
                const Gap(12),
                ElevatedButton(
                  onPressed: _showDatePicker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(140, 48),
                  ),
                  child: const Text("Change Time"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // Sort Dropdown/Chip
          DropdownButton<String>(
            value: _selectedSort,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.slate700,
            ),
            items:
                <String>[
                      "Recommended",
                      "Highest Rated",
                      "Nearest",
                      "Lowest Price",
                    ]
                    .map(
                      (val) => DropdownMenuItem<String>(
                        value: val,
                        child: Text(val),
                      ),
                    )
                    .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedSort = val;
                });
              }
            },
          ),
          const Gap(12),

          // Verified Filter Chip
          FilterChip(
            label: const Text(
              "Verified Only",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            selected: _onlyVerified,
            onSelected: (val) {
              setState(() {
                _onlyVerified = val;
              });
            },
            selectedColor: AppColors.lightBlue,
            checkmarkColor: AppColors.accent,
          ),
          const Gap(12),

          // Language Selector
          const Row(
            children: [
              Icon(Icons.language_rounded, size: 14, color: AppColors.slate400),
              Gap(4),
            ],
          ),
          DropdownButton<String>(
            value: _selectedLanguage,
            underline: const SizedBox(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.slate700,
            ),
            items: <String>["All", "Tamil", "English", "Hindi", "French"]
                .map(
                  (lang) =>
                      DropdownMenuItem<String>(value: lang, child: Text(lang)),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedLanguage = val;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
