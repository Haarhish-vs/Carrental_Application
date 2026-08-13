import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/auth_required_view.dart';
import '../../../auth/services/auth_service.dart';
import '../../../owner/data/services/car_api_service.dart';
import 'booking_tracking_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({
    super.key,
    required this.onListCarPressed,
    this.onExplorePressed,
  });

  final VoidCallback onListCarPressed;
  final VoidCallback? onExplorePressed;

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  final CarApiService _apiService = CarApiService();
  late Future<List<Map<String, dynamic>>> _carsFuture;
  late Future<List<Map<String, dynamic>>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    AuthService.authStateNotifier.addListener(_onAuthChanged);
    _refresh();
  }

  @override
  void dispose() {
    AuthService.authStateNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      _refresh();
    }
  }

  void _refresh() {
    setState(() {
      _carsFuture = _apiService.getMyListings();
      _requestsFuture = _apiService.getMyVehicleBookings();
    });
  }

  Future<void> _toggleAvailability(Map<String, dynamic> car, bool currentlyAvailable) async {
    final vehicleId = car['id']?.toString() ?? '';
    final targetAvailable = !currentlyAvailable;
    final bookedUntil = _bookedUntil(car);

    if (targetAvailable && bookedUntil != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Action Not Allowed'),
          content: Text('This vehicle is currently booked until $bookedUntil. You cannot mark it as available until the trip is finished or completed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final actionLabel = targetAvailable ? 'mark as available' : 'mark as unavailable';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(targetAvailable ? 'Mark as Available' : 'Mark as Unavailable'),
        content: Text(
          targetAvailable
              ? 'This car will become visible and bookable by renters.'
              : 'This car will be hidden from renters and cannot be booked until re-enabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(actionLabel[0].toUpperCase() + actionLabel.substring(1)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _apiService.toggleVehicleAvailability(vehicleId, isAvailable: targetAvailable);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(targetAvailable ? 'Car is now available for booking.' : 'Car is now marked as unavailable.'),
          backgroundColor: targetAvailable ? AppColors.success : Colors.orange,
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  // Parses ISO date string and returns a nicely formatted date
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$min $period';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildStepNode({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    required bool isLast,
    String? timestamp,
  }) {
    Color indicatorColor = isDone
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : Colors.grey.shade300;

    IconData nodeIcon = isDone
        ? Icons.check_circle_rounded
        : isActive
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left timeline line & indicator
        Column(
          children: [
            Icon(nodeIcon, color: indicatorColor, size: 24),
            if (!isLast)
              Container(
                width: 2.5,
                height: 48,
                color: isDone ? AppColors.success : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Right step info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDone || isActive ? AppColors.textPrimary : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDone || isActive ? AppColors.textSecondary : Colors.grey.shade400,
                ),
              ),
              if (timestamp != null && timestamp.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  timestamp,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDone ? Colors.grey.shade500 : Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // Determines the "until" date a car is booked (from activeBooking on car, if available)
  String? _bookedUntil(Map<String, dynamic> car) {
    final booking = car['activeBooking'] as Map<String, dynamic>?;
    if (booking != null) {
      return _formatDate(booking['end_date']?.toString());
    }
    // Fallback: if is_available is false and unavailable_until present
    final until = car['unavailable_until']?.toString();
    if (until != null && until.isNotEmpty) return _formatDate(until);
    return null;
  }

  Widget _buildStatusBadge(bool isAvailable, String? bookedUntil) {
    if (isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F4EA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'AVAILABLE',
          style: TextStyle(
            color: AppColors.success,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE8E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        bookedUntil != null ? 'BOOKED TILL $bookedUntil' : 'UNAVAILABLE',
        style: const TextStyle(
          color: Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCarCard(Map<String, dynamic> car) {
    final brand = car['brand']?.toString() ?? '';
    final model = car['model']?.toString() ?? '';
    final name = [brand, model].where((s) => s.isNotEmpty).join(' ');
    final city = car['city']?.toString() ?? 'Unknown City';
    final price = double.tryParse(
          car['price_per_day']?.toString() ?? car['dailyPrice']?.toString() ?? '',
        ) ??
        0.0;
    final seats = car['seats']?.toString() ?? '4';
    final transmission = car['transmission']?.toString() ?? 'Automatic';
    final fuelType = (car['fuel_type'] ?? car['fuelType'])?.toString() ?? 'Petrol';
    final isAvailable = car['is_available'] == true;
    final bookedUntil = _bookedUntil(car);

    final images = (car['images'] as List<dynamic>?) ?? [];
    final imageUrl = images.isNotEmpty ? images.first.toString() : '';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        memCacheHeight: 400, // Optimize memory for lists
                        placeholder: (context, url) => _placeholderImage(),
                        errorWidget: (context, url, error) => _placeholderImage(),
                      )
                    : _placeholderImage(),
                // Overlay banner if unavailable
                if (!isAvailable)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.black.withOpacity(0.55),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            bookedUntil != null
                                ? 'Not available until $bookedUntil'
                                : 'Currently unavailable',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name.isNotEmpty ? name : 'My Car',
                        style: const TextStyle(
                          color: Color(0xFF103B66),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(isAvailable, bookedUntil),
                  ],
                ),
                const SizedBox(height: 4),
                // City
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      city,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.divider),
                // Specs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpecChip(Icons.event_seat_outlined, '$seats Seats'),
                    _buildSpecChip(Icons.settings_outlined, transmission),
                    _buildSpecChip(Icons.local_gas_station_outlined, fuelType),
                  ],
                ),
                const Divider(height: 20, color: AppColors.divider),
                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PRICE PER DAY',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Toggle availability button
                SizedBox(
                  width: double.infinity,
                  child: isAvailable
                      ? OutlinedButton.icon(
                          onPressed: () => _toggleAvailability(
                            car,
                            isAvailable,
                          ),
                          icon: const Icon(Icons.block_outlined, size: 16),
                          label: const Text('Mark as Unavailable'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: bookedUntil != null
                              ? null
                              : () => _toggleAvailability(
                                  car,
                                  isAvailable,
                                ),
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: Text(bookedUntil != null ? 'Unavailable (Booked)' : 'Mark as Available'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFFEAF2FF),
      child: const Icon(
        Icons.directions_car_rounded,
        size: 48,
        color: AppColors.primary,
      ),
    );
  }

  Future<void> _handleAccept(String bookingId) async {
    try {
      await _apiService.confirmBooking(bookingId);
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking accepted successfully!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleDecline(String bookingId) async {
    try {
      await _apiService.declineBooking(bookingId);
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request declined.'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleStartTrip(String bookingId) async {
    try {
      await _apiService.startBooking(bookingId);
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip started successfully!'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleCompleteTrip(String bookingId) async {
    try {
      await _apiService.completeBooking(bookingId);
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip completed successfully!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildRequestsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _requestsFuture,
      initialData: _apiService.getCachedVehicleBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Something went wrong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFF8EA6BE)),
                  SizedBox(height: 16),
                  Text(
                    'No Rental Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When renters request to book your vehicles, they will show up here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildRequestCard(requests[index]),
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final bookingId = request['id']?.toString() ?? '';
    final vehicle = request['vehicle'] as Map<String, dynamic>? ?? {};
    final brand = vehicle['brand']?.toString() ?? 'Vehicle';
    final model = vehicle['model']?.toString() ?? '';
    final vehicleName = '$brand $model';
    final price = (request['total_price'] ?? 0).toDouble();

    final startDate = _formatDate(request['start_date']);
    final endDate = _formatDate(request['end_date']);

    final status = request['status']?.toString().toLowerCase() ?? 'pending';
    final paymentStatus = request['payment_status']?.toString().toLowerCase() ?? 'unpaid';

    Color statusColor = Colors.orange;
    String statusLabel = 'PENDING ACCEPTANCE';
    if (status == 'confirmed') {
      if (paymentStatus == 'unpaid') {
        statusColor = AppColors.primary;
        statusLabel = 'AWAITING PAYMENT';
      } else {
        statusColor = AppColors.success;
        statusLabel = 'PAID & CONFIRMED';
      }
    } else if (status == 'active') {
      statusColor = AppColors.primary;
      statusLabel = 'ACTIVE TRIP';
    } else if (status == 'completed') {
      statusColor = AppColors.textSecondary;
      statusLabel = 'COMPLETED';
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
      statusLabel = 'CANCELLED';
    }

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingTrackingScreen(booking: request, isOwnerView: true),
          ),
        );
        _refresh();
      },
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    vehicleName,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF103B66)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '$startDate - $endDate',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Payment: ${paymentStatus.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: paymentStatus == 'paid' ? AppColors.success : Colors.orange,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.divider),
            
            // Action Buttons
            if (status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleDecline(bookingId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _handleAccept(bookingId),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'confirmed' && paymentStatus == 'paid') ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _handleStartTrip(bookingId),
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Start Trip'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookingTrackingScreen(booking: request, isOwnerView: true),
                          ),
                        );
                        _refresh();
                      },
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('View Tracking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'active') ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _handleCompleteTrip(bookingId),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Complete Trip'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookingTrackingScreen(booking: request, isOwnerView: true),
                          ),
                        );
                        _refresh();
                      },
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('Live GPS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookingTrackingScreen(booking: request, isOwnerView: true),
                      ),
                    );
                    _refresh();
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View Booking Details & Timeline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

  Widget _buildVehiclesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _carsFuture,
      initialData: _apiService.getCachedListings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Something went wrong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }

        final cars = snapshot.data ?? [];
        if (cars.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.garage_outlined, size: 64, color: Color(0xFF8EA6BE)),
                  const SizedBox(height: 16),
                  const Text('No Cars Listed Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('List your first car and start earning today!', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: widget.onListCarPressed,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('List a Car'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: cars.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildCarCard(cars[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isAuthenticated) {
      return AuthRequiredView(
        title: 'My Cars',
        message: 'Log in or create an account to view your listed vehicles, track availability, and manage earnings.',
        buttonText: 'Log In / Register',
        onAuthenticated: _refresh,
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Color(0xFF103B66),
                      ),
                      onPressed: () {
                        if (widget.onExplorePressed != null) {
                          widget.onExplorePressed!();
                        } else if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          widget.onListCarPressed();
                        }
                      },
                      tooltip: 'Back',
                    ),
                    const Text(
                      'My Cars',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF103B66),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                  onPressed: _refresh,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // TabBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14.5),
              tabs: const [
                Tab(text: 'My Vehicles'),
                Tab(text: 'Rental Requests'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // TabBarView
          Expanded(
            child: TabBarView(
              children: [
                _buildVehiclesTab(),
                _buildRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
