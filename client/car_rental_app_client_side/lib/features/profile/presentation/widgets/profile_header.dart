import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Shared identity header used by both the Owner and Customer Profile
/// screens: avatar, name, phone, email, location, and a small edit
/// icon (never a large "Edit Profile" button, per spec).
///
/// [verified] is nullable on purpose: pass `true`/`false` to show the
/// customer verification badge, or leave it `null` (as the Owner
/// profile does) to omit the badge entirely.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    this.phone,
    this.email,
    this.location,
    this.avatarUrl,
    this.verified,
    this.onAvatarTap,
    required this.onEditTap,
  });

  final String name;
  final String? phone;
  final String? email;
  final String? location;
  final String? avatarUrl;

  /// null = no badge (Owner). true/false = Verified/Not Verified (Customer).
  final bool? verified;
  final VoidCallback? onAvatarTap;

  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onAvatarTap,
            borderRadius: BorderRadius.circular(40),
            child: Stack(children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? NetworkImage(avatarUrl!) : null,
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 36, color: AppColors.primary) : null,
              ),
              if (onAvatarTap != null) const Positioned(
                right: 0, bottom: 0,
                child: CircleAvatar(radius: 11, child: Icon(Icons.camera_alt, size: 13)),
              ),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _EditIconButton(onTap: onEditTap),
                  ],
                ),
                if (verified != null) ...[
                  const SizedBox(height: 6),
                  _VerificationBadge(verified: verified!),
                ],
                const SizedBox(height: 10),
                if (phone != null && phone!.isNotEmpty)
                  _InfoLine(icon: Icons.phone_outlined, text: phone!),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _InfoLine(icon: Icons.mail_outline_rounded, text: email!),
                ],
                if (location != null && location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _InfoLine(icon: Icons.location_on_outlined, text: location!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.success : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified_rounded : Icons.error_outline_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            verified ? 'Verified' : 'Not Verified',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _EditIconButton extends StatelessWidget {
  const _EditIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Edit profile',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
