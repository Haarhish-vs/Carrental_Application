import 'package:flutter/material.dart';

import 'package:car_rental_app_client_side/core/utils/indian_currency_formatter.dart';
import 'common/owner_colors.dart';
import 'common/owner_date_format.dart';
import 'common/owner_spacing.dart';
import '../../models/owner_booking.dart';

/// A single row for a booking — reuses the existing [OwnerBooking]
/// model (guestName / vehicleName / startDate / total) formatted with Indian currency.
class BookingListTile extends StatelessWidget {
  const BookingListTile({super.key, required this.booking});

  final OwnerBooking booking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: OwnerSpacing.sm),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: OwnerColors.primaryLight,
            child: Icon(Icons.person_rounded, color: OwnerColors.primary, size: 18),
          ),
          const SizedBox(width: OwnerSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.guestName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${booking.vehicleName} · ${OwnerDateFormat.dayMonth(booking.startDate)}',
                  style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: OwnerSpacing.sm),
          Text(
            IndianCurrencyFormatter.format(booking.total),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: OwnerColors.ink),
          ),
        ],
      ),
    );
  }
}
