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
  final double? width;

  const CarCard({
    super.key,
    required this.car,
    this.onCarTap,
    this.onBookNow,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bool available = car.isAvailable;
    final mediaQuery = MediaQuery.sizeOf(context);
    final double screenWidth = mediaQuery.width;
    
    // 1. USE MEDIAPUERY FOR DIMENSIONS: Calculate scale factor from base mobile screen (375 logical px)
    final double scale = (screenWidth / 375.0).clamp(0.8, 1.25);
    
    // Dynamic dimensions based on screen width & scale factor
    final double cardPaddingH = (12.0 * scale).clamp(8.0, 16.0);
    final double cardPaddingV = (10.0 * scale).clamp(8.0, 14.0);
    final double imageHeight = (screenWidth * 0.32).clamp(100.0, 140.0);
    final double borderRadiusVal = 16.0 * scale;

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
          borderRadius: BorderRadius.circular(borderRadiusVal),
          child: Opacity(
            opacity: available ? 1.0 : 0.65,
            child: Container(
              width: width ?? (screenWidth * 0.68).clamp(230.0, 270.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadiusVal),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12 * scale,
                    offset: Offset(0, 4 * scale),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 5. USE BOXFIT CONSTRAINTS FOR IMAGES: Bounded container with BoxFit.cover
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(borderRadiusVal - 1),
                        ),
                        child: SizedBox(
                          height: imageHeight,
                          width: double.infinity,
                          child: Image.network(
                            car.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: imageHeight,
                              width: double.infinity,
                              color: const Color(0xFFF1F5F9),
                              child: Icon(
                                Icons.directions_car_rounded,
                                size: 40 * scale,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Rating Badge (Top Left of Image)
                      Positioned(
                        top: 8 * scale,
                        left: 8 * scale,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7 * scale,
                            vertical: 3.5 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4 * scale,
                                offset: Offset(0, 2 * scale),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 13 * scale,
                                color: const Color(0xFFFFB800),
                              ),
                              SizedBox(width: 2.5 * scale),
                              Text(
                                displayRating,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: 2 * scale),
                              Flexible(
                                child: Text(
                                  '(${reviewCount > 0 ? reviewCount : 24})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10 * scale,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Wishlist Heart Button (Top Right of Image)
                      Positioned(
                        top: 8 * scale,
                        right: 8 * scale,
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
                                  padding: EdgeInsets.all(5.5 * scale),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4 * scale,
                                        offset: Offset(0, 2 * scale),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isWishlisted
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 15 * scale,
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
                            padding: EdgeInsets.symmetric(vertical: 4 * scale),
                            color: Colors.black.withValues(alpha: 0.6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: Colors.white,
                                  size: 11 * scale,
                                ),
                                SizedBox(width: 4 * scale),
                                Flexible(
                                  child: Text(
                                    'Not Available',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5 * scale,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: cardPaddingH,
                      vertical: cardPaddingV,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. ENFORCE HORIZONTAL ROW SAFETY & 3. PREVENT TEXT BREAKOUTS:
                        // Title Row: Car Name on Left (Expanded), Reviews Pill on Right (Flexible)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                car.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            SizedBox(width: 6 * scale),
                            Flexible(
                              child: InkWell(
                                onTap: () => ReviewsBottomSheet.show(context, car.id),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 7 * scale,
                                    vertical: 3.5 * scale,
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
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 11 * scale,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 3 * scale),
                                      Flexible(
                                        child: Text(
                                          reviewsText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10 * scale,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8 * scale),

                        // Specs Row: Transmission, Fuel, Seats (Horizontal Row Safety - Wrapped in Expanded)
                        Row(
                          children: [
                            Expanded(
                              child: _SpecChip(
                                icon: Icons.tune_rounded,
                                label: car.transmission,
                                scale: scale,
                              ),
                            ),
                            SizedBox(width: 4 * scale),
                            Expanded(
                              child: _SpecChip(
                                icon: Icons.local_gas_station_rounded,
                                label: car.fuelType,
                                scale: scale,
                              ),
                            ),
                            SizedBox(width: 4 * scale),
                            Expanded(
                              child: _SpecChip(
                                icon: Icons.person_outline_rounded,
                                label: '${car.seats} Seats',
                                scale: scale,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10 * scale),

                        // Price & Book Now Row (Horizontal Row Safety - Expanded / Flexible with Text Ellipsis)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '₹${car.pricePerDay.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 15 * scale,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' / day',
                                      style: TextStyle(
                                        fontSize: 10 * scale,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4 * scale),
                            Flexible(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: available ? onBookNow : null,
                                  borderRadius: BorderRadius.circular(10 * scale),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 9 * scale,
                                      vertical: 6.5 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: available
                                          ? AppColors.primary
                                          : Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(10 * scale),
                                      boxShadow: available
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 6 * scale,
                                                offset: Offset(0, 2 * scale),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            available ? 'Book Now' : 'Unavailable',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11 * scale,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                        ),
                                        if (available) ...[
                                          SizedBox(width: 2 * scale),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.white,
                                            size: 14 * scale,
                                          ),
                                        ],
                                      ],
                                    ),
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
  final double scale;

  const _SpecChip({
    required this.icon,
    required this.label,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11.5 * scale, color: const Color(0xFF64748B)),
        SizedBox(width: 2.5 * scale),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10 * scale,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}
