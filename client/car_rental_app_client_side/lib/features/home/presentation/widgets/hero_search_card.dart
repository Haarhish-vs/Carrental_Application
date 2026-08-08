import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Search card for Home Screen. Purely presentational — every field's
/// current value comes from the constructor and every tap fires a
/// callback. No pickers, no navigation, no internal state. Whoever
/// owns state (parent screen, or a state manager later) supplies the
/// values and reacts to the callbacks.
class HeroSearchCard extends StatelessWidget {
  final String? pickupLocation;
  final String? pickupDate;
  final String? pickupTime;
  final String? returnDate;
  final String? returnTime;

  final VoidCallback onPickupLocationTap;
  final VoidCallback onPickupDateTap;
  final VoidCallback onPickupTimeTap;
  final VoidCallback onReturnDateTap;
  final VoidCallback onReturnTimeTap;
  final VoidCallback onSearch;

  const HeroSearchCard({
    super.key,
    this.pickupLocation,
    this.pickupDate,
    this.pickupTime,
    this.returnDate,
    this.returnTime,
    required this.onPickupLocationTap,
    required this.onPickupDateTap,
    required this.onPickupTimeTap,
    required this.onReturnDateTap,
    required this.onReturnTimeTap,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find your perfect ride',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          _FieldTile(
            icon: Icons.location_on_outlined,
            label: 'Pickup Location',
            value: pickupLocation,
            placeholder: 'Select Location',
            onTap: onPickupLocationTap,
          ),
          const _DividerLine(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FieldTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Pickup Date',
                  value: pickupDate,
                  placeholder: 'Select Date',
                  onTap: onPickupDateTap,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _FieldTile(
                  icon: Icons.access_time,
                  label: 'Pickup Time',
                  value: pickupTime,
                  placeholder: 'Select Time',
                  onTap: onPickupTimeTap,
                ),
              ),
            ],
          ),
          const _DividerLine(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FieldTile(
                  icon: Icons.calendar_today,
                  label: 'Return Date',
                  value: returnDate,
                  placeholder: 'Select Date',
                  onTap: onReturnDateTap,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _FieldTile(
                  icon: Icons.access_time_filled,
                  label: 'Return Time',
                  value: returnTime,
                  placeholder: 'Select Time',
                  onTap: onReturnTimeTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.search, size: 20),
              label: const Text('Search Cars', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const _FieldTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (value == null || value!.trim().isEmpty) ? placeholder : value!;
    final hasValue = value != null && value!.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    displayValue,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, color: AppColors.divider);
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 44,
        color: AppColors.divider,
        margin: const EdgeInsets.symmetric(horizontal: 10),
      );
}