import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Top app bar for Home Screen.
/// Fully data-driven and callback-driven — no navigation, no hardcoded
/// user data. Backend/auth module can pass real values once login is wired.
class CustomHomeAppBar extends StatelessWidget {
  /// Null until login/profile data is available.
  final String? userName;

  /// Null until location permission/selection is available.
  final String? location;

  /// Null until user uploads/has a profile photo.
  final String? profileImageUrl;

  final VoidCallback onMenuTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onProfileTap;

  const CustomHomeAppBar({
    super.key,
    this.userName,
    this.location,
    this.profileImageUrl,
    required this.onMenuTap,
    required this.onFavoriteTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: onMenuTap,
            borderRadius: BorderRadius.circular(24),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.menu_rounded, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(text: 'TH'),
                      TextSpan(
                        text: 'A',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      TextSpan(text: 'DAM'),
                    ],
                  ),
                ),
                if (location != null && location!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          location!.trim(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _CircleIconButton(
            icon: Icons.favorite_border_rounded,
            onTap: onFavoriteTap,
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage:
                  (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                  ? NetworkImage(profileImageUrl!)
                  : null,
              child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                  ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
