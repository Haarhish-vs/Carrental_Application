import 'package:flutter/material.dart';

import 'common/owner_colors.dart';
import 'common/owner_spacing.dart';
import '../../models/owner_dummy_data.dart';

/// "Welcome back, {name}" hero card with a short subtitle and three
/// primary quick-action buttons (Add New Car / View Bookings / Manage Cars).
class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final firstName = OwnerDummyData.ownerName.split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OwnerSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff1E293B),
            Color(0xff0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(OwnerRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Welcome back, $firstName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Here's how your rental business is performing today.",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5),
          ),
          const SizedBox(height: OwnerSpacing.lg),
          Wrap(
            spacing: OwnerSpacing.sm,
            runSpacing: OwnerSpacing.sm,
            children: [
              _ActionButton(icon: Icons.add_rounded, label: 'Add New Car', filled: true, onTap: () {}),
              _ActionButton(icon: Icons.calendar_month_rounded, label: 'View Bookings', onTap: () {}),
              _ActionButton(icon: Icons.directions_car_rounded, label: 'Manage Cars', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.filled = false});

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? OwnerColors.primary : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(OwnerRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OwnerRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: OwnerSpacing.md, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
