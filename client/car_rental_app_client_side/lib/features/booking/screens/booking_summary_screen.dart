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
import '../providers/booking_provider.dart';
import '../utils/booking_price_calculator.dart';
import '../widgets/bottom_sheets/location_search_sheet.dart';

class BookingSummaryScreen extends ConsumerStatefulWidget {
  const BookingSummaryScreen({super.key});

  @override
  ConsumerState<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
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
    if (dateTime == null) return '';
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  void _showDatePickerSheet(bool isPickup) async {
    final flow = ref.read(bookingFlowProvider);
    final initialDate = isPickup
        ? (flow.pickupDateTime ?? DateTime.now())
        : (flow.returnDateTime ?? DateTime.now().add(const Duration(days: 3)));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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
        ref.read(bookingFlowProvider.notifier).setDateTimes(
          pickup: selectedDateTime,
          returnDT: flow.returnDateTime,
        );
      } else {
        ref.read(bookingFlowProvider.notifier).setDateTimes(
          pickup: flow.pickupDateTime,
          returnDT: selectedDateTime,
        );
      }
    }
  }

  void _showLocationSheet() async {
    final selectedLoc = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const LocationSearchSheet(title: "Select Hub Location"),
    );
    if (selectedLoc != null && mounted) {
      ref.read(bookingFlowProvider.notifier).setLocations(
        pickup: selectedLoc,
        returnLoc: ref.read(bookingFlowProvider).returnLocation ?? selectedLoc,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final vehicle = flowState.vehicle;

    final baseCharge = BookingPriceCalculator.calculateBaseRentalCharge(flowState);
    final driverFee = BookingPriceCalculator.calculateDriverFee(flowState);
    final insuranceFee = BookingPriceCalculator.calculateInsurance(flowState);
    final additionalServicesFee = BookingPriceCalculator.calculateAdditionalServices(flowState);
    final discount = BookingPriceCalculator.calculateDiscount(flowState);
    final tax = BookingPriceCalculator.calculateTax(flowState);
    final deposit = BookingPriceCalculator.calculateSecurityDeposit(flowState);
    final totalAmount = BookingPriceCalculator.calculateGrandTotal(flowState);

    final days = flowState.pickupDateTime != null && flowState.returnDateTime != null
        ? flowState.returnDateTime!.difference(flowState.pickupDateTime!).inDays
        : 3;

    final hasDriver = flowState.rentalType == RentalType.withDriver;
    final hasInsurance = flowState.selectedServices.any((s) => s.id == "srv_insurance");

    return AppScaffold(
      title: "Complete Booking",
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Vehicle Card
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
                                    fontSize: 16,
                                  ),
                                ),
                                const Gap(4),
                                Text(
                                  "Electric - Automatic",
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate500),
                                ),
                                const Gap(4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
                                    const Gap(2),
                                    Text(
                                      "${vehicle.rating}",
                                      style: TextStyle(
                                        color: AppColors.slate800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Gap(4),
                                    Text(
                                      "(128 trips)",
                                      style: TextStyle(color: AppColors.slate400, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Gap(AppSpacing.md),

                  // 2. Date & Time Selection
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
                            const Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 20),
                            const Gap(8),
                            Text(
                              "Date & Time",
                              style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.md),
                        Row(
                          children: [
                            // Timeline visual line
                            Column(
                              children: [
                                const Icon(Icons.circle, color: AppColors.accent, size: 10),
                                Container(width: 2, height: 35, color: AppColors.slate200),
                                const Icon(Icons.circle, color: AppColors.primary, size: 10),
                              ],
                            ),
                            const Gap(16),
                            Expanded(
                              child: Column(
                                children: [
                                  _DateTimeRow(
                                    label: "PICKUP",
                                    value: _formatDateTime(flowState.pickupDateTime),
                                    onEdit: () => _showDatePickerSheet(true),
                                  ),
                                  const Gap(10),
                                  _DateTimeRow(
                                    label: "RETURN",
                                    value: _formatDateTime(flowState.returnDateTime),
                                    onEdit: () => _showDatePickerSheet(false),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Gap(AppSpacing.md),

                  // 3. Location selection with Map Preview
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
                            const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                            const Gap(8),
                            Text(
                              "Location",
                              style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.md),

                        // Map Stylized Preview Card
                        GestureDetector(
                          onTap: _showLocationSheet,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                // Styled map abstract background
                                Image.network(
                                  "https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=800",
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                // Tint overlay
                                Container(
                                  height: 110,
                                  color: Colors.black.withOpacity(0.05),
                                ),
                                // Location Address Pin details
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: AppElevation.selectShadow,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.my_location_rounded, color: AppColors.accent, size: 16),
                                        const Gap(8),
                                        Expanded(
                                          child: Text(
                                            flowState.pickupLocation ?? "SFO International Airport",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.slate800,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Gap(AppSpacing.md),

                  // 4. Add-ons card
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
                            const Icon(Icons.layers_outlined, color: AppColors.primary, size: 20),
                            const Gap(8),
                            Text(
                              "Add-ons",
                              style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.md),

                        // Driver addon toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.slate100,
                                  radius: 18,
                                  child: Icon(Icons.people_alt_outlined, color: AppColors.slate600, size: 16),
                                ),
                                Gap(12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Driver Required", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Gap(2),
                                    Text(r"+₹50/day", style: TextStyle(color: AppColors.slate400, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: hasDriver,
                              activeColor: AppColors.accent,
                              onChanged: (val) {
                                ref.read(bookingFlowProvider.notifier).setRentalType(
                                      val ? RentalType.withDriver : RentalType.selfDrive,
                                    );
                                if (val) {
                                  context.push(AppRoutes.driverSelection);
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Premium Insurance toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.slate100,
                                  radius: 18,
                                  child: Icon(Icons.shield_outlined, color: AppColors.slate600, size: 16),
                                ),
                                Gap(12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Premium Insurance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Gap(2),
                                    Text("Zero deductible, full coverage", style: TextStyle(color: AppColors.slate400, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: hasInsurance,
                              activeColor: AppColors.accent,
                              onChanged: (val) {
                                if (val) {
                                  ref.read(bookingFlowProvider.notifier).toggleService(
                                        Service(
                                          id: "srv_insurance",
                                          name: "Premium Insurance",
                                          description: "Zero deductible cover",
                                          price: 15.0,
                                          isReoccurring: true,
                                        ),
                                      );
                                } else {
                                  ref.read(bookingFlowProvider.notifier).toggleService(
                                        Service(
                                          id: "srv_insurance",
                                          name: "Premium Insurance",
                                          description: "Zero deductible cover",
                                          price: 15.0,
                                          isReoccurring: true,
                                        ),
                                      );
                                }
                              },
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => context.push(AppRoutes.additionalServices),
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                            label: const Text("View all add-ons"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Gap(AppSpacing.md),

                  // 5. Payment Summary Breakdown
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
                            const Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
                            const Gap(8),
                            Text(
                              "Payment Summary",
                              style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.md),
                        _FareRow(label: "Rental Price (₹120 x $days days)", value: baseCharge),
                        if (hasDriver)
                          _FareRow(label: "Driver Fee (₹50 x $days days)", value: driverFee),
                        if (hasInsurance)
                          _FareRow(label: "Premium Insurance", value: insuranceFee),
                        if (additionalServicesFee > 0)
                          _FareRow(label: "Additional Services", value: additionalServicesFee),
                        if (discount > 0)
                          _FareRow(label: "Discount", value: -discount, valueColor: AppColors.accent),
                        const _FareRow(label: "Platform Fee", value: 15.0),
                        _FareRow(label: "Security Deposit", value: deposit, isRefundable: true),
                        _FareRow(label: "GST (18%)", value: tax),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.local_offer_outlined, color: AppColors.cta),
                          title: Text(
                            flowState.coupon?.code ?? "Apply coupon",
                            style: AppTextStyles.subtitle2.copyWith(color: AppColors.slate800),
                          ),
                          subtitle: Text(
                            flowState.coupon == null
                                ? "Browse available promo codes"
                                : "Coupon applied successfully",
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate500),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
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

          // 6. Floating Checkout Footer
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.slate200, width: 1)),
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
                      Text(
                        "TOTAL",
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.slate400,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        "₹${totalAmount.toStringAsFixed(2)}",
                        style: AppTextStyles.h2.copyWith(fontSize: 22, color: AppColors.primary),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to payment selection options
                      context.push(AppRoutes.paymentMethod);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(180, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Pay Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Gap(8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
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

class _DateTimeRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _DateTimeRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 9, color: AppColors.slate400, fontWeight: FontWeight.bold),
              ),
              const Gap(4),
              Text(
                value,
                style: AppTextStyles.subtitle2.copyWith(color: AppColors.slate800, fontSize: 13),
              ),
            ],
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.slate500, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate500, fontSize: 12),
              ),
              if (isRefundable) ...[
                const Gap(4),
                const Icon(Icons.help_outline_rounded, color: AppColors.slate400, size: 12),
              ],
            ],
          ),
          Text(
            value < 0 ? "-₹${value.abs().toStringAsFixed(2)}" : "₹${value.toStringAsFixed(2)}",
            style: AppTextStyles.subtitle2.copyWith(color: valueColor ?? AppColors.slate800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
