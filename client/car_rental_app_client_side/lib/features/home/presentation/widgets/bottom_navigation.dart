import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Bottom navigation for Home Screen. Profile tab replaced with Host
/// (top app bar already owns the profile avatar, so this avoids duplication).
/// Purely presentational — selection state and routing both live outside.
class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onBookingsTap;
  final VoidCallback onMyCarTap;
  final VoidCallback onHostTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onHomeTap,
    required this.onBookingsTap,
    required this.onMyCarTap,
    required this.onHostTap,
  });

  void _handleTap(int index) {
    switch (index) {
      case 0:
        onHomeTap();
        break;
      case 1:
        onBookingsTap();
        break;
      case 2:
        onMyCarTap();
        break;
      case 3:
        onHostTap();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int safeIndex = currentIndex > 3 ? 0 : currentIndex;
    return BottomNavigationBar(
      currentIndex: safeIndex,
      onTap: _handleTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      showUnselectedLabels: true,
      elevation: 10,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_outlined),
          label: 'My Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car_outlined),
          label: 'My Car',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.garage_outlined),
          label: 'Host',
        ),
      ],
    );
  }
}
