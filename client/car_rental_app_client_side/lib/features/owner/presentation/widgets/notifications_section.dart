import 'package:flutter/material.dart';

import 'common/owner_colors.dart';
import 'common/owner_layout.dart';
import 'common/owner_section_header.dart';
import 'common/owner_spacing.dart';
import '../../models/owner_dummy_data.dart';
import '../../models/owner_notification.dart';

/// SECTION 10 — Notifications.
class NotificationsSection extends StatelessWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerSectionHeader(
          title: 'Notifications',
          subtitle: 'Stay on top of what needs your attention',
          icon: Icons.notifications_none_rounded,
          actionLabel: 'Mark all read',
        ),
        OwnerSurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [for (final n in OwnerDummyData.notifications) _NotificationTile(n: n)],
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n});

  final OwnerNotification n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: OwnerSpacing.sm, vertical: OwnerSpacing.sm),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: n.unread ? OwnerColors.primaryLight.withValues(alpha: 0.35) : null,
        borderRadius: BorderRadius.circular(OwnerRadius.sm),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: n.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(OwnerRadius.sm),
            ),
            child: Icon(n.icon, size: 18, color: n.color),
          ),
          const SizedBox(width: OwnerSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(n.subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: OwnerSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(n.timeAgo, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
              if (n.unread) ...[
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: OwnerColors.primary, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
