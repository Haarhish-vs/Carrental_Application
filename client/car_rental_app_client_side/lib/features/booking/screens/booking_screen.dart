import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../../models/booking_step.dart';
import '../../models/booking_flow_state.dart';
import '../../models/vehicle_model.dart';
import '../providers/booking_provider.dart';
import '../widgets/cards/vehicle_booking_card.dart';
import '../widgets/inputs/location_selector.dart';
import '../widgets/pickers/custom_date_picker.dart';
import '../widgets/pickers/custom_time_picker.dart';
import '../widgets/bottom_sheets/location_search_sheet.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final List<Vehicle> _vehicles = [
    const Vehicle(
      id: "veh_tesla",
      name: "Tesla Model S Plaid",
      imageUrl: AppImages.mockCarTesla,
      pricePerDay: 149.0,
      specifications: ["Electric", "1020 HP", "5 Seats", "Auto"],
      rating: 4.95,
    ),
    const Vehicle(
      id: "veh_audi",
      name: "Audi R8 Coupe",
      imageUrl: AppImages.mockCarAudi,
      pricePerDay: 199.0,
      specifications: ["Petrol", "562 HP", "2 Seats", "Auto"],
      rating: 4.88,
    ),
    const Vehicle(
      id: "veh_porsche",
      name: "Porsche 911 Carrera",
      imageUrl: AppImages.mockCarPorsche,
      pricePerDay: 179.0,
      specifications: ["Petrol", "379 HP", "4 Seats", "PDK"],
      rating: 4.92,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flow = ref.read(bookingFlowProvider);
      if (flow.vehicle == null) {
        ref.read(bookingFlowProvider.notifier).setVehicle(_vehicles[0]);
      }
      ref.read(bookingFlowProvider.notifier).setStep(BookingStep.vehicle);
    });
  }

  void _openLocationSearch(BuildContext context, bool isPickup) {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSearchSheet(
        title: isPickup ? "Choose Pickup Location" : "Choose Return Location",
      ),
    ).then((selected) {
      if (selected != null) {
        if (isPickup) {
          ref.read(bookingFlowProvider.notifier).setLocations(pickup: selected);
        } else {
          ref.read(bookingFlowProvider.notifier).setLocations(returnLoc: selected);
        }
      }
    });
  }

  void _validateAndNavigate() {
    final state = ref.read(bookingFlowProvider);

    if (state.pickupLocation == null || state.pickupLocation!.isEmpty) {
      _showError("Please select a pickup location");
      return;
    }
    if (state.returnLocation == null || state.returnLocation!.isEmpty) {
      _showError("Please select a return location");
      return;
    }
    if (state.pickupDateTime == null) {
      _showError("Please choose a pickup date and time");
      return;
    }
    if (state.returnDateTime == null) {
      _showError("Please choose a return date and time");
      return;
    }
    if (state.returnDateTime!.isBefore(state.pickupDateTime!)) {
      _showError("Return date/time cannot be before pickup date/time");
      return;
    }

    // Progression
    if (state.rentalType == RentalType.withDriver) {
      context.push(AppRoutes.driverSelection);
    } else {
      context.push(AppRoutes.additionalServices);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingFlowProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= AppSizes.tabletBreakpoint;

    return AppScaffold(
      title: "Booking Checkout",
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Vehicle Selection Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
              child: Text(
                "Select Luxury Ride",
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 2. Horizontal Vehicle List
          SliverToBoxAdapter(
            child: SizedBox(
              height: 310,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = _vehicles[index];
                  final isSelected = state.vehicle?.id == vehicle.id;
                  return Container(
                    width: isTablet ? 380 : 310,
                    margin: const EdgeInsets.only(right: AppSpacing.md, bottom: AppSpacing.sm),
                    child: VehicleBookingCard(
                      vehicle: vehicle,
                      isSelected: isSelected,
                      onTap: () => ref.read(bookingFlowProvider.notifier).setVehicle(vehicle),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Rental Form & Schedule Fields
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(AppSpacing.sm),
                  Text(
                    "Rental Specifications",
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Gap(AppSpacing.md),

                  // Rental Style Selector (Self Drive vs Driver)
                  Row(
                    children: [
                      Expanded(
                        child: _RentalTypeTab(
                          label: "Self Drive",
                          icon: Icons.vpn_key_outlined,
                          isSelected: state.rentalType == RentalType.selfDrive,
                          onTap: () => ref.read(bookingFlowProvider.notifier).setRentalType(RentalType.selfDrive),
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Expanded(
                        child: _RentalTypeTab(
                          label: "With Driver",
                          icon: Icons.person_pin_outlined,
                          isSelected: state.rentalType == RentalType.withDriver,
                          onTap: () => ref.read(bookingFlowProvider.notifier).setRentalType(RentalType.withDriver),
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.lg),

                  // Location Input Fields
                  LocationSelector(
                    label: "PICK-UP HUB",
                    placeholder: "Select pick-up airport or station",
                    selectedLocation: state.pickupLocation,
                    onTap: () => _openLocationSearch(context, true),
                  ),
                  const Gap(AppSpacing.md),
                  LocationSelector(
                    label: "RETURN HUB",
                    placeholder: "Select return airport or station",
                    selectedLocation: state.returnLocation,
                    onTap: () => _openLocationSearch(context, false),
                  ),
                  const Gap(AppSpacing.lg),

                  // DateTime Picker Grid
                  Row(
                    children: [
                      Expanded(
                        child: CustomDatePicker(
                          label: "PICK-UP DATE",
                          placeholder: "Select Date",
                          selectedDate: state.pickupDateTime,
                          onDateSelected: (date) {
                            final time = state.pickupDateTime != null
                                ? TimeOfDay.fromDateTime(state.pickupDateTime!)
                                : const TimeOfDay(hour: 10, minute: 0);
                            ref.read(bookingFlowProvider.notifier).setDateTimes(
                                  pickup: DateTime(date.year, date.month, date.day, time.hour, time.minute),
                                );
                          },
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Expanded(
                        child: CustomTimePicker(
                          label: "PICK-UP TIME",
                          placeholder: "Select Time",
                          selectedTime: state.pickupDateTime != null
                              ? TimeOfDay.fromDateTime(state.pickupDateTime!)
                              : null,
                          onTimeSelected: (time) {
                            final date = state.pickupDateTime ?? DateTime.now();
                            ref.read(bookingFlowProvider.notifier).setDateTimes(
                                  pickup: DateTime(date.year, date.month, date.day, time.hour, time.minute),
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: CustomDatePicker(
                          label: "RETURN DATE",
                          placeholder: "Select Date",
                          selectedDate: state.returnDateTime,
                          firstDate: state.pickupDateTime ?? DateTime.now(),
                          onDateSelected: (date) {
                            final time = state.returnDateTime != null
                                ? TimeOfDay.fromDateTime(state.returnDateTime!)
                                : const TimeOfDay(hour: 10, minute: 0);
                            ref.read(bookingFlowProvider.notifier).setDateTimes(
                                  returnDT: DateTime(date.year, date.month, date.day, time.hour, time.minute),
                                );
                          },
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Expanded(
                        child: CustomTimePicker(
                          label: "RETURN TIME",
                          placeholder: "Select Time",
                          selectedTime: state.returnDateTime != null
                              ? TimeOfDay.fromDateTime(state.returnDateTime!)
                              : null,
                          onTimeSelected: (time) {
                            final date = state.returnDateTime ?? DateTime.now().add(const Duration(days: 1));
                            ref.read(bookingFlowProvider.notifier).setDateTimes(
                                  returnDT: DateTime(date.year, date.month, date.day, time.hour, time.minute),
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  // Dynamic Duration tag
                  if (state.pickupDateTime != null && state.returnDateTime != null) ...[
                    const Gap(AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: AppColors.accent, size: 20),
                              const Gap(10),
                              Text(
                                "Total Rental Duration",
                                style: AppTextStyles.subtitle2.copyWith(color: AppColors.slate800),
                              ),
                            ],
                          ),
                          Text(
                            "${state.rentalDurationDays} ${state.rentalDurationDays == 1 ? 'Day' : 'Days'}",
                            style: AppTextStyles.h3.copyWith(fontSize: 16, color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Gap(AppSpacing.xxl),
                  
                  // Navigation Bottom CTA button
                  ElevatedButton(
                    onPressed: _validateAndNavigate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.rentalType == RentalType.withDriver
                              ? "Select Driver"
                              : "Choose Accessories",
                        ),
                        const Gap(8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RentalTypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RentalTypeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: AppRadius.mdBorderRadius,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.slate200,
            width: 1.5,
          ),
          boxShadow: isSelected ? AppElevation.selectShadow : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.slate600,
              size: 24,
            ),
            const Gap(6),
            Text(
              label,
              style: AppTextStyles.subtitle2.copyWith(
                color: isSelected ? Colors.white : AppColors.slate800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
