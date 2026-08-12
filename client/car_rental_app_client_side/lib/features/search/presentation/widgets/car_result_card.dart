import 'package:flutter/material.dart';
import 'package:car_rental_app_client_side/core/theme/app_colors.dart';
import 'package:car_rental_app_client_side/features/home/models/car_model.dart';
import 'package:car_rental_app_client_side/features/wishlist/presentation/controllers/wishlist_controller.dart';

class CarResultCard extends StatelessWidget {
  final CarModel car;
  final VoidCallback onViewDetails;

  const CarResultCard({
    super.key,
    required this.car,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final hasDistance = car.distanceKm != null && car.distanceKm! > 0;
    final distanceText = hasDistance
        ? '${car.distanceKm!.toStringAsFixed(1)} km away'
        : (car.pickupLocation ?? car.city);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Car Image & Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: car.imageUrl.isNotEmpty
                      ? Image.network(
                          car.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(
                                Icons.directions_car_rounded,
                                size: 56,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFFF8FAFC),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: Icon(
                              Icons.directions_car_rounded,
                              size: 56,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                ),
              ),

              // Car Type Badge (Top Left)
              if (car.carType != null && car.carType!.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      car.carType!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Rating Badge and Wishlist Button (Top Right)
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            car.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: WishlistController.instance,
                      builder: (context, _) {
                        final isWishlisted = WishlistController.instance.isWishlisted(car.id);
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              WishlistController.instance.toggleWishlist(
                                car.id,
                                context: context,
                                carName: car.name,
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isWishlisted
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                                color: isWishlisted
                                    ? Colors.redAccent
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 2. Info details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car Name
                Text(
                  car.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Attributes Row: Seats, Transmission, Fuel, Distance
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _SpecChip(
                      icon: Icons.airline_seat_recline_normal_rounded,
                      text: '${car.seats} Seats',
                    ),
                    _SpecChip(
                      icon: Icons.settings_outlined,
                      text: car.transmission,
                    ),
                    _SpecChip(
                      icon: Icons.local_gas_station_outlined,
                      text: car.fuelType,
                    ),
                    if (distanceText.isNotEmpty)
                      _SpecChip(
                        icon: Icons.near_me_outlined,
                        text: distanceText,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 14),

                // 3. Price & View Details Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${car.pricePerDay.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text(
                              ' / day',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: onViewDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
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

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SpecChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
