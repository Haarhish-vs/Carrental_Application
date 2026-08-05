import 'package:flutter/material.dart';

enum OwnerNotificationType { bookingRequest, paymentReceived, rentalEnding, maintenance, lowRating }

class OwnerNotification {
  const OwnerNotification({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    this.unread = false,
  });

  final OwnerNotificationType type;
  final String title;
  final String subtitle;
  final String timeAgo;
  final bool unread;

  IconData get icon {
    switch (type) {
      case OwnerNotificationType.bookingRequest:
        return Icons.event_available_rounded;
      case OwnerNotificationType.paymentReceived:
        return Icons.payments_rounded;
      case OwnerNotificationType.rentalEnding:
        return Icons.timer_rounded;
      case OwnerNotificationType.maintenance:
        return Icons.build_rounded;
      case OwnerNotificationType.lowRating:
        return Icons.star_half_rounded;
    }
  }

  Color get color {
    switch (type) {
      case OwnerNotificationType.bookingRequest:
        return const Color(0xff2563EB);
      case OwnerNotificationType.paymentReceived:
        return const Color(0xff1F9B71);
      case OwnerNotificationType.rentalEnding:
        return const Color(0xffD97706);
      case OwnerNotificationType.maintenance:
        return const Color(0xff8B5CF6);
      case OwnerNotificationType.lowRating:
        return const Color(0xffDC2626);
    }
  }
}
