import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Professional footer for Home Screen. All links are callback-only —
/// wiring to real screens (About, Privacy, etc.) happens elsewhere.
class HomeFooter extends StatelessWidget {
  final VoidCallback? onAboutTap;
  final VoidCallback? onPrivacyPolicyTap;
  final VoidCallback? onTermsTap;
  final VoidCallback? onFaqsTap;
  final VoidCallback? onContactUsTap;
  final String appVersion;

  const HomeFooter({
    super.key,
    this.onAboutTap,
    this.onPrivacyPolicyTap,
    this.onTermsTap,
    this.onFaqsTap,
    this.onContactUsTap,
    this.appVersion = '1.0.0',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Car Rental Application',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _FooterLink(label: 'About Us', onTap: onAboutTap),
              _FooterLink(label: 'Privacy Policy', onTap: onPrivacyPolicyTap),
              _FooterLink(label: 'Terms', onTap: onTermsTap),
              _FooterLink(label: 'FAQs', onTap: onFaqsTap),
              _FooterLink(label: 'Contact Us', onTap: onContactUsTap),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: Colors.white.withOpacity(0.15), height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Version $appVersion',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11.5,
                ),
              ),
              Text(
                '© 2026 Car Rental Application',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _FooterLink({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.85),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
