import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/car_model.dart';
import '../../../wishlist/presentation/controllers/wishlist_controller.dart';
import '../../../owner/data/services/car_api_service.dart';
import '../widgets/reviews_bottom_sheet.dart';

/// Reusable car card matching the modern design system.
/// Features:
/// - Floating rating badge and wishlist toggle over car image
/// - Car title with upper reviews pill badge
/// - Clean specs row (Transmission, Fuel, Seats)
/// - Bold price and prominent clean "Book Now >" action button
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
    this.width = 260,
  });

  @override
  Widget build(BuildContext context) {
    final bool available = car.isAvailable;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: CarApiService().getVehicleReviews(car.id),
      builder: (context, snapshot) {
        final reviews = snapshot.data;
        final int reviewCount = reviews != null
            ? reviews.length
            : (car.reviewsCount ?? 0);

        double avgRating = car.rating;
        if (reviews != null && reviews.isNotEmpty) {
          double total = 0;
          for (var r in reviews) {
            total += (r['rating'] as num?)?.toDouble() ?? 0.0;
          }
          avgRating = total / reviews.length;
        }
        final String displayRating = avgRating > 0
            ? avgRating.toStringAsFixed(1)
            : (car.rating > 0 ? car.rating.toStringAsFixed(1) : '4.5');

        final String reviewsText = reviewCount > 0
            ? '$reviewCount Reviews'
            : 'Reviews';

        return InkWell(
          onTap: available ? onCarTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Opacity(
            opacity: available ? 1.0 : 0.65,
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Image Stack with Rating & Wishlist Badges
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(17),
                        ),
                        child: Image.network(
                          car.imageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 130,
                            width: double.infinity,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(
                              Icons.directions_car_rounded,
                              size: 46,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),

                      // Rating Badge (Top Left of Image)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFFFB800),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                displayRating,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '(${reviewCount > 0 ? reviewCount : 24})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Wishlist Heart Button (Top Right of Image)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: AnimatedBuilder(
                          animation: WishlistController.instance,
                          builder: (context, _) {
                            final isWishlisted = WishlistController.instance
                                .isWishlisted(car.id);
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  WishlistController.instance.toggleWishlist(
                                    car.id,
                                    context: context,
                                    carName: car.name,
                                    carModel: car,
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
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
                                        : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Unavailable overlay
                      if (!available)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.black.withValues(alpha: 0.6),
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
                    ],
                  ),

                  // 2. Card Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row: Car Name on Left, Reviews Pill on Right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                car.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => ReviewsBottomSheet.show(context, car.id),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF4FF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFD0E1FD),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 12.5,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      reviewsText,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Specs Row: Transmission, Fuel, Seats
                        Row(
                          children: [
                            _SpecChip(
                              icon: Icons.tune_rounded,
                              label: car.transmission,
                            ),
                            const SizedBox(width: 12),
                            _SpecChip(
                              icon: Icons.local_gas_station_rounded,
                              label: car.fuelType,
                            ),
                            const SizedBox(width: 12),
                            _SpecChip(
                              icon: Icons.person_outline_rounded,
                              label: '${car.seats} Seats',
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Price & Book Now Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '₹${car.pricePerDay.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' / day',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: available ? onBookNow : null,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: available
                                        ? AppColors.primary
                                        : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: available
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        available ? 'Book Now' : 'Unavailable',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      if (available) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white,
                                          size: 17,
                                        ),
                                      ],
                                    ],
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
      },
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
        Icon(icon, size: 13, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
