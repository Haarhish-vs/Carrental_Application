import 'package:flutter/material.dart';
import '../../auth/presentation/screens/auth_screen.dart';
import '../../auth/services/auth_service.dart';
import 'screens/customer_profile_screen.dart';

/// Opens the authenticated account profile. Capability selection is handled
/// by the protected profile API; this never infers a role from vehicle count.
Future<void> openProfile(
  BuildContext context, {
  VoidCallback? onViewTrips,
  VoidCallback? onViewListings,
}) async {
  if (!AuthService.isAuthenticated) {
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (success != true || !context.mounted) return;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CustomerProfileScreen(onViewTrips: onViewTrips),
    ),
  );
}
