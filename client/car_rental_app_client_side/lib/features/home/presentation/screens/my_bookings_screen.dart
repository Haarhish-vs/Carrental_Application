import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/auth_required_view.dart';
import '../../../auth/services/auth_service.dart';
import '../../../owner/data/services/car_api_service.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../models/car_model.dart';
import 'payment_screen.dart';
import 'booking_tracking_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, required this.onExplorePressed});

  final VoidCallback onExplorePressed;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final CarApiService _apiService = CarApiService();
  late Future<List<Map<String, dynamic>>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    AuthService.authStateNotifier.addListener(_onAuthChanged);
    _refreshBookings();
  }

  @override
  void dispose() {
    AuthService.authStateNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      _refreshBookings();
    }
  }

  void _refreshBookings() {
    setState(() {
      _bookingsFuture = _apiService.getMyBookings();
    });
  }

  bool _isCancellable(String status) =>
      status == 'pending' || status == 'confirmed';

  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, Keep It'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _apiService.cancelBooking(bookingId, reason: 'Cancelled by renter');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      _refreshBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  String _formatBookingDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return dateStr;
  }

  Widget _buildStatusChip(String status, String paymentStatus) {
    Color bg;
    Color text;
    String label = status.toUpperCase();

    if (status.toLowerCase() == 'pending') {
      bg = const Color(0xFFFEF7E0);
      text = Colors.orange;
      label = 'PENDING APPROVAL';
    } else if (status.toLowerCase() == 'confirmed' && paymentStatus.toLowerCase() == 'unpaid') {
      bg = const Color(0xFFE2F0FD);
      text = AppColors.primary;
      label = 'AWAITING PAYMENT';
    } else {
      switch (status.toLowerCase()) {
        case 'confirmed':
          bg = const Color(0xFFE6F4EA);
          text = AppColors.success;
          label = 'CONFIRMED';
          break;
        case 'active':
          bg = const Color(0xFFEAF2FF);
          text = AppColors.primary;
          label = 'ACTIVE';
          break;
        case 'completed':
          bg = const Color(0xFFF1F3F4);
          text = AppColors.textSecondary;
          label = 'COMPLETED';
          break;
        case 'cancelled':
          bg = const Color(0xFFFCE8E6);
          text = Colors.red;
          label = 'CANCELLED';
          break;
        default:
          bg = const Color(0xFFFEF7E0);
          text = Colors.orange;
          label = 'PENDING';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
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
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isAuthenticated) {
      return AuthRequiredView(
        title: 'My Bookings',
        message:
            'Log in or create an account to view your booked cars, status, and receipts.',
        buttonText: 'Log In / Register',
        onAuthenticated: _refreshBookings,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
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
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        widget.onExplorePressed();
                      }
                    },
                    tooltip: 'Back',
                  ),
                  const Text(
                    'My Bookings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF103B66),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                ),
                onPressed: _refreshBookings,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _bookingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final bookings = snapshot.data ?? [];
              for (final b in bookings) {
                if (b['status']?.toString().toLowerCase() == 'active') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    LocationTrackingService().startTracking(b['id']?.toString() ?? '');
                  });
                  break;
                }
              }
              if (bookings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.directions_car_outlined,
                          size: 64,
                          color: Color(0xFF8EA6BE),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Bookings Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Book your first ride and get ready for an amazing trip!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: widget.onExplorePressed,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Explore Cars'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final car = booking['vehicle'] as Map<String, dynamic>? ?? {};
                  final images = (car['images'] as List<dynamic>?) ?? [];
                  final imageUrl = images.isNotEmpty
                      ? images.first.toString()
                      : '';
                  final brand = car['brand'] ?? 'Vehicle';
                  final model = car['model'] ?? '';
                  final seats = car['seats'] ?? 5;
                  final transmission = car['transmission'] ?? 'Automatic';
                  final fuelType = car['fuel_type'] ?? 'Petrol';
                  final city = car['city'] ?? 'Default City';

                  final rawStart =
                      DateTime.tryParse(booking['start_date'] ?? '') ??
                      DateTime.now();
                  final rawEnd =
                      DateTime.tryParse(booking['end_date'] ?? '') ??
                      DateTime.now();

                  // Calculate days matching what Razorpay charged
                  final startCal = DateTime(
                    rawStart.year,
                    rawStart.month,
                    rawStart.day,
                  );
                  final endCal = DateTime(
                    rawEnd.year,
                    rawEnd.month,
                    rawEnd.day,
                  );
                  final diff = endCal.difference(startCal).inDays;
                  final computedDays = diff <= 0
                      ? 1
                      : diff; // Match frontend payment logic

                  // For display, we ignore DB total_price and calculate it to match gateway
                  final double pricePerDay = (car['price_per_day'] ?? 0).toDouble();
                  final double displayPrice = computedDays * pricePerDay;

                  final startDate = _formatBookingDate(booking['start_date']);
                  final endDate = _formatBookingDate(booking['end_date']);
                  final depositAmount = booking['deposit_amount'] ?? 0.0;

                  return InkWell(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BookingTrackingScreen(booking: booking),
                        ),
                      );
                      _refreshBookings();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFEAF2FF),
                                      child: const Icon(
                                        Icons.directions_car_rounded,
                                        size: 48,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFFEAF2FF),
                                    child: const Icon(
                                      Icons.directions_car_rounded,
                                      size: 48,
                                      color: AppColors.primary,
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$brand $model',
                                        style: const TextStyle(
                                          color: Color(0xFF103B66),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    _buildStatusChip(
                                      booking['status'] ?? 'pending',
                                      booking['payment_status'] ?? 'unpaid',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      city,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 24,
                                  color: AppColors.divider,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSpecChip(
                                      Icons.event_seat_outlined,
                                      '$seats Seats',
                                    ),
                                    _buildSpecChip(
                                      Icons.settings_outlined,
                                      transmission,
                                    ),
                                    _buildSpecChip(
                                      Icons.local_gas_station_outlined,
                                      fuelType,
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 24,
                                  color: AppColors.divider,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'BOOKING PERIOD',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$startDate - $endDate',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'TOTAL AMOUNT',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${displayPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Deposit: ₹${depositAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    Text(
                                      'Payment: ${booking['payment_status'] ?? 'unpaid'}',
                                      style: TextStyle(
                                        color:
                                            (booking['payment_status'] == 'paid')
                                            ? AppColors.success
                                            : Colors.orange,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                // Pay Now button for confirmed & unpaid bookings
                                if (booking['status'] == 'confirmed' &&
                                    booking['payment_status'] == 'unpaid') ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () async {
                                        final carModel = CarModel.fromJson(car);
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PaymentScreen(
                                              car: carModel,
                                              pickupDateTime: rawStart,
                                              returnDateTime: rawEnd,
                                              days: computedDays,
                                              totalAmount: displayPrice,
                                              bookingId: booking['id']?.toString(),
                                            ),
                                          ),
                                        );
                                        _refreshBookings();
                                      },
                                      icon: const Icon(Icons.payment_rounded, size: 16),
                                      label: const Text('Pay Now'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                // Cancel button for cancellable bookings
                                if (_isCancellable(booking['status'] ?? '')) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _cancelBooking(
                                        booking['id']?.toString() ?? '',
                                      ),
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('Cancel Booking'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
