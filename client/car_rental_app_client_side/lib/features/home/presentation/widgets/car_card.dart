import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/car_model.dart';
import '../../../wishlist/presentation/controllers/wishlist_controller.dart';

/// Reusable car card used by both Recommended Cars and Popular Cars.
/// Tapping the card fires onCarTap; tapping the button fires onBookNow —
/// kept separate since teammates may route them to different screens
/// (car details vs. booking flow).
class CarCard extends StatelessWidget {
  final CarModel car;
  final VoidCallback? onCarTap;
  final VoidCallback? onBookNow;
  final double width;

  const CarCard({
    super.key,
    required this.car,
    this.onCarTap,
    this.onBookNow,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    final bool available = car.isAvailable;

    return InkWell(
      onTap: available ? onCarTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: available ? 1.0 : 0.6,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Image.network(
                      car.imageUrl,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 110,
                        width: double.infinity,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          size: 40,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                  // Wishlist Heart Button (Top Left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: AnimatedBuilder(
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
                                size: 16,
                                color: isWishlisted
                                    ? Colors.redAccent
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Rating Badge (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.rating,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            car.rating.toString(),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Unavailable banner
                  if (!available)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(0),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          color: Colors.black.withOpacity(0.55),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Not Available',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _SpecChip(
                          icon: Icons.settings,
                          label: car.transmission,
                        ),
                        _SpecChip(
                          icon: Icons.local_gas_station,
                          label: car.fuelType,
                        ),
                        _SpecChip(
                          icon: Icons.event_seat,
                          label: '${car.seats} Seats',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '₹${car.pricePerDay.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(
                                  text: '/day',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: available ? onBookNow : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: available
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              available ? 'Book Now' : 'Unavailable',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
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
        ),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
