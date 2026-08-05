import 'package:flutter/material.dart';

import 'owner_colors.dart';
import 'owner_spacing.dart';

/// Consistent section title + optional trailing action, reused above
/// every major block of the Owner Dashboard.
class OwnerSectionHeader extends StatelessWidget {
  const OwnerSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: OwnerSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: OwnerColors.primaryLight,
                borderRadius: BorderRadius.circular(OwnerRadius.sm),
              ),
              child: Icon(icon, size: 18, color: OwnerColors.primary),
            ),
            const SizedBox(width: OwnerSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: OwnerColors.ink, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionTap ?? () {},
              style: TextButton.styleFrom(foregroundColor: OwnerColors.primary),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
