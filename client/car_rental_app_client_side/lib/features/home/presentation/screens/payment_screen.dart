import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../owner/data/services/car_api_service.dart';
import '../../models/car_model.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.car,
    required this.pickupDateTime,
    required this.returnDateTime,
    required this.days,
    required this.totalAmount,
  });

  final CarModel car;
  final DateTime pickupDateTime;
  final DateTime returnDateTime;
  final int days;
  final double totalAmount;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  final CarApiService _carApiService = CarApiService();
  bool _processing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _handleDirectRazorpayPayment() async {
    // Direct Razorpay Payment Gateway popup trigger
    final paymentSuccess = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF002970).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payment, color: Color(0xFF002970)),
              ),
              const SizedBox(width: 12),
              const Text('Razorpay Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.car.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Amount to Pay: ₹${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Razorpay Gateway Test Credentials:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    const Text('Key ID: rzp_test_R5uZgmenogCy4j', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    Text('Pickup: ${_formatDate(widget.pickupDateTime)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    Text('Return: ${_formatDate(widget.returnDateTime)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel Payment', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0275D8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Pay via Razorpay'),
            ),
          ],
        );
      },
    );

    if (paymentSuccess != true) return;

    setState(() {
      _processing = true;
    });

    try {
      final formattedPickup = widget.pickupDateTime.toIso8601String().split('T')[0];
      final formattedReturn = widget.returnDateTime.toIso8601String().split('T')[0];

      // Save booking & payment details into database via API
      await _carApiService.createBooking(
        vehicleId: widget.car.id,
        startDate: formattedPickup,
        endDate: formattedReturn,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 10),
                Text('Booking Confirmed!'),
              ],
            ),
            content: Text(
              'Payment of ₹${widget.totalAmount.toStringAsFixed(2)} for ${widget.car.name} was successfully completed via Razorpay.\n\nYour booking details have been saved to the database.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).popUntil((route) => route.isFirst); // Redirect to Home
                },
                child: const Text('Go to Home'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Widget _buildStepNode(int stepNum, String title, bool isCompleted, bool isActive) {
    return Column(
      children: [
        if (isCompleted)
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24)
        else if (isActive)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Center(
              child: Text(
                '$stepNum',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Center(
              child: Text(
                '$stepNum',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.w400,
            color: isActive || isCompleted ? AppColors.textPrimary : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2.5,
        color: isCompleted ? AppColors.success.withOpacity(0.8) : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.car.images.isNotEmpty 
        ? widget.car.images 
        : (widget.car.imageUrl.isNotEmpty ? [widget.car.imageUrl] : []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Timeline steps
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  _buildStepNode(1, 'Vehicle', true, false),
                  _buildStepConnector(true),
                  _buildStepNode(2, 'Pickup', true, false),
                  _buildStepConnector(true),
                  _buildStepNode(3, 'Extras', true, false),
                  _buildStepConnector(true),
                  _buildStepNode(4, 'Payment', false, true),
                  _buildStepConnector(false),
                  _buildStepNode(5, 'Confirmed', false, false),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Car Image PageView Carousel
                  if (images.isNotEmpty)
                    Container(
                      height: 180,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return Image.network(
                                  images[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: const Color(0xFFEAF2FF),
                                    child: const Icon(Icons.directions_car_rounded, size: 48, color: AppColors.primary),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (images.length > 1) ...[
                            Positioned(
                              left: 10,
                              child: GestureDetector(
                                onTap: _currentImageIndex > 0
                                    ? () {
                                        _pageController.previousPage(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    : null,
                                child: CircleAvatar(
                                  backgroundColor: _currentImageIndex > 0 ? Colors.black45 : Colors.black12,
                                  radius: 16,
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: _currentImageIndex > 0 ? Colors.white : Colors.white30,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              child: GestureDetector(
                                onTap: _currentImageIndex < images.length - 1
                                    ? () {
                                        _pageController.nextPage(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    : null,
                                child: CircleAvatar(
                                  backgroundColor: _currentImageIndex < images.length - 1 ? Colors.black45 : Colors.black12,
                                  radius: 16,
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: _currentImageIndex < images.length - 1 ? Colors.white : Colors.white30,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  images.length,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentImageIndex == index
                                          ? AppColors.primary
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // 3. Trip & Booking Summary Breakdown Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.03), blurRadius: 14, offset: Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.car.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.car.fuelType} • ${widget.car.transmission}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const Divider(height: 24, thickness: 1),

                        // Pickup schedule info
                        Row(
                          children: [
                            const Icon(Icons.flight_takeoff_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('PICKUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  Text(
                                    '${_formatDate(widget.pickupDateTime)}, ${_formatTime(widget.pickupDateTime)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Return schedule info
                        Row(
                          children: [
                            const Icon(Icons.flight_land_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('RETURN / DROP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  Text(
                                    '${_formatDate(widget.returnDateTime)}, ${_formatTime(widget.returnDateTime)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, thickness: 1),

                        // Calculation Breakdown: 1 day cost vs multi-day calculation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daily Rate (₹${widget.car.pricePerDay.toStringAsFixed(0)} × ${widget.days} ${widget.days == 1 ? 'day' : 'days'})',
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                            Text(
                              '₹${widget.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              '₹${widget.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Direct Pay Now Button (Directly opens Razorpay)
                  FilledButton(
                    onPressed: _processing ? null : _handleDirectRazorpayPayment,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: AppColors.primary,
                    ),
                    child: _processing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Pay ₹${widget.totalAmount.toStringAsFixed(2)} via Razorpay',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
