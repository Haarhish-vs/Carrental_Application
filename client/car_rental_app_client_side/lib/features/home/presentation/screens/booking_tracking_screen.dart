import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/services/auth_service.dart';
import '../../../owner/data/services/car_api_service.dart';
import '../../models/car_model.dart';
import 'payment_screen.dart';

class BookingTrackingScreen extends StatefulWidget {
  const BookingTrackingScreen({
    super.key,
    required this.booking,
  });

  final Map<String, dynamic> booking;

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen> {
  final CarApiService _apiService = CarApiService();
  late Future<Map<String, dynamic>> _bookingFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _bookingFuture = _apiService.getBookingById(widget.booking['id']?.toString() ?? '');
    });
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  // Stepper Node Widget
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

  // Decline Action Handler
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

  // Accept Action Handler
  Future<void> _handleAccept(String bookingId) async {
    try {
      await _apiService.confirmBooking(bookingId);
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request approved! awaiting renter payment.'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
      );
    }
  }

  // Start Trip Action Handler
  Future<void> _handleStartTrip(String bookingId) async {
    try {
      await _apiService.startBooking(bookingId);
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip has started! Drive safely.'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
      );
    }
  }

  // Complete Trip Action Handler
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF103B66)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Track Booking',
          style: TextStyle(color: Color(0xFF103B66), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _bookingFuture,
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
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text('Failed to load tracking data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    OutlinedButton(onPressed: _refresh, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final booking = snapshot.data ?? {};
          final vehicle = booking['vehicle'] as Map<String, dynamic>? ?? {};
          final brand = vehicle['brand']?.toString() ?? 'Vehicle';
          final model = vehicle['model']?.toString() ?? '';
          final images = (vehicle['images'] as List<dynamic>?) ?? [];
          final imageUrl = images.isNotEmpty ? images.first.toString() : '';
          
          final rawStart = DateTime.tryParse(booking['start_date'] ?? '') ?? DateTime.now();
          final rawEnd = DateTime.tryParse(booking['end_date'] ?? '') ?? DateTime.now();
          final startCal = DateTime(rawStart.year, rawStart.month, rawStart.day);
          final endCal = DateTime(rawEnd.year, rawEnd.month, rawEnd.day);
          final diff = endCal.difference(startCal).inDays;
          final int computedDays = diff <= 0 ? 1 : diff;
          final double pricePerDay = (vehicle['price_per_day'] ?? 0).toDouble();
          final double displayPrice = computedDays * pricePerDay;

          final status = booking['status']?.toString().toLowerCase() ?? 'pending';
          final paymentStatus = booking['payment_status']?.toString().toLowerCase() ?? 'unpaid';

          final currentUserId = AuthService.currentUser?['id']?.toString() ?? '';
          final ownerId = vehicle['owner_id']?.toString() ?? '';
          final renterId = booking['renter_id']?.toString() ?? '';
          final isOwner = currentUserId == ownerId;

          // Track states: requested, accepted, paid, active, completed
          bool requested = true;
          bool accepted = status == 'confirmed' || status == 'active' || status == 'completed';
          bool paid = paymentStatus == 'paid' && accepted;
          bool active = status == 'active' || status == 'completed';
          bool completed = status == 'completed';
          bool cancelled = status == 'cancelled';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Mini Car Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, width: 85, height: 60, fit: BoxFit.cover)
                            : Container(
                                width: 85,
                                height: 60,
                                color: const Color(0xFFEAF2FF),
                                child: const Icon(Icons.directions_car, color: AppColors.primary),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$brand $model',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF103B66)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDate(booking['start_date'])} - ${_formatDate(booking['end_date'])} ($computedDays ${computedDays == 1 ? 'Day' : 'Days'})',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Total: ₹${displayPrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Cancellation block if cancelled
                if (cancelled) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE8E6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Booking Cancelled',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reason: ${booking['cancellation_reason'] ?? 'Cancelled by user.'}',
                          style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                        ),
                        if (booking['cancelled_at'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Cancelled on ${_formatDateTime(booking['cancelled_at'])}',
                            style: TextStyle(fontSize: 11, color: Colors.red.shade400),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. Stepper Timeline (Flipkart style)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      _buildStepNode(
                        title: 'Request Placed',
                        subtitle: 'Renter submitted the reservation request.',
                        isDone: requested,
                        isActive: status == 'pending',
                        isLast: false,
                        timestamp: _formatDateTime(booking['created_at']),
                      ),
                      _buildStepNode(
                        title: 'Approved by Owner',
                        subtitle: accepted 
                            ? 'Owner approved the request.'
                            : 'Awaiting owner approval.',
                        isDone: accepted,
                        isActive: status == 'pending',
                        isLast: false,
                        timestamp: accepted ? _formatDateTime(booking['updated_at']) : null,
                      ),
                      _buildStepNode(
                        title: 'Payment Confirmed',
                        subtitle: paid
                            ? 'Payment completed securely.'
                            : accepted
                                ? 'Awaiting renter payment.'
                                : 'Pending owner approval.',
                        isDone: paid,
                        isActive: accepted && !paid,
                        isLast: false,
                        timestamp: paid ? _formatDateTime(booking['updated_at']) : null,
                      ),
                      _buildStepNode(
                        title: 'Trip Started',
                        subtitle: active
                            ? 'Trip is currently in progress.'
                            : 'Pending key handoff.',
                        isDone: active,
                        isActive: paid && !active,
                        isLast: false,
                        timestamp: active ? _formatDateTime(booking['updated_at']) : null,
                      ),
                      _buildStepNode(
                        title: 'Trip Completed',
                        subtitle: completed
                            ? 'Car returned and trip finalized.'
                            : 'Pending rental return.',
                        isDone: completed,
                        isActive: active && !completed,
                        isLast: true,
                        timestamp: completed ? _formatDateTime(booking['updated_at']) : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 4. Interactive Action Section
                if (status == 'pending' && isOwner) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleDecline(booking['id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Decline Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _handleAccept(booking['id']),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Accept Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ] else if (status == 'confirmed' && paymentStatus == 'unpaid' && !isOwner) ...[
                  FilledButton.icon(
                    onPressed: () async {
                      final carModel = CarModel.fromJson(vehicle);
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
                      _refresh();
                    },
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ] else if (status == 'confirmed' && paymentStatus == 'paid' && isOwner) ...[
                  FilledButton.icon(
                    onPressed: () => _handleStartTrip(booking['id']),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ] else if (status == 'active' && isOwner) ...[
                  FilledButton.icon(
                    onPressed: () => _handleCompleteTrip(booking['id']),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Complete Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ] else ...[
                  const SizedBox.shrink(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
