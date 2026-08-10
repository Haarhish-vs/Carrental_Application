// lib/features/location/presentation/widgets/recent_locations_list.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/location_model.dart';
import 'location_tile.dart';

class RecentLocationsList extends StatelessWidget {
  final List<LocationModel> locations;
  final ValueChanged<LocationModel> onLocationTap;
  final VoidCallback? onSeeAllTap;

  const RecentLocationsList({
    super.key,
    required this.locations,
    required this.onLocationTap,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Locations',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (onSeeAllTap != null)
              InkWell(
                onTap: onSeeAllTap,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: locations.length,
          itemBuilder: (context, index) {
            final location = locations[index];
            return LocationTile(
              location: location,
              icon: Icons.history_rounded,
              onTap: () => onLocationTap(location),
            );
          },
        ),
      ],
    );
  }
}
