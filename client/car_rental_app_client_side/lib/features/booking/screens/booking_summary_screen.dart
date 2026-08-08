import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/design_system/radius.dart';
import '../../../../core/design_system/elevation.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../models/booking_step.dart';
import '../models/booking_flow_state.dart';
import '../models/service_model.dart';
import '../models/location_model.dart';
import '../providers/booking_provider.dart';
import '../utils/booking_price_calculator.dart';
import '../utils/currency_formatter.dart';
import '../widgets/bottom_sheets/location_search_sheet.dart';
import '../repositories/driver_repository.dart';

class BookingSummaryScreen extends ConsumerStatefulWidget {
  const BookingSummaryScreen({super.key});

  @override
  ConsumerState<BookingSummaryScreen> createState() =>
      _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingFlowProvider.notifier).setStep(BookingStep.summary);
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not selected';
    return DateFormat('EEE, MMM d, h:mm a').format(dateTime);
  }

  double? _getDriverDistance(BookingFlowState flowState) {
    if (flowState.driver == null || flowState.pickupLocation == null) {
      return null;
    }
    return MockDriverRepository.calculateDistance(
      flowState.driver!.latitude,
      flowState.driver!.longitude,
      flowState.pickupLocation!.latitude,
      flowState.pickupLocation!.longitude,
    );
  }

  bool _isPickupInPast(DateTime? pickup) {
    if (pickup == null) return false;
    // Allow a 5-minute buffer for user action latency
    return pickup.isBefore(DateTime.now().subtract(const Duration(minutes: 5)));
  }

  bool _isReturnBeforePickup(DateTime? pickup, DateTime? returnDT) {
    if (pickup == null || returnDT == null) return false;
    return returnDT.isBefore(pickup) || returnDT.isAtSameMomentAs(pickup);
  }

  String? _getDateValidationError(BookingFlowState flowState) {
    final pickup = flowState.pickupDateTime;
    final returnDT = flowState.returnDateTime;
    if (pickup == null || returnDT == null) {
      return "Pickup and return dates are required.";
    }
    if (_isPickupInPast(pickup)) {
      return "Pickup date/time cannot be in the past.";
    }
    if (_isReturnBeforePickup(pickup, returnDT)) {
      return "Return date/time must be after pickup date/time.";
    }
    return null;
  }

  void _showDatePickerSheet(bool isPickup) async {
    final flow = ref.read(bookingFlowProvider);
    final initialDate = isPickup
        ? (flow.pickupDateTime ?? DateTime.now().add(const Duration(days: 1)))
        : (flow.returnDateTime ?? DateTime.now().add(const Duration(days: 4)));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(DateTime.now())
          ? DateTime.now()
          : initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime == null || !mounted) return;

      final selectedDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (isPickup) {
        ref
            .read(bookingFlowProvider.notifier)
            .setDateTimes(
              pickup: selectedDateTime,
              returnDT: flow.returnDateTime,
            );
      } else {
        ref
            .read(bookingFlowProvider.notifier)
            .setDateTimes(
              pickup: flow.pickupDateTime,
              returnDT: selectedDateTime,
            );
      }
    }
  }

  void _showLocationSheet(bool isPickup) async {
    final selectedLoc = await showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) => LocationSearchSheet(
        title: isPickup ? "Select Pickup Hub" : "Select Return Hub",
      ),
    );
    if (selectedLoc != null && mounted) {
      if (isPickup) {
        ref
            .read(bookingFlowProvider.notifier)
            .setLocations(
              pickup: selectedLoc,
              returnLoc: ref.read(bookingFlowProvider).returnLocation,
            );
      } else {
        ref
            .read(bookingFlowProvider.notifier)
            .setLocations(
              pickup: ref.read(bookingFlowProvider).pickupLocation,
              returnLoc: selectedLoc,
            );
      }
    }
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Contact Support",
            style: AppTextStyles.h3.copyWith(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.phone_outlined,
                  color: AppColors.accent,
                ),
                title: const Text("+1 (800) 555-0199"),
                subtitle: const Text("Toll-Free Customer Line"),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.accent,
                ),
                title: const Text("Live Chat In-App"),
                subtitle: const Text("Average wait: 2 mins"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final vehicle = flowState.vehicle;

    final baseCharge = BookingPriceCalculator.calculateBaseRentalCharge(
      flowState,
    );
    final driverFee = BookingPriceCalculator.calculateDriverFee(flowState);
    final insuranceFee = BookingPriceCalculator.calculateInsurance(flowState);
    final additionalServicesFee =
        BookingPriceCalculator.calculateAdditionalServices(flowState);
    final discount = BookingPriceCalculator.calculateDiscount(flowState);
    final tax = BookingPriceCalculator.calculateTax(flowState);
    final deposit = BookingPriceCalculator.calculateSecurityDeposit(flowState);
    final totalAmount = BookingPriceCalculator.calculateGrandTotal(flowState);

    final days = flowState.rentalDurationDays;
    final hasDriver = flowState.rentalType == RentalType.withDriver;
    final hasInsurance = flowState.selectedServices.any(
      (s) => s.id == "srv_insurance",
    );

    final dateError = _getDateValidationError(flowState);
    final isDriverRequiredButMissing = hasDriver && flowState.driver == null;
    final isCheckoutEnabled =
        dateError == null && !isDriverRequiredButMissing && vehicle != null;

    return AppScaffold(
      title: "Complete Booking",
      actions: [
        IconButton(
          onPressed: _showSupportDialog,
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Vehicle Selection Card
                  if (vehicle != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.lgBorderRadius,
                        border: Border.all(color: AppColors.slate200),
                        boxShadow: AppElevation.cardShadow,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              vehicle.imageUrl,
                              width: 80,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 60,
                                color: AppColors.slate100,
                                child: const Icon(
                                  Icons.directions_car,
                                  color: AppColors.slate400,
                                ),
                              ),
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.name,
                                  style: AppTextStyles.subtitle1.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.slate900,
                                    fontSize: 15,
                                  ),
                                ),
                                const Gap(4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFBBF24),
                                      size: 14,
                                    ),
                                    const Gap(2),
                                    Text(
                                      "${vehicle.rating}",
                                      style: const TextStyle(
                                        color: AppColors.slate800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Gap(8),
                                    Text(
                                      "${formatCurrency(vehicle.pricePerDay)}/day",
                                      style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(bookingFlowProvider.notifier).reset();
                              context.go(AppRoutes.booking);
                            },
                            child: const Text(
                              "Change",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Gap(AppSpacing.md),

                  // 2. Pickup & Return Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.lgBorderRadius,
                      border: Border.all(color: AppColors.slate200),
                      boxShadow: AppElevation.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const Gap(8),
                            Text(
                              "Schedule & Location",
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.md),

                        // Pickup Section
                        const Text(
                          "PICKUP LOCATION & TIME",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Gap(6),
                        GestureDetector(
                          onTap: () => _showLocationSheet(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.pin_drop_rounded,
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Text(
                                    flowState.pickupLocation?.name ??
                                        "Select Pickup Hub",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: flowState.pickupLocation != null
                                          ? AppColors.slate800
                                          : AppColors.slate400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: AppColors.slate400,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Gap(6),
                        GestureDetector(
                          onTap: () => _showDatePickerSheet(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Text(
                                    flowState.pickupDateTime != null
                                        ? _formatDateTime(
                                            flowState.pickupDateTime,
                                          )
                                        : "Select Pickup Date & Time",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: flowState.pickupDateTime != null
                                          ? AppColors.slate800
                                          : AppColors.slate400,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: AppColors.slate400,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Gap(AppSpacing.md),
                        const Divider(),
                        const Gap(AppSpacing.md),

                        // Return Section
                        const Text(
                          "RETURN LOCATION & TIME",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Gap(6),
                        GestureDetector(
                          onTap: () => _showLocationSheet(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.pin_drop_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Text(
                                    flowState.returnLocation?.name ??
                                        "Select Return Hub",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: flowState.returnLocation != null
                                          ? AppColors.slate800
                                          : AppColors.slate400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: AppColors.slate400,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Gap(6),
                        GestureDetector(
                          onTap: () => _showDatePickerSheet(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const Gap(8),
                                Expanded(
                                  child: Text(
                                    flowState.returnDateTime != null
                                        ? _formatDateTime(
                                            flowState.returnDateTime,
                                          )
                                        : "Select Return Date & Time",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: flowState.returnDateTime != null
                                          ? AppColors.slate800
                                          : AppColors.slate400,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: AppColors.slate400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Gap(AppSpacing.md),

                  // 3. Route Map Preview Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.lgBorderRadius,
                      border: Border.all(color: AppColors.slate200),
                      boxShadow: AppElevation.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.map_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const Gap(8),
                            Text(
                              "Route Preview",
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.network(
                                "https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=800",
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                height: 120,
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: AppElevation.cardShadow,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.navigation_rounded,
                                        size: 12,
                                        color: Color(0xFF2563EB),
                                      ),
                                      const Gap(4),
                                      Text(
                                        "$days day trip",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Gap(
                    AppSpacing.md,
                  ), // 4. Self-Drive vs With-Driver Mode Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.lgBorderRadius,
                      border: Border.all(color: AppColors.slate200),
                      boxShadow: AppElevation.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.commute_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const Gap(8),
                            Text(
                              "Travel Mode Selector",
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(bookingFlowProvider.notifier)
                                        .setRentalType(RentalType.selfDrive);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !hasDriver
                                          ? AppColors.accent
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Self Drive",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: !hasDriver
                                              ? Colors.white
                                              : AppColors.slate600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(bookingFlowProvider.notifier)
                                        .setRentalType(RentalType.withDriver);
                                    if (flowState.driver == null) {
                                      context.push(AppRoutes.driverSelection);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasDriver
                                          ? AppColors.accent
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "With Driver",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: hasDriver
                                              ? Colors.white
                                              : AppColors.slate600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Gap(AppSpacing.md),

                  // 4b. Mode-Specific Requirements / Assigned Driver details
                  if (!hasDriver)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: AppRadius.lgBorderRadius,
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF1D4ED8),
                                size: 18,
                              ),
                              Gap(8),
                              Text(
                                "Self-Drive Requirements",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                          Gap(10),
                          _RequirementRow(
                            icon: Icons.badge_outlined,
                            text:
                                "Valid physical Driving License (LVM/Car) required",
                          ),
                          _RequirementRow(
                            icon: Icons.account_box_outlined,
                            text: "Aadhaar Card or Passport must be verified",
                          ),
                          _RequirementRow(
                            icon: Icons.calendar_today_outlined,
                            text: "Minimum age required is 21 years",
                          ),
                          _RequirementRow(
                            icon: Icons.lock_clock_outlined,
                            text:
                                "Refundable security deposit of ₹150 required",
                          ),
                        ],
                      ),
                    ),

                  if (hasDriver)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.lgBorderRadius,
                        border: Border.all(
                          color: flowState.driver == null
                              ? const Color(0xFFFFEDD5)
                              : AppColors.slate200,
                        ),
                        boxShadow: AppElevation.cardShadow,
                      ),
                      child: flowState.driver == null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFEA580C),
                                      size: 20,
                                    ),
                                    Gap(8),
                                    Expanded(
                                      child: Text(
                                        "Chauffeur Assignment Required",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF7C2D12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(8),
                                const Text(
                                  "A professional driver is required for 'With Driver' mode. Please select one to complete the checkout.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9A3412),
                                  ),
                                ),
                                const Gap(12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        context.push(AppRoutes.driverSelection),
                                    icon: const Icon(
                                      Icons.person_add_alt_1_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      "Select Driver",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEA580C),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Assigned Driver",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.slate900,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.push(
                                        AppRoutes.driverSelection,
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        foregroundColor: AppColors.accent,
                                      ),
                                      child: const Text(
                                        "Change",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(12),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final useVerticalLayout =
                                        constraints.maxWidth < 280;
                                    final dist = _getDriverDistance(flowState);

                                    final photoWidget = Container(
                                      width: 56,
                                      height: 56,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: Image.network(
                                          flowState.driver!.imageUrl,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    color: AppColors.slate100,
                                                    child: const Icon(
                                                      Icons.person,
                                                      color: AppColors.slate400,
                                                      size: 32,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    );

                                    final infoWidget = Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          flowState.driver!.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.slate900,
                                          ),
                                        ),
                                        const Gap(2),
                                        if (flowState.driver!.isVerified)
                                          const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.verified_user_rounded,
                                                color: Color(0xFF16A34A),
                                                size: 13,
                                              ),
                                              Gap(4),
                                              Text(
                                                "Verified Driver",
                                                style: TextStyle(
                                                  color: Color(0xFF16A34A),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        const Gap(4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFFBBF24),
                                              size: 14,
                                            ),
                                            const Gap(2),
                                            Text(
                                              "${flowState.driver!.rating}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const Gap(6),
                                            Text(
                                              "•  ${flowState.driver!.experienceYears} yrs exp",
                                              style: const TextStyle(
                                                color: AppColors.slate500,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (dist != null) ...[
                                          const Gap(4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.pin_drop_outlined,
                                                color: AppColors.slate400,
                                                size: 13,
                                              ),
                                              const Gap(4),
                                              Text(
                                                dist < 0.1
                                                    ? "Available in your area"
                                                    : "${dist.toStringAsFixed(1)} km away",
                                                style: const TextStyle(
                                                  color: AppColors.slate500,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    );

                                    final priceWidget = Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "${formatCurrency(flowState.driver!.pricePerDay)}/day",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                        const Gap(2),
                                        const Text(
                                          "Driver Charge",
                                          style: TextStyle(
                                            color: AppColors.slate400,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    );

                                    if (useVerticalLayout) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              photoWidget,
                                              const Gap(12),
                                              Expanded(child: infoWidget),
                                            ],
                                          ),
                                          const Gap(12),
                                          priceWidget,
                                        ],
                                      );
                                    } else {
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          photoWidget,
                                          const Gap(12),
                                          Expanded(child: infoWidget),
                                          const Gap(8),
                                          priceWidget,
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                    ),

                  const Gap(AppSpacing.md),

                  // 5. Add-ons card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.lgBorderRadius,
                      border: Border.all(color: AppColors.slate200),
                      boxShadow: AppElevation.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.layers_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const Gap(8),
                            Text(
                              "Additional Add-ons",
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.md),

                        // Premium Insurance toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.slate100,
                                  radius: 18,
                                  child: Icon(
                                    Icons.shield_outlined,
                                    color: AppColors.slate600,
                                    size: 16,
                                  ),
                                ),
                                Gap(12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Premium Insurance",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Gap(2),
                                    Text(
                                      "Zero deductible, full coverage",
                                      style: TextStyle(
                                        color: AppColors.slate400,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: hasInsurance,
                              activeThumbColor: AppColors.accent,
                              onChanged: (val) {
                                ref
                                    .read(bookingFlowProvider.notifier)
                                    .toggleService(
                                      const Service(
                                        id: "srv_insurance",
                                        name: "Premium Insurance",
                                        description: "Zero deductible cover",
                                        price: 15.0,
                                        isReoccurring: true,
                                      ),
                                    );
                              },
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.additionalServices),
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                            ),
                            label: const Text("View all optional services"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Gap(AppSpacing.md),

                  // 6. Payment Summary Breakdown
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.lgBorderRadius,
                      border: Border.all(color: AppColors.slate200),
                      boxShadow: AppElevation.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const Gap(8),
                            Text(
                              "Payment Details",
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.md),
                        _FareRow(
                          label:
                              "Rental Price (${formatCurrency(vehicle?.pricePerDay ?? 0.0)} x $days days)",
                          value: baseCharge,
                        ),
                        if (hasDriver && driverFee > 0)
                          _FareRow(
                            label:
                                "Chauffeur Fee (${formatCurrency(flowState.driver?.pricePerDay ?? 0.0)} x $days days)",
                            value: driverFee,
                          ),
                        if (hasInsurance)
                          _FareRow(
                            label: "Premium Insurance",
                            value: insuranceFee,
                          ),
                        if (additionalServicesFee > 0)
                          _FareRow(
                            label: "Additional Add-ons",
                            value: additionalServicesFee,
                          ),
                        if (discount > 0)
                          _FareRow(
                            label: "Coupon Discount",
                            value: -discount,
                            valueColor: AppColors.accent,
                          ),
                        const _FareRow(label: "Platform Fee", value: 15.0),
                        _FareRow(
                          label: "Security Deposit (Refundable)",
                          value: deposit,
                          isRefundable: true,
                        ),
                        _FareRow(label: "GST Tax (18%)", value: tax),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.local_offer_outlined,
                            color: AppColors.cta,
                          ),
                          title: Text(
                            flowState.coupon?.code ?? "Apply coupon",
                            style: AppTextStyles.subtitle2.copyWith(
                              color: AppColors.slate800,
                            ),
                          ),
                          subtitle: Text(
                            flowState.coupon == null
                                ? "Browse available promo codes"
                                : "Promo coupon applied successfully",
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.slate500,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.slate400,
                          ),
                          onTap: () => context.push(AppRoutes.coupon),
                        ),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.xl),
                ],
              ),
            ),
          ),

          // Validation warning banner
          if (dateError != null || isDriverRequiredButMissing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              color: const Color(0xFFFEF2F2),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      dateError ?? "Select an available driver to continue.",
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 7. Sticky Checkout Footer
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: AppColors.slate200.withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              boxShadow: AppElevation.selectShadow,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "GRAND TOTAL",
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.slate400,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Gap(2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            alignment: Alignment.centerLeft,
                            child: child,
                          );
                        },
                        child: Text(
                          formatCurrency(totalAmount),
                          key: ValueKey<double>(totalAmount),
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 22,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: isCheckoutEnabled
                        ? () {
                            context.push(AppRoutes.paymentMethod);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(180, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isCheckoutEnabled ? 2 : 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Pay Now",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Gap(8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RequirementRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1D4ED8)),
          const Gap(8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF1E3A8A),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isRefundable;
  final Color? valueColor;

  const _FareRow({
    required this.label,
    required this.value,
    this.isRefundable = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.slate500,
                  fontSize: 12,
                ),
              ),
              if (isRefundable) ...[
                const Gap(4),
                const Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.slate400,
                  size: 12,
                ),
              ],
            ],
          ),
          Text(
            value < 0
                ? "-${formatCurrency(value.abs())}"
                : formatCurrency(value),
            style: AppTextStyles.subtitle2.copyWith(
              color: valueColor ?? AppColors.slate800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
