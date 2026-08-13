import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/car_model.dart';
import '../widgets/car_card.dart';
import 'car_detail_screen.dart';
import '../../../auth/services/auth_service.dart';

class AllRecommendedCarsScreen extends StatelessWidget {
  final List<CarModel> cars;
  final DateTime? initialPickupDate;
  final DateTime? initialReturnDate;

  const AllRecommendedCarsScreen({
    super.key,
    required this.cars,
    this.initialPickupDate,
    this.initialReturnDate,
  });

  void _openCarDetail(BuildContext context, CarModel car) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CarDetailScreen(
          car: car,
          initialPickupDate: initialPickupDate,
          initialReturnDate: initialReturnDate,
        ),
      ),
    );
  }

  void _handleBookNow(BuildContext context, CarModel car) {
    if (AuthService.isAuthenticated &&
        AuthService.currentUser != null &&
        AuthService.currentUser!['id'] == car.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot book your own vehicle'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    _openCarDetail(context, car);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.sizeOf(context);
    final double screenWidth = mediaQuery.width;
    
    // 1. USE MEDIAPUERY FOR DIMENSIONS: Scale factor derived from base mobile width (375 logical pixels)
    final double scale = (screenWidth / 375.0).clamp(0.8, 1.25);
    final double gridPadding = (16.0 * scale).clamp(12.0, 24.0);
    final double spacing = (12.0 * scale).clamp(8.0, 16.0);

    // Responsive columns based on device width
    final int crossAxisCount = screenWidth >= 900
        ? 4
        : (screenWidth >= 600 ? 3 : 2);

    // 4. CALCULATION OF GRID ASPECT RATIOS: Dynamically compute aspect ratio from MediaQuery screen width
    final double totalHorizontalSpacing = (gridPadding * 2) + (spacing * (crossAxisCount - 1));
    final double cardWidth = (screenWidth - totalHorizontalSpacing) / crossAxisCount;
    final double imageHeight = (screenWidth * 0.32).clamp(100.0, 140.0);
    // Estimated content height: padding + title row + spec chips + price row + gaps
    final double cardContentHeight = 105.0 * scale;
    final double estimatedCardHeight = imageHeight + cardContentHeight;
    final double dynamicAspectRatio = (cardWidth / estimatedCardHeight).clamp(0.46, 0.72);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Top Rated Cars',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18 * scale,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: cars.isEmpty
          ? Center(
              child: Text(
                'No cars available.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14 * scale,
                ),
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(gridPadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: dynamicAspectRatio,
              ),
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                return CarCard(
                  car: car,
                  width: double.infinity,
                  onCarTap: () => _openCarDetail(context, car),
                  onBookNow: () => _handleBookNow(context, car),
                );
              },
            ),
    );
  }
}
