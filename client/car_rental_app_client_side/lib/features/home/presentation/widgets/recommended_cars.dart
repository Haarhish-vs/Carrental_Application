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

    final mediaQuery = MediaQuery.sizeOf(context);
    final double screenWidth = mediaQuery.width;
    final double scale = (screenWidth / 375.0).clamp(0.8, 1.25);
    final double horizontalPadding = (16.0 * scale).clamp(12.0, 24.0);
    final double spacing = (12.0 * scale).clamp(8.0, 16.0);
    
    // Dynamic horizontal rail height derived from screen dimensions
    final double imageHeight = (screenWidth * 0.32).clamp(100.0, 140.0);
    final double contentHeight = 105.0 * scale;
    final double railHeight = imageHeight + contentHeight + (16.0 * scale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17 * scale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing ??
                  GestureDetector(
                    onTap: onSeeAllTap,
                    child: Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            ],
          ),
        ),
        SizedBox(height: 12 * scale),
        SizedBox(
          height: railHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: availableCars.length,
            separatorBuilder: (context, index) => SizedBox(width: spacing),
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
