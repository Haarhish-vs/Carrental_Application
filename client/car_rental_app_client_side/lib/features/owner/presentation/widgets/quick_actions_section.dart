import 'package:flutter/material.dart';

import 'common/owner_colors.dart';
import 'common/owner_layout.dart';
import 'common/owner_section_header.dart';
import 'common/owner_spacing.dart';

/// SECTION 11 — Quick Actions (large tappable buttons).
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    const actions = <(IconData, String, Color)>[
      (Icons.add_rounded, 'Add Car', OwnerColors.primary),
      (Icons.directions_car_rounded, 'Manage Cars', OwnerColors.info),
      (Icons.check_circle_rounded, 'Approve Bookings', OwnerColors.success),
      (Icons.people_rounded, 'Manage Drivers', OwnerColors.warning),
      (Icons.account_balance_wallet_rounded, 'View Earnings', OwnerColors.success),
      (Icons.file_download_rounded, 'Export Report', OwnerColors.primary),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerSectionHeader(title: 'Quick Actions', icon: Icons.bolt_rounded),
        OwnerResponsiveGrid(
          maxColumns: 3,
          children: [
            for (final (icon, label, color) in actions) _QuickActionButton(icon: icon, label: label, color: color),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OwnerColors.surface,
      borderRadius: BorderRadius.circular(OwnerRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(OwnerRadius.md),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: OwnerSpacing.lg, horizontal: OwnerSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: OwnerColors.border),
            borderRadius: BorderRadius.circular(OwnerRadius.md),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(OwnerRadius.sm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: OwnerSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
