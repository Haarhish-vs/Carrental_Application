import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/services/auth_service.dart';
import '../../../owner/data/services/car_api_service.dart';
import '../../models/owner_earnings.dart';
import '../../models/owner_fleet_stats.dart';
import '../../models/rating_summary.dart';
import '../../data/profile_api_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stat_row.dart';
import '../widgets/rating_card.dart';
import '../widgets/section_card.dart';
import 'edit_profile_screen.dart';

/// Indian numbering (lakh/crore) grouping, e.g. 245680 -> "2,45,680".
String _formatIndian(double value) {
  final intVal = value.round();
  var str = intVal.toString();
  if (str.length <= 3) return str;

  final lastThree = str.substring(str.length - 3);
  var rest = str.substring(0, str.length - 3);

  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);

  return '${groups.join(',')},$lastThree';
}

/// Owner profile — identity (no verification badge, per spec),
/// earnings, fleet stats, renters, ratings, a compact fleet/document
/// overview, and a link into "My Car" for the full vehicle list.
///
/// Earnings and renter stats are mock/demo values (clearly documented
/// in their model files) since this project's backend has no
/// earnings/payouts or per-fleet-booking endpoint yet. Fleet stats and
/// document status ARE computed from the real `getMyListings()` data.
class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key, this.onViewListings});

  /// Called after popping this screen to switch the Home bottom nav
  /// to the "My Car" (listings) tab.
  final VoidCallback? onViewListings;

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final CarApiService _apiService = CarApiService();
  late Future<List<Map<String, dynamic>>> _listingsFuture;
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _listingsFuture = _apiService.getMyListings();
    _profileFuture = ProfileApiService().getProfile();
  }

  void _goToListings() {
    Navigator.of(context).pop();
    widget.onViewListings?.call();
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditProfileScreen(isOwner: true)),
    );
    if (updated == true && mounted) setState(() {});
  }

  Future<void> _updatePhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    final updatedUser = await ProfileApiService().uploadPhoto(image);
    AuthService.currentUser?.addAll(updatedUser);
    if (mounted) setState(() => _profileFuture = ProfileApiService().getProfile());
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final name = user?['full_name']?.toString() ?? user?['fullName']?.toString();
    final phone = user?['phone_number']?.toString() ?? user?['phoneNumber']?.toString();
    final email = user?['email']?.toString();
    final location = user?['city']?.toString() ?? user?['location']?.toString();
    final earnings = OwnerEarnings.demo();
    final renters = OwnerRenterStats.demo();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHeader(
                name: (name == null || name.isEmpty) ? 'Guest Owner' : name,
                phone: phone,
                email: email,
                location: location,
                avatarUrl: user?['profile_photo_url']?.toString(),
                verified: null, // Owners never show a verification badge.
                onEditTap: _editProfile,
                onAvatarTap: _updatePhoto,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _listingsFuture,
                  builder: (context, snapshot) {
                    final listings = snapshot.data ?? const [];
                    final fleet = OwnerFleetStats.fromListings(listings);
                    final docs = VehicleDocumentInfo.fromListings(listings);
                    final recentVehicles = listings.take(3).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionCard(
                          title: 'Earnings',
                          icon: Icons.account_balance_wallet_outlined,
                          child: Row(
                            children: [
                              _EarningTile(label: 'Total', value: earnings.total),
                              _EarningTile(label: 'This Month', value: earnings.thisMonth),
                              _EarningTile(label: 'Today', value: earnings.today),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ProfileStatRow(items: [
                          ProfileStatItem(
                            icon: Icons.directions_car_outlined,
                            label: 'Total Cars',
                            value: '${fleet.totalCars}',
                          ),
                          ProfileStatItem(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Available',
                            value: '${fleet.availableCars}',
                            color: AppColors.success,
                          ),
                          ProfileStatItem(
                            icon: Icons.event_busy_outlined,
                            label: 'Rented',
                            value: '${fleet.rentedCars}',
                            color: Colors.orange,
                          ),
                        ]),
                        const SizedBox(height: 14),
                        SectionCard(
                          title: 'Renters',
                          icon: Icons.groups_outlined,
                          child: Row(
                            children: [
                              _RenterTile(label: 'Repeat Renters', value: renters.repeatRenters),
                              _RenterTile(label: 'Total Renters', value: renters.totalRenters),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _profileFuture,
                          builder: (context, profileSnapshot) {
                            final owner = profileSnapshot.data?['owner'] as Map<String, dynamic>?;
                            return RatingCard(
                              summary: RatingSummary.fromApi(
                                owner?['rating'] as Map<String, dynamic>?,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        SectionCard(
                          title: 'My Vehicles',
                          icon: Icons.garage_outlined,
                          actionLabel: 'View All',
                          onActionTap: _goToListings,
                          child: recentVehicles.isEmpty
                              ? const Text(
                                  'No vehicles listed yet.',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                )
                              : Column(
                                  children: [
                                    for (final v in recentVehicles) _VehicleRow(vehicle: v),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 14),
                        SectionCard(
                          title: 'Documents & Verification',
                          icon: Icons.description_outlined,
                          child: docs.isEmpty
                              ? const Text(
                                  'No vehicle documents on record yet.',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                )
                              : Column(
                                  children: [for (final d in docs) _DocumentRow(doc: d)],
                                ),
                        ),
                        const SizedBox(height: 14),
                        SectionCard(
                          title: 'Payouts',
                          icon: Icons.payments_outlined,
                          child: InkWell(
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Payout history coming soon')),
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.account_balance_outlined, size: 16, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text('View payout history & bank details', style: TextStyle(fontSize: 12.5)),
                                  ),
                                  Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _AccountActions(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningTile extends StatelessWidget {
  const _EarningTile({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u20b9${_formatIndian(value)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _RenterTile extends StatelessWidget {
  const _RenterTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.vehicle});

  final Map<String, dynamic> vehicle;

  @override
  Widget build(BuildContext context) {
    final name = [vehicle['brand'], vehicle['model']]
        .where((p) => p != null && p.toString().isNotEmpty)
        .join(' ');
    final isAvailable = vehicle['is_available'] == true || vehicle['isAvailable'] == true;
    final rawOdometer = vehicle['odometerReading'] ?? vehicle['odometer_reading'];
    final odometer = rawOdometer is num ? rawOdometer.toDouble() : double.tryParse(rawOdometer?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.directions_car_rounded, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name.isEmpty ? 'Vehicle' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          if (odometer != null) ...[
            Text('${odometer.toStringAsFixed(0)} km', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAvailable ? const Color(0xFFE6F4EA) : const Color(0xFFFEF7E0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isAvailable ? 'AVAILABLE' : 'RENTED',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: isAvailable ? AppColors.success : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.doc});

  final VehicleDocumentInfo doc;

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    switch (doc.status) {
      case DocumentStatus.verified:
        color = AppColors.success;
        label = 'Verified';
      case DocumentStatus.pending:
        color = Colors.orange;
        label = 'Pending';
      case DocumentStatus.expired:
        color = Colors.redAccent;
        label = 'Expired';
      case DocumentStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              doc.vehicleName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
            child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Account',
      icon: Icons.settings_outlined,
      child: InkWell(
        onTap: () {
          AuthService.logout();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        borderRadius: BorderRadius.circular(10),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}
