import 'package:flutter/material.dart';
import 'package:car_rental_app_client_side/core/theme/app_colors.dart';
import 'package:car_rental_app_client_side/core/utils/responsive.dart';
import 'package:car_rental_app_client_side/features/home/models/car_model.dart';
import 'package:car_rental_app_client_side/features/wishlist/presentation/controllers/wishlist_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final scale = context.scale;
    final hasDistance = car.distanceKm != null && car.distanceKm! > 0;
    final distanceText = hasDistance
        ? '${car.distanceKm!.toStringAsFixed(1)} km away'
        : (car.pickupLocation ?? car.city);
    final imageHeight = (context.screenWidth * 0.42).clamp(130.0, 180.0);

    return Container(
      margin: EdgeInsets.only(bottom: context.rSize(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.rSize(20)),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: context.rSize(14),
            offset: Offset(0, context.rSize(4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Car Image & Badges (BoxFit constraints)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(context.rSize(20)),
                ),
                child: SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: car.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: car.imageUrl,
                          fit: BoxFit.cover,
                          memCacheHeight: 450, // Optimize memory for lists
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF8FAFC),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: Center(
                              child: Icon(
                                Icons.directions_car_rounded,
                                size: context.rSize(48),
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF1F5F9),
                          child: Center(
                            child: Icon(
                              Icons.directions_car_rounded,
                              size: context.rSize(48),
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                ),
              ),

              // Car Type Badge (Top Left)
              if (car.carType != null && car.carType!.isNotEmpty)
                Positioned(
                  top: context.rSize(12),
                  left: context.rSize(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.rSize(8),
                      vertical: context.rSize(4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      car.carType!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.rFont(10),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Rating Badge and Wishlist Button (Top Right)
              Positioned(
                top: context.rSize(12),
                right: context.rSize(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rSize(7),
                        vertical: context.rSize(3.5),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: context.rSize(14), color: Colors.amber),
                          SizedBox(width: context.rSize(3)),
                          Text(
                            car.rating.toStringAsFixed(1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.rFont(11),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.rSize(6)),
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
                                carModel: car,
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.all(context.rSize(5)),
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
                                size: context.rSize(17),
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
            padding: EdgeInsets.all(context.rSize(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car Name (Text Breakout Safety)
                Text(
                  car.name,
                  style: TextStyle(
                    fontSize: context.rFont(16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.rSize(8)),

                // Attributes Row: Seats, Transmission, Fuel, Distance
                Wrap(
                  spacing: context.rSize(10),
                  runSpacing: context.rSize(6),
                  children: [
                    _SpecChip(
                      icon: Icons.airline_seat_recline_normal_rounded,
                      text: '${car.seats} Seats',
                      scale: scale,
                    ),
                    _SpecChip(
                      icon: Icons.settings_outlined,
                      text: car.transmission,
                      scale: scale,
                    ),
                    _SpecChip(
                      icon: Icons.local_gas_station_outlined,
                      text: car.fuelType,
                      scale: scale,
                    ),
                    if (distanceText.isNotEmpty)
                      _SpecChip(
                        icon: Icons.near_me_outlined,
                        text: distanceText,
                        scale: scale,
                      ),
                  ],
                ),
                SizedBox(height: context.rSize(12)),
                const Divider(height: 1, color: AppColors.divider),
                SizedBox(height: context.rSize(12)),

                // 3. Price & View Details Action (Horizontal Row Safety - Expanded & Flexible)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '₹${car.pricePerDay.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: context.rFont(18),
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            TextSpan(
                              text: ' / day',
                              style: TextStyle(
                                fontSize: context.rFont(12),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: context.rSize(8)),
                    Flexible(
                      child: ElevatedButton(
                        onPressed: onViewDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: context.rSize(16),
                            vertical: context.rSize(9),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'View Details',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.rFont(12.5),
                            fontWeight: FontWeight.bold,
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
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final double scale;

  const _SpecChip({
    required this.icon,
    required this.text,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13 * scale, color: AppColors.textSecondary),
        SizedBox(width: 3 * scale),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11 * scale,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
