import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../models/car_model.dart';
import 'payment_screen.dart';

class ReserveScreen extends StatefulWidget {
  const ReserveScreen({
    super.key,
    required this.car,
    this.initialPickupDate,
    this.initialReturnDate,
  });

  final CarModel car;
  final DateTime? initialPickupDate;
  final DateTime? initialReturnDate;

  @override
  State<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends State<ReserveScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  DateTime? _pickupDate;
  TimeOfDay? _pickupTime = const TimeOfDay(hour: 10, minute: 0);
  DateTime? _returnDate;
  TimeOfDay? _returnTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _pickupDate = widget.initialPickupDate;
    _returnDate = widget.initialReturnDate;
  }

  int get _rentalDays {
    if (_pickupDate == null || _returnDate == null) return 0;

    // Normalize to midnight to calculate calendar days difference
    final start = DateTime(
      _pickupDate!.year,
      _pickupDate!.month,
      _pickupDate!.day,
    );
    final end = DateTime(
      _returnDate!.year,
      _returnDate!.month,
      _returnDate!.day,
    );

    if (end.isBefore(start)) return 0;

    final diff = end.difference(start).inDays;
    // Same day = 1 day rental; each extra day = +1
    return diff == 0 ? 1 : diff;
  }

  double get _totalAmount {
    final days = _rentalDays;
    if (days <= 0) return 0;
    return days * widget.car.pricePerDay;
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[date.month - 1]} ${date.day}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _specItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isPickup,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPickup
          ? (_pickupDate ?? DateTime.now())
          : (_returnDate ?? DateTime.now().add(const Duration(days: 1))),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
          if (_returnDate != null && _returnDate!.isBefore(picked)) {
            _returnDate = picked.add(const Duration(days: 1));
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(
    BuildContext context, {
    required bool isPickup,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isPickup
          ? (_pickupTime ?? const TimeOfDay(hour: 10, minute: 0))
          : (_returnTime ?? const TimeOfDay(hour: 18, minute: 0)),
    );

    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupTime = picked;
        } else {
          _returnTime = picked;
        }
      });
    }
  }

  Widget _buildStepNode(
    int stepNum,
    String title,
    bool isCompleted,
    bool isActive,
  ) {
    return Column(
      children: [
        if (isCompleted)
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 24,
          )
        else if (isActive)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Center(
              child: Text(
                '$stepNum',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
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
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isCompleted
                ? FontWeight.w600
                : FontWeight.w400,
            color: isActive || isCompleted
                ? AppColors.textPrimary
                : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector() {
    return Expanded(
      child: Container(
        height: 2.5,
        color: AppColors.success.withOpacity(0.8),
        margin: const EdgeInsets.only(bottom: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.car.images.isNotEmpty
        ? widget.car.images.take(4).toList()
        : (widget.car.imageUrl.isNotEmpty ? [widget.car.imageUrl] : []);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reservation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Booking Progress Timeline (Steps 1 to 5)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  _buildStepNode(1, 'Vehicle', true, false),
                  _buildStepConnector(),
                  _buildStepNode(2, 'Pickup', true, false),
                  _buildStepConnector(),
                  _buildStepNode(3, 'Extras', true, false),
                  _buildStepConnector(),
                  _buildStepNode(4, 'Payment', false, true),
                  Expanded(
                    child: Container(
                      height: 2.5,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.only(bottom: 22),
                    ),
                  ),
                  _buildStepNode(5, 'Confirmed', false, false),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Car Card (Carousel & Info side-by-side)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.03),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Carousel & Dot indicators on the left
                        if (images.isNotEmpty)
                          SizedBox(
                            width: 110,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 110,
                                  height: 80,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
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
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                color: const Color(0xFFEAF2FF),
                                                child: const Icon(
                                                  Icons.directions_car_rounded,
                                                  size: 24,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (images.length > 1)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      images.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        width: _currentImageIndex == index
                                            ? 8
                                            : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                          color: _currentImageIndex == index
                                              ? AppColors.primary
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: 110,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_car_rounded,
                              size: 36,
                              color: AppColors.primary,
                            ),
                          ),
                        const SizedBox(width: 14),

                        // Info on the right
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.car.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.car.fuelType} - ${widget.car.transmission}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.car.rating.toStringAsFixed(1)} (128 trips)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Date & Time Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.03),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Date & Time',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Connecting timeline line on the left
                            Column(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 1.5,
                                  height: 48,
                                  color: Colors.grey.shade300,
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Inputs on the right
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Pickup row
                                  GestureDetector(
                                    onTap: () async {
                                      await _selectDate(
                                        context,
                                        isPickup: true,
                                      );
                                      if (mounted)
                                        await _selectTime(
                                          context,
                                          isPickup: true,
                                        );
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'PICKUP',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _pickupDate != null
                                                  ? '${_formatDate(_pickupDate!)}, ${_formatTime(_pickupTime!)}'
                                                  : 'Select Pickup Date',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: _pickupDate != null
                                                    ? AppColors.textPrimary
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Colors.grey.shade500,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Return row
                                  GestureDetector(
                                    onTap: () async {
                                      await _selectDate(
                                        context,
                                        isPickup: false,
                                      );
                                      if (mounted)
                                        await _selectTime(
                                          context,
                                          isPickup: false,
                                        );
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'RETURN',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _returnDate != null
                                                  ? '${_formatDate(_returnDate!)}, ${_formatTime(_returnTime!)}'
                                                  : 'Select Return Date',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: _returnDate != null
                                                    ? AppColors.textPrimary
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: Colors.grey.shade500,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 5. Specifications Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.03),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Specifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _specItem('Transmission', widget.car.transmission),
                            _specItem('Fuel', widget.car.fuelType),
                            _specItem('Seats', '${widget.car.seats}'),
                            _specItem('Rating', '${widget.car.rating} ★'),
                          ],
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

      // 5. Sticky Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: FilledButton(
                onPressed: _rentalDays > 0
                    ? () async {
                        // Auth guard
                        if (!AuthService.isAuthenticated) {
                          final loggedIn = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => const AuthScreen(
                                    initialMode: AuthMode.login,
                                  ),
                                ),
                              );
                          if (loggedIn != true || !context.mounted) return;
                        }
                        if (!context.mounted) return;

                        final pickupDateTime = DateTime(
                          _pickupDate!.year,
                          _pickupDate!.month,
                          _pickupDate!.day,
                          _pickupTime?.hour ?? 10,
                          _pickupTime?.minute ?? 0,
                        );
                        final returnDateTime = DateTime(
                          _returnDate!.year,
                          _returnDate!.month,
                          _returnDate!.day,
                          _returnTime?.hour ?? 18,
                          _returnTime?.minute ?? 0,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              car: widget.car,
                              pickupDateTime: pickupDateTime,
                              returnDateTime: returnDateTime,
                              days: _rentalDays,
                              totalAmount: _totalAmount,
                            ),
                          ),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: AppColors.primary,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
