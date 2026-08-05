import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'common/owner_colors.dart';
import 'common/owner_date_format.dart';
import 'common/owner_spacing.dart';
import '../../models/owner_dummy_data.dart';

/// Top App Bar for the Owner Dashboard: avatar, owner name, business
/// name, today's date, notification icon (with unread badge), customer portal switch, and settings.
class OwnerTopBar extends StatelessWidget implements PreferredSizeWidget {
  const OwnerTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final today = OwnerDateFormat.full(DateTime.now());

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: OwnerSpacing.md,
      title: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: OwnerColors.primaryLight,
            child: Icon(Icons.person_rounded, color: OwnerColors.primary),
          ),
          const SizedBox(width: OwnerSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  OwnerDummyData.ownerName,
                  style: const TextStyle(color: OwnerColors.ink, fontWeight: FontWeight.w700, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${OwnerDummyData.businessName} · $today',
                  style: const TextStyle(color: Colors.black54, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.storefront_rounded, size: 16),
            label: const Text('Customer App', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: OwnerColors.primary,
              backgroundColor: OwnerColors.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ),
        _IconAction(
          icon: Icons.notifications_none_rounded,
          badgeCount: OwnerDummyData.unreadNotifications,
          onTap: () {},
        ),
        _IconAction(icon: Icons.settings_outlined, onTap: () {}),
        const SizedBox(width: OwnerSpacing.sm),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, this.badgeCount = 0, required this.onTap});

  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onTap,
            icon: Icon(icon, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: OwnerColors.surfaceMuted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: OwnerColors.danger, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
