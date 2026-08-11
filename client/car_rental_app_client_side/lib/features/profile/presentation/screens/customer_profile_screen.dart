import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/services/auth_service.dart';
import '../../../owner/data/services/car_api_service.dart';
import '../../models/customer_profile_stats.dart';
import '../../models/rating_summary.dart';
import '../../models/trip_insight.dart';
import '../../data/profile_api_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stat_row.dart';
import '../widgets/rating_card.dart';
import '../widgets/section_card.dart';
import '../widgets/trip_insights_card.dart';
import 'edit_profile_screen.dart';

/// Customer / renter profile — identity, activity stats, rating,
/// a compact link into My Trips (the detailed trip data itself lives
/// there, not here), and essential account actions.
///
/// Deliberately does NOT show: reviews/comments, total distance as a
/// standalone stat, total days, or any business/financial data — see
/// the Owner Profile for that side.
class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key, this.onViewTrips});

  /// Called after popping this screen to switch the Home bottom nav
  /// to the "My Trips" (My Bookings) tab. Kept optional/nullable so
  /// this screen also works if pushed from anywhere else later.
  final VoidCallback? onViewTrips;

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final CarApiService _apiService = CarApiService();
  late Future<List<Map<String, dynamic>>> _bookingsFuture;
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _apiService.getMyBookings();
    _profileFuture = ProfileApiService().getProfile();
  }

  void _goToTrips() {
    Navigator.of(context).pop();
    widget.onViewTrips?.call();
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditProfileScreen(isOwner: false)),
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
    final isVerified = user?['is_verified'] == true || user?['isVerified'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHeader(
                name: (name == null || name.isEmpty) ? 'Guest User' : name,
                phone: phone,
                email: email,
                location: location,
                avatarUrl: user?['profile_photo_url']?.toString(),
                verified: isVerified,
                onEditTap: _editProfile,
                onAvatarTap: _updatePhoto,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _bookingsFuture,
                  builder: (context, snapshot) {
                    final bookings = snapshot.data ?? const [];
                    final stats = CustomerProfileStats.fromBookings(bookings);
                    final insights = TripInsights.fromBookings(bookings);
                    final recent = bookings.take(2).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProfileStatRow(items: [
                          ProfileStatItem(
                            icon: Icons.list_alt_outlined,
                            label: 'Bookings',
                            value: '${stats.totalBookings}',
                          ),
                          ProfileStatItem(
                            icon: Icons.directions_car_filled_outlined,
                            label: 'Currently Rented',
                            value: '${stats.currentlyRented}',
                            color: AppColors.success,
                          ),
                          ProfileStatItem(
                            icon: Icons.flag_outlined,
                            label: 'Completed Trips',
                            value: '${stats.completedTrips}',
                          ),
                        ]),
                        const SizedBox(height: 14),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _profileFuture,
                          builder: (context, profileSnapshot) {
                            final customer = profileSnapshot.data?['customer'] as Map<String, dynamic>?;
                            return RatingCard(
                              summary: RatingSummary.fromApi(
                                customer?['rating'] as Map<String, dynamic>?,
                              ),
                              showDistribution: false,
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        SectionCard(
                          title: 'My Trips',
                          icon: Icons.map_outlined,
                          actionLabel: 'View All',
                          onActionTap: _goToTrips,
                          child: insights.totalTrips == 0
                              ? const Text(
                                  'No trips yet. Book a car to get started.',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${insights.totalTrips} trip${insights.totalTrips == 1 ? '' : 's'} so far'
                                      '${insights.mostUsed != null ? ' · most used: ${insights.mostUsed!.vehicleName}' : ''}',
                                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tap "View All" for full trip insights and history.',
                                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                        ),
                        if (recent.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          SectionCard(
                            title: 'Recent Bookings',
                            icon: Icons.history_rounded,
                            actionLabel: 'View All',
                            onActionTap: _goToTrips,
                            child: Column(
                              children: [
                                for (final b in recent) _RecentBookingRow(booking: b),
                              ],
                            ),
                          ),
                        ],
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

class _RecentBookingRow extends StatelessWidget {
  const _RecentBookingRow({required this.booking});

  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final vehicle = booking['vehicle'] as Map<String, dynamic>? ?? const {};
    final name = [vehicle['brand'], vehicle['model']]
        .where((p) => p != null && p.toString().isNotEmpty)
        .join(' ');
    final status = booking['status']?.toString() ?? 'pending';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
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
          Text(
            status.toUpperCase(),
            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
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
