import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/car_model.dart';
import 'car_card.dart';

/// Horizontal recommended-cars rail. Swap `cars: DummyData.recommendedCars`
/// for `cars: apiResponse.cars` later — nothing else in this widget changes.
class RecommendedCars extends StatelessWidget {
  final List<CarModel> cars;
  final ValueChanged<CarModel> onCarTap;
  final ValueChanged<CarModel> onBookNow;

  const RecommendedCars({
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recommended Cars',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const Text('See all',
                  style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: cars.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final car = cars[index];
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