import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/car_model.dart';
import 'car_card.dart';

/// Horizontal recommended-cars rail displaying real database vehicle results.
class RecommendedCars extends StatelessWidget {
  final List<CarModel> cars;
  final ValueChanged<CarModel> onCarTap;
  final ValueChanged<CarModel> onBookNow;
  final VoidCallback? onSeeAllTap;
  final String title;
  final Widget? trailing;

  const RecommendedCars({
    super.key,
    required this.cars,
    required this.onCarTap,
    required this.onBookNow,
    this.onSeeAllTap,
    this.title = 'Recommended Cars',
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final availableCars = cars.where((c) => c.isAvailable).toList();
    if (availableCars.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing ??
                  GestureDetector(
                    onTap: onSeeAllTap,
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: availableCars.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final car = availableCars[index];
              return CarCard(
                car: car,
                onCarTap: () => onCarTap(car),
                onBookNow: () => onBookNow(car),
              );
            },
          ),
        ),
      ],
    );
  }
}
