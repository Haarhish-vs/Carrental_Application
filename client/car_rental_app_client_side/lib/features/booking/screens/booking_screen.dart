import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

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

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  String _selectedCategory = "SUV";
  final List<String> _categories = ["SUV", "Sedan", "Luxury", "Electric", "Sport"];

  final List<Vehicle> _cars = const [
    Vehicle(
      id: "veh_tesla_y",
      name: "Tesla Model Y",
      imageUrl: "https://images.unsplash.com/photo-1617788138017-80ad40651399?auto=format&fit=crop&q=80&w=800",
      pricePerDay: 120.0,
      specifications: ["EV", "5 Seats", "Auto", "AC", "GPS"],
      rating: 4.9,
    ),
    Vehicle(
      id: "veh_bmw_x5",
      name: "BMW X5 2023",
      imageUrl: "https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&q=80&w=800",
      pricePerDay: 135.0,
      specifications: ["Petrol", "Automatic", "5 Seats", "Climate Control", "GPS"],
      rating: 4.8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showProgress: false,
      body: Column(
        children: [
          // 1. Header bar: Location, Notifications, Profile
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                    const Gap(6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Location",
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate400, fontSize: 10),
                        ),
                        Row(
                          children: [
                            Text(
                              "New York, NY",
                              style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.slate600),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.slate700),
                    ),
                    const CircleAvatar(
                      backgroundImage: NetworkImage(AppImages.profilePlaceholder),
                      radius: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Search Input bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search cars, brands, or mode...",
                prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
                suffixIcon: const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.tune_rounded, color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.slate100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          const Gap(AppSpacing.md),

          // 3. Category Horizontal Row List
          SizedBox(
            height: 38,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.slate500,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.slate100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                );
              },
            ),
          ),

          const Gap(AppSpacing.lg),

          // 4. Featured Cars List Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Featured Cars",
                  style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text("See All", style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              physics: const BouncingScrollPhysics(),
              itemCount: _cars.length,
              itemBuilder: (context, index) {
                final car = _cars[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _DashboardCarCard(
                    vehicle: car,
                    onBookNow: () {
                      ref.read(bookingFlowProvider.notifier).setVehicle(car);
                      context.push('/booking/car-details');
                    },
                  ),
                );
              },
            ),
          ),

          // 5. Customer Dashboard Bottom Navigation Bar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.slate200, width: 1)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavBtn(icon: Icons.home, label: "Home", isActive: true),
                    _NavBtn(icon: Icons.calendar_month, label: "Bookings", isActive: false),
                    _NavBtn(icon: Icons.wallet_giftcard_rounded, label: "Wallet", isActive: false),
                    _NavBtn(icon: Icons.person, label: "Profile", isActive: false),
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

class _DashboardCarCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onBookNow;

  const _DashboardCarCard({
    required this.vehicle,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(color: AppColors.slate200),
        boxShadow: AppElevation.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Image and rating tag
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  vehicle.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFBBF24), size: 14),
                      const Gap(4),
                      Text(
                        "${vehicle.rating}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Gap(8),

                // Specs list badges
                Row(
                  children: vehicle.specifications.take(3).map((spec) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          spec,
                          style: TextStyle(
                            color: AppColors.slate500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const Gap(AppSpacing.md),

                // Pricing and CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Price",
                          style: TextStyle(color: AppColors.slate400, fontSize: 10),
                        ),
                        const Gap(2),
                        Text.rich(
                          TextSpan(
                            text: "\$${vehicle.pricePerDay.toStringAsFixed(0)}",
                            style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                            children: [
                              TextSpan(
                                text: "/day",
                                style: TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: onBookNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text(
                        "Book Now",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.slate400,
          size: 22,
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.slate500,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
