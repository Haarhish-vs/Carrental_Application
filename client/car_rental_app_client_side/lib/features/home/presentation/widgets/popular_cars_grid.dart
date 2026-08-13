import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/car_model.dart';
import 'car_card.dart';

/// Popular-cars grid. Same replace-the-list-later pattern as RecommendedCars.
class PopularCarsGrid extends StatelessWidget {
  final List<CarModel> cars;
  final ValueChanged<CarModel> onCarTap;
  final ValueChanged<CarModel> onBookNow;

  const PopularCarsGrid({
    super.key,
    required this.cars,
    required this.onCarTap,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    if (cars.isEmpty) return const SizedBox.shrink();

    final mediaQuery = MediaQuery.sizeOf(context);
    final double screenWidth = mediaQuery.width;
    final double scale = (screenWidth / 375.0).clamp(0.8, 1.25);
    final double gridPadding = (16.0 * scale).clamp(12.0, 24.0);
    final double spacing = (12.0 * scale).clamp(8.0, 16.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gridPadding),
          child: Text(
            'Popular Cars',
            style: TextStyle(
              fontSize: 17 * scale,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 12 * scale),
        LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            final int crossAxisCount = availableWidth >= 900
                ? 4
                : availableWidth >= 600
                    ? 3
                    : 2;

            // 4. CALCULATION OF GRID ASPECT RATIOS: Dynamically compute childAspectRatio from width
            final double totalHorizontalSpacing = (gridPadding * 2) + (spacing * (crossAxisCount - 1));
            final double cardWidth = (availableWidth - totalHorizontalSpacing) / crossAxisCount;
            final double imageHeight = (availableWidth * 0.32).clamp(100.0, 140.0);
            final double cardContentHeight = 105.0 * scale;
            final double estimatedCardHeight = imageHeight + cardContentHeight;
            final double dynamicAspectRatio = (cardWidth / estimatedCardHeight).clamp(0.46, 0.72);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: gridPadding),
              itemCount: cars.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: dynamicAspectRatio,
              ),
              itemBuilder: (context, index) {
                final car = cars[index];
                return CarCard(
                  car: car,
                  width: double.infinity,
                  onCarTap: () => onCarTap(car),
                  onBookNow: () => onBookNow(car),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
