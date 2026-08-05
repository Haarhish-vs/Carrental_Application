import 'package:flutter/material.dart';

import 'common/owner_colors.dart';
import 'common/owner_spacing.dart';
import '../../models/car_model.dart';

/// Reusable row representing a single car with its status badge,
/// utilization bar, rating and rental count.
class CarListTile extends StatelessWidget {
  const CarListTile({super.key, required this.car});

  final CarModel car;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OwnerSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: OwnerColors.primaryLight,
              borderRadius: BorderRadius.circular(OwnerRadius.sm),
            ),
            child: const Icon(Icons.directions_car_rounded, color: OwnerColors.primary),
          ),
          const SizedBox(width: OwnerSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        car.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(status: car.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${car.plateNumber} · ${car.totalRentals} rentals · ${car.kilometersDriven} km',
                  style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: car.utilization,
                    minHeight: 6,
                    backgroundColor: OwnerColors.surfaceMuted,
                    valueColor: const AlwaysStoppedAnimation(OwnerColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CarStatus status;

  @override
  Widget build(BuildContext context) {
    late Color fg;
    late Color bg;
    late String label;

    switch (status) {
      case CarStatus.available:
        fg = OwnerColors.success;
        bg = OwnerColors.successBg;
        label = 'Available';
      case CarStatus.rented:
        fg = OwnerColors.info;
        bg = OwnerColors.infoBg;
        label = 'Rented';
      case CarStatus.maintenance:
        fg = OwnerColors.warning;
        bg = OwnerColors.warningBg;
        label = 'Maintenance';
      case CarStatus.inactive:
        fg = OwnerColors.textTertiary;
        bg = OwnerColors.surfaceMuted;
        label = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(OwnerRadius.pill)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
