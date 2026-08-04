import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/design_system/radius.dart';
import '../../../../core/design_system/elevation.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../models/booking_step.dart';
import '../models/booking_flow_state.dart';
import '../models/vehicle_model.dart';
import '../providers/booking_provider.dart';

class CarDetailsScreen extends ConsumerStatefulWidget {
  const CarDetailsScreen({super.key});

  @override
  ConsumerState<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends ConsumerState<CarDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(bookingFlowProvider);
    final vehicle = flowState.vehicle ?? const Vehicle(
      id: "veh_bmw_x5",
      name: "BMW X5 2023",
      imageUrl: "https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&q=80&w=800",
      pricePerDay: 120.0,
      specifications: ["Petrol", "Automatic", "5 Seats", "Climate Control", "Built-in GPS"],
      rating: 4.9,
    );

    return AppScaffold(
      showProgress: false,
      body: Stack(
        children: [
          // Scrollable details contents
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Cover Image with header details
                  Stack(
                    children: [
                      Image.network(
                        vehicle.imageUrl,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 280,
                          width: double.infinity,
                          color: AppColors.slate100,
                          child: const Icon(Icons.directions_car, size: 70, color: AppColors.slate400),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 280,
                            width: double.infinity,
                            color: AppColors.slate100,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                      // Carousel dots overlay
                      Positioned(
                        bottom: AppSpacing.md,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                            const Gap(4),
                            Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
                            const Gap(4),
                            Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
                          ],
                        ),
                      ),
                      // 360 View overlay button
                      Positioned(
                        bottom: AppSpacing.md,
                        left: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.threed_rotation_rounded, size: 14, color: AppColors.primary),
                              Gap(6),
                              Text(
                                "360° View",
                                style: TextStyle(
                                  fontSize: 11,
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
                  
                  // 2. Title & Rating details
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.name,
                          style: AppTextStyles.h2.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                        const Gap(6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                            const Gap(4),
                            Text(
                              "${vehicle.rating}",
                              style: AppTextStyles.subtitle2.copyWith(fontSize: 14),
                            ),
                            const Gap(8),
                            Text(
                              "•  120 reviews",
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate400),
                            ),
                          ],
                        ),
                        const Gap(AppSpacing.lg),

                        // Host Section
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.slate50,
                            borderRadius: AppRadius.mdBorderRadius,
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundImage: NetworkImage(AppImages.profilePlaceholder),
                                radius: 20,
                              ),
                              const Gap(AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Hosted by Michael",
                                      style: AppTextStyles.subtitle2.copyWith(color: AppColors.slate900),
                                    ),
                                    const Gap(2),
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 12),
                                        const Gap(4),
                                        Text(
                                          "Verified Owner",
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(AppSpacing.lg),

                        // 3. Specifications Grid
                        Text(
                          "Specifications",
                          style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Gap(AppSpacing.md),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          children: const [
                            _SpecCard(label: "Fuel Type", value: "Petrol", icon: Icons.local_gas_station_outlined),
                            _SpecCard(label: "Transmission", value: "Automatic", icon: Icons.settings_input_component_outlined),
                            _SpecCard(label: "Seats", value: "5 Seats", icon: Icons.airline_seat_recline_normal_rounded),
                            _SpecCard(label: "AC", value: "Climate Control", icon: Icons.ac_unit_rounded),
                          ],
                        ),
                        const Gap(AppSpacing.md),
                        const _SpecCard(
                          label: "Navigation",
                          value: "Built-in GPS",
                          icon: Icons.map_outlined,
                          isFullWidth: true,
                        ),
                        const Gap(AppSpacing.lg),

                        // 4. Included Amenities
                        Text(
                          "Included in your booking",
                          style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Gap(AppSpacing.md),
                        const _AmenityRow(icon: Icons.speed_rounded, text: "Unlimited KM"),
                        const Gap(AppSpacing.sm),
                        const _AmenityRow(icon: Icons.health_and_safety_outlined, text: "24/7 Roadside Assistance"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Header action icons floating overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderIconBtn(
                  icon: Icons.arrow_back,
                  onPressed: () => context.pop(),
                ),
                Row(
                  children: [
                    _HeaderIconBtn(
                      icon: Icons.favorite_border_rounded,
                      onPressed: () {},
                    ),
                    const Gap(10),
                    _HeaderIconBtn(
                      icon: Icons.share_outlined,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 5. Sticky Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.slate200, width: 1)),
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
                          "TOTAL PRICE",
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.slate400,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Gap(2),
                        Text.rich(
                          TextSpan(
                            text: "\$${vehicle.pricePerDay.toStringAsFixed(0)}",
                            style: AppTextStyles.h2.copyWith(fontSize: 22, color: AppColors.primary),
                            children: [
                              TextSpan(
                                text: " / day",
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate500, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to Complete Booking checkout screen
                        context.push(AppRoutes.bookingSummary);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(180, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        "Book Now",
                        style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isFullWidth;

  const _SpecCard({
    required this.label,
    required this.value,
    required this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdBorderRadius,
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.slate500, size: 22),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: AppColors.slate400, fontWeight: FontWeight.bold),
                ),
                const Gap(2),
                Text(
                  value,
                  style: AppTextStyles.subtitle2.copyWith(color: AppColors.slate800, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AmenityRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.accent, size: 16),
        ),
        const Gap(12),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate600, fontSize: 13),
        ),
      ],
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderIconBtn({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: AppElevation.cardShadow,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.slate900, size: 20),
      ),
    );
  }
}
