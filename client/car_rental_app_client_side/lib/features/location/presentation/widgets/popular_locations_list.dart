// lib/features/location/presentation/widgets/popular_locations_list.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/location_model.dart';
import 'location_tile.dart';

class PopularLocationsList extends StatelessWidget {
  final List<LocationModel> locations;
  final ValueChanged<LocationModel> onLocationTap;

  const PopularLocationsList({
    super.key,
    required this.locations,
    required this.onLocationTap,
  });

  /// Derives a display icon from the location's name since the backend
  /// model carries no explicit "type" field. Falls back to a generic
  /// pin icon when nothing matches.
  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('airport')) return Icons.flight_takeoff_rounded;
    if (lower.contains('railway') || lower.contains('station')) return Icons.train_rounded;
    if (lower.contains('bus')) return Icons.directions_bus_rounded;
    if (lower.contains('mall')) return Icons.local_mall_outlined;
    if (lower.contains('city') || lower.contains('center') || lower.contains('centre')) {
      return Icons.location_city_rounded;
    }
    return Icons.place_outlined;
  }

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Locations',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
              icon: _iconFor(location.name),
              onTap: () => onLocationTap(location),
            );
          },
        ),
      ],
    );
  }
}