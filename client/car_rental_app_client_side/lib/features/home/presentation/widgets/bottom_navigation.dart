import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom navigation for Home Screen. Profile tab replaced with Host
/// (top app bar already owns the profile avatar, so this avoids duplication).
/// Purely presentational — selection state and routing both live outside.
class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onTripsTap;
  final VoidCallback onSupportTap;
  final VoidCallback onHostTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onHomeTap,
    required this.onTripsTap,
    required this.onSupportTap,
    required this.onHostTap,
  });

  void _handleTap(int index) {
    switch (index) {
      case 0:
        onHomeTap();
        break;
      case 1:
        onTripsTap();
        break;
      case 2:
        onSupportTap();
        break;
      case 3:
        onHostTap();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: _handleTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      showUnselectedLabels: true,
      elevation: 10,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Trips'),
        BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        BottomNavigationBarItem(icon: Icon(Icons.garage_outlined), label: 'Host'),
      ],
    );
  }
}