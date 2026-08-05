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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Popular Cars',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive column count: phone -> 2, tablet/web -> 3+.
            final crossAxisCount = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 600
                    ? 3
                    : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: cars.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
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