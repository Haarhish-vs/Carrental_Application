import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';

class HomeDrawer extends StatelessWidget {
  final String? userName;
  final String? userLocation;
  final String? profileImageUrl;
  final bool isAuthenticated;

  final VoidCallback onProfileTap;
  final VoidCallback onTripsTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onSupportTap;
  final VoidCallback onHostTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onHelpTap;
  final VoidCallback onPrivacyTap;
  final VoidCallback onLogoutTap;
  final VoidCallback? onLoginTap;

  const HomeDrawer({
    super.key,
    this.userName,
    this.userLocation,
    this.profileImageUrl,
    this.isAuthenticated = false,
    required this.onProfileTap,
    required this.onTripsTap,
    required this.onFavoritesTap,
    required this.onSupportTap,
    required this.onHostTap,
    required this.onSettingsTap,
    required this.onHelpTap,
    required this.onPrivacyTap,
    required this.onLogoutTap,
    this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (userName == null || userName!.trim().isEmpty)
        ? 'Guest User'
        : userName!;

    final bool hasValidLocation = userLocation != null &&
        userLocation!.trim().isNotEmpty &&
        userLocation != 'Select Location';

    final bool hasProfileImage = profileImageUrl != null && profileImageUrl!.trim().isNotEmpty;

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
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: hasProfileImage
                        ? CachedNetworkImageProvider(profileImageUrl!)
                        : null,
                    child: !hasProfileImage
                        ? const Icon(
                            Icons.person,
                            size: 32,
                            color: AppColors.primary,
                          )
                        : null,
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
                  if (hasValidLocation) ...[
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
                            userLocation!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
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

            if (isAuthenticated)
              _DrawerTile(
                icon: Icons.logout,
                title: "Logout",
                onTap: onLogoutTap,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onLoginTap ?? onLogoutTap,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text(
                      'Log In / Register',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
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
