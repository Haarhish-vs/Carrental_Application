import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/services/auth_service.dart';
import '../../../owner/data/services/car_api_service.dart';
import '../../models/car_model.dart';
import 'payment_screen.dart';
import '../widgets/rating_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BookingTrackingScreen extends StatefulWidget {
  const BookingTrackingScreen({
    super.key,
    required this.booking,
    this.isOwnerView,
  });

  final Map<String, dynamic> booking;
  final bool? isOwnerView;

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen> {
  final CarApiService _apiService = CarApiService();
  late Future<Map<String, dynamic>> _bookingFuture;

  bool _imagesUploaded = false;
  bool _isLoadingImages = false;
  bool _demoTripStarted = false;
  bool _demoTripCompleted = false;
  final _storage = const FlutterSecureStorage();

  Timer? _realtimeTimer;
  final MapController _mapController = MapController();
  Map<String, dynamic>? _latestBookingData;

  @override
  void initState() {
    super.initState();
    _refresh();
    _checkImagesUploaded();
    _startRealtimeTrackingTimer();
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    LocationTrackingService().stopTracking();
    super.dispose();
  }

  void _startRealtimeTrackingTimer() {
    _realtimeTimer?.cancel();
    _realtimeTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final bookingId = widget.booking['id']?.toString() ?? '';
      if (bookingId.isEmpty || !mounted) return;
      try {
        final updatedData = await _apiService.getBookingById(bookingId);
        if (mounted) {
          setState(() {
            _latestBookingData = updatedData;
          });
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching realtime tracking update: $e');
      }
    });
  }

  Future<void> _checkImagesUploaded() async {
    final value = await _storage.read(key: 'images_uploaded_${widget.booking['id']}');
    if (mounted && value == 'true') {
      setState(() {
        _imagesUploaded = true;
      });
    }
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

  // Upload Images Action Handler
  Future<void> _handleUploadImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isEmpty) return;
      
      if (images.length != 4) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select exactly 4 images of the car.'), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() {
        _isLoadingImages = true;
      });

      // Upload to Cloudinary using existing API
      await _apiService.uploadFiles(images, (progress) {});

      // Mark as uploaded
      await _storage.write(key: 'images_uploaded_${widget.booking['id']}', value: 'true');
      
      if (mounted) {
        setState(() {
          _imagesUploaded = true;
          _isLoadingImages = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Images uploaded successfully!'), backgroundColor: AppColors.success),
        );
        
        // Removed automated demo flow. Now relies on exact time and backend states.
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingImages = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading images: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildUploadImagesStep({
    required bool isDone,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isDone ? Icons.check_circle_rounded : (isActive ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
              color: isDone ? AppColors.success : (isActive ? AppColors.primary : Colors.grey.shade300),
              size: 24,
            ),
            Container(
              width: 2.5,
              height: 90,
              color: isDone ? AppColors.success : Colors.grey.shade200,
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GestureDetector(
            onTap: isActive && !isDone ? onTap : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDone ? AppColors.success.withOpacity(0.05) : (isActive ? const Color(0xFFF4F8FF) : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDone ? AppColors.success.withOpacity(0.3) : (isActive ? const Color(0xFFD6E4FF) : Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.success.withOpacity(0.1) : (isActive ? Colors.white : Colors.grey.shade100),
                      shape: BoxShape.circle,
                    ),
                    child: _isLoadingImages 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(
                            isDone ? Icons.check : Icons.cloud_upload_outlined,
                            color: isDone ? AppColors.success : (isActive ? AppColors.primary : Colors.grey.shade400),
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDone ? 'Images Uploaded' : 'Upload car images',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: isDone ? AppColors.success : (isActive ? const Color(0xFF103B66) : Colors.grey.shade500),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isDone 
                              ? '4 images have been uploaded to Cloudinary.'
                              : 'Tap to take a photo or choose multiple images from the gallery.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDone ? AppColors.success.withOpacity(0.8) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMapCard(Map<String, dynamic> rawBooking) {
    final booking = _latestBookingData ?? rawBooking;
    final lat = double.tryParse(booking['current_lat']?.toString() ?? '');
    final lng = double.tryParse(booking['current_lng']?.toString() ?? '');
    final vehicle = booking['vehicle'] as Map<String, dynamic>?;
    final vehicleLat = double.tryParse(vehicle?['location_lat']?.toString() ?? '');
    final vehicleLng = double.tryParse(vehicle?['location_lng']?.toString() ?? '');

    final targetLat = lat ?? vehicleLat ?? 13.0827; // Default lat
    final targetLng = lng ?? vehicleLng ?? 80.2707; // Default lng
    final centerPoint = LatLng(targetLat, targetLng);

    final String lastTracked = booking['last_tracked_at'] != null
        ? _formatDateTime(booking['last_tracked_at'].toString())
        : 'Live GPS Active';

    final brand = vehicle?['brand']?.toString() ?? 'Vehicle';
    final model = vehicle?['model']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Owner Live GPS Tracking',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      '$brand $model',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, color: AppColors.success, size: 8),
                    SizedBox(width: 5),
                    Text('REALTIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last updated: $lastTracked',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              if (lat != null && lng != null)
                Text(
                  '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: centerPoint,
                      initialZoom: 14.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.car_rental_app_client_side',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: centerPoint,
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.25),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
                                  ),
                                  child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'recenter_map',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      tooltip: 'Recenter Map',
                      onPressed: () {
                        _mapController.move(centerPoint, 15.0);
                      },
                      child: const Icon(Icons.center_focus_strong),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerRatingDialog(String carId) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        carId: carId,
        bookingId: widget.booking['id']?.toString() ?? '',
        onSubmitted: () {
          _refresh();
        },
      ),
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
      LocationTrackingService().startTracking(bookingId);
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
      LocationTrackingService().stopTracking();
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
          final isOwner = widget.isOwnerView ?? (currentUserId.isNotEmpty && currentUserId == ownerId);

          if (!isOwner && (status == 'active' || status == 'confirmed')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              LocationTrackingService().startTracking(booking['id']?.toString() ?? '');
            });
          }

          final now = DateTime.now();
          final bool isPickupReached = now.isAfter(rawStart);
          final bool isDropoffReached = now.isAfter(rawEnd);

          // Track states: requested, accepted, paid, active, completed
          bool requested = true;
          bool accepted = status == 'confirmed' || status == 'active' || status == 'completed';
          bool paid = paymentStatus == 'paid' && accepted;
          bool active = status == 'active' || status == 'completed';
          bool completed = status == 'completed' || (active && isDropoffReached);
          bool cancelled = status == 'cancelled';
          
          bool tripStartedGreen = isOwner ? active : (paid && _imagesUploaded);

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
                            ? CachedNetworkImage(
                                imageUrl: imageUrl, 
                                width: 85, 
                                height: 60, 
                                fit: BoxFit.cover,
                                memCacheHeight: 200,
                                placeholder: (context, url) => Container(
                                  width: 85,
                                  height: 60,
                                  color: const Color(0xFFEAF2FF),
                                  child: const Center(
                                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 85,
                                  height: 60,
                                  color: const Color(0xFFEAF2FF),
                                  child: const Icon(Icons.directions_car, color: AppColors.primary),
                                ),
                              )
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

                // 2.5. Live Vehicle Location Tracking Map Card (ONLY for car owner view on active or confirmed rentals)
                if (isOwner && (status == 'active' || status == 'confirmed')) ...[
                  _buildLiveMapCard(booking),
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
                      if (!isOwner)
                        _buildUploadImagesStep(
                          isDone: _imagesUploaded,
                          isActive: paid && !_imagesUploaded && isPickupReached,
                          onTap: _handleUploadImages,
                        ),
                      _buildStepNode(
                        title: 'Trip Started',
                        subtitle: tripStartedGreen
                            ? 'Trip is currently in progress.'
                            : 'Pending key handoff.',
                        isDone: tripStartedGreen,
                        isActive: paid && (!isOwner ? _imagesUploaded : true) && !active,
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
                ] else if (completed && !isOwner) ...[
                  FilledButton.icon(
                    onPressed: () => _triggerRatingDialog(vehicle['id']?.toString() ?? ''),
                    icon: const Icon(Icons.star_rate_rounded),
                    label: const Text('Leave a Review', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber,
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
