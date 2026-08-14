import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Promo banner encouraging car owners to list their vehicle.
/// Callback-only — no navigation baked in.
class BecomeHostBanner extends StatelessWidget {
  final VoidCallback onHostTap;

  const BecomeHostBanner({super.key, required this.onHostTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Own a Car?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Earn passive income by listing your car',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: onHostTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Become a Host',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.directions_car_filled,
            color: Colors.white24,
            size: 70,
          ),
        ],
      ),
    );
  }
}
