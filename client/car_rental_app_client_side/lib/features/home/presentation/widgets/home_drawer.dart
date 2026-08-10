import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HomeDrawer extends StatelessWidget {
  final String? userName;
  final String? userLocation;

  final VoidCallback onProfileTap;
  final VoidCallback onTripsTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onSupportTap;
  final VoidCallback onHostTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onHelpTap;
  final VoidCallback onPrivacyTap;
  final VoidCallback onLogoutTap;

  const HomeDrawer({
    super.key,
    this.userName,
    this.userLocation,
    required this.onProfileTap,
    required this.onTripsTap,
    required this.onFavoritesTap,
    required this.onSupportTap,
    required this.onHostTap,
    required this.onSettingsTap,
    required this.onHelpTap,
    required this.onPrivacyTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (userName == null || userName!.trim().isEmpty)
        ? 'Guest User'
        : userName!;

    final displayLocation =
        (userLocation == null || userLocation!.trim().isEmpty)
        ? 'Select Location'
        : userLocation!;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          displayLocation,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            _DrawerTile(
              icon: Icons.person_outline,
              title: "Profile",
              onTap: onProfileTap,
            ),

            _DrawerTile(
              icon: Icons.map_outlined,
              title: "My Trips",
              onTap: onTripsTap,
            ),

            _DrawerTile(
              icon: Icons.favorite_border,
              title: "Favorites",
              onTap: onFavoritesTap,
            ),

            _DrawerTile(
              icon: Icons.support_agent_outlined,
              title: "Support",
              onTap: onSupportTap,
            ),

            _DrawerTile(
              icon: Icons.garage_outlined,
              title: "Become a Host",
              onTap: onHostTap,
            ),

            const Divider(),

            _DrawerTile(
              icon: Icons.settings_outlined,
              title: "Settings",
              onTap: onSettingsTap,
            ),

            _DrawerTile(
              icon: Icons.help_outline,
              title: "Help & FAQs",
              onTap: onHelpTap,
            ),

            _DrawerTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: onPrivacyTap,
            ),

            const Spacer(),

            const Divider(),

            _DrawerTile(
              icon: Icons.logout,
              title: "Logout",
              onTap: onLogoutTap,
            ),

            const SizedBox(height: 8),

            const Text("Version 1.0.0", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      onTap: onTap,
    );
  }
}
