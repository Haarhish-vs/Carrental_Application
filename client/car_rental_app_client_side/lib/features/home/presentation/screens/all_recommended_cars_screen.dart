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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Top Rated Cars',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: cars.isEmpty
          ? const Center(
              child: Text(
                'No cars available.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                return CarCard(
                  car: car,
                  onCarTap: () => _openCarDetail(context, car),
                  onBookNow: () => _handleBookNow(context, car),
                );
              },
            ),
    );
  }
}
