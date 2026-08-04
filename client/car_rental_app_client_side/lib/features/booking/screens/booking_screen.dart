import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/layout/app_scaffold.dart';
import '../models/vehicle_model.dart';
import '../providers/booking_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  String _selectedCategory = "SUV";

  final List<_VehicleCategory> _categories = const [
    _VehicleCategory("SUV", Icons.directions_car_filled_outlined),
    _VehicleCategory("Sedan", Icons.airport_shuttle_outlined),
    _VehicleCategory("Luxury", Icons.star_border_rounded),
    _VehicleCategory("Electric", Icons.electric_car_outlined),
    _VehicleCategory("Sport", Icons.speed_rounded),
  ];

  final List<Vehicle> _cars = const [
    Vehicle(
      id: "veh_tesla_y",
      name: "Tesla Model Y",
      imageUrl:
          "https://images.unsplash.com/photo-1619767886558-efdc259cde1a?auto=format&fit=crop&q=80&w=900",
      pricePerDay: 120.0,
      specifications: ["EV", "5 Seats", "Auto"],
      rating: 4.9,
    ),
    Vehicle(
      id: "veh_bmw_x5",
      name: "BMW X5 2023",
      imageUrl:
          "https://images.unsplash.com/photo-1556189250-72ba954cfc2b?auto=format&fit=crop&q=80&w=900",
      pricePerDay: 135.0,
      specifications: ["Petrol", "5 Seats", "Auto"],
      rating: 4.8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showProgress: false,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _DashboardHeader()),
                SliverToBoxAdapter(child: _SearchBar()),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 76,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return _CategoryTile(
                          category: category,
                          isSelected: _selectedCategory == category.label,
                          onTap: () => setState(() => _selectedCategory = category.label),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Featured Cars",
                          style: AppTextStyles.subtitle1.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            "See All",
                            style: TextStyle(fontSize: 11, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index.isOdd) return const Gap(16);
                        final car = _cars[index ~/ 2];
                        return _DashboardCarCard(
                          vehicle: car,
                          onBookNow: () {
                            ref.read(bookingFlowProvider.notifier).setVehicle(car);
                            context.push('/booking/car-details');
                          },
                        );
                      },
                      childCount: (_cars.length * 2) - 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _DashboardBottomNav(),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFF2563EB), size: 18),
            const Gap(6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Location",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.slate400,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "New York, NY",
                    style: AppTextStyles.subtitle2.copyWith(
                      color: AppColors.slate900,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.notifications_none_rounded, size: 19),
            ),
            const CircleAvatar(
              backgroundImage: NetworkImage(AppImages.profilePlaceholder),
              radius: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search cars, brands, or model",
          hintStyle: const TextStyle(fontSize: 11, color: AppColors.slate400),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.slate400),
          suffixIcon: Container(
            width: 34,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 17),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _VehicleCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFDBEAFE) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.slate900.withOpacity(0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                category.icon,
                color: isSelected ? const Color(0xFF2563EB) : AppColors.slate500,
                size: 20,
              ),
            ),
            const Gap(7),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? AppColors.slate900 : AppColors.slate500,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  vehicle.imageUrl,
                  height: 158,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 158,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
                      ),
                    ),
                    child: const Icon(Icons.directions_car_rounded, size: 64, color: AppColors.slate400),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: _RatingPill(rating: vehicle.rating),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  style: AppTextStyles.subtitle1.copyWith(
                    fontSize: 15,
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: vehicle.specifications
                      .map((spec) => _SpecPill(label: spec))
                      .toList(),
                ),
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Price",
                            style: TextStyle(fontSize: 9, color: AppColors.slate400, fontWeight: FontWeight.w700),
                          ),
                          const Gap(2),
                          Text.rich(
                            TextSpan(
                              text: "\$${vehicle.pricePerDay.toStringAsFixed(0)}",
                              style: AppTextStyles.subtitle1.copyWith(
                                color: const Color(0xFF2563EB),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                              children: const [
                                TextSpan(
                                  text: "/day",
                                  style: TextStyle(color: AppColors.slate500, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 34,
                      child: ElevatedButton(
                        onPressed: onBookNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          minimumSize: const Size(88, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Book Now",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                        ),
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

class _RatingPill extends StatelessWidget {
  final double rating;

  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
          const Gap(3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate900),
          ),
        ],
      ),
    );
  }
}

class _SpecPill extends StatelessWidget {
  final String label;

  const _SpecPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, color: AppColors.slate500, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DashboardBottomNav extends StatelessWidget {
  const _DashboardBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.slate200.withOpacity(0.8))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 9, 18, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _NavBtn(icon: Icons.home_rounded, label: "Home", isActive: true),
              _NavBtn(icon: Icons.calendar_month_rounded, label: "Bookings", isActive: false),
              _NavBtn(icon: Icons.account_balance_wallet_rounded, label: "Wallet", isActive: false),
              _NavBtn(icon: Icons.person_rounded, label: "Profile", isActive: false),
            ],
          ),
        ),
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
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF2563EB) : AppColors.slate400,
            size: 20,
          ),
          const Gap(3),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF2563EB) : AppColors.slate500,
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCategory {
  final String label;
  final IconData icon;

  const _VehicleCategory(this.label, this.icon);
}
