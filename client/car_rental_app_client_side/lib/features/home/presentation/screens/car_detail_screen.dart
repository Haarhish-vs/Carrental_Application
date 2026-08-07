import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../owner/data/services/car_api_service.dart';
import '../../models/car_model.dart';

class CarDetailScreen extends StatefulWidget {
  const CarDetailScreen({super.key, required this.car});

  final CarModel car;

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  final CarApiService _carApiService = CarApiService();
  DateTime? _pickupDate;
  DateTime? _returnDate;
  double _totalAmount = 0.0;
  bool _processingPayment = false;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _selectDate({required bool isPickup}) async {
    final initialDate = isPickup ? DateTime.now() : (_pickupDate ?? DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (isPickup) {
        _pickupDate = selected;
        if (_returnDate != null && _returnDate!.isBefore(selected)) {
          _returnDate = null;
        }
      } else {
        _returnDate = selected;
      }
      _updateTotal();
    });
  }

  void _updateTotal() {
    if (_pickupDate == null || _returnDate == null) {
      _totalAmount = 0.0;
      return;
    }

    final days = _returnDate!.difference(_pickupDate!).inDays + 1;
    if (days <= 0) {
      _totalAmount = 0.0;
      return;
    }
    _totalAmount = days * widget.car.pricePerDay;
  }

  Future<void> _handlePayNow() async {
    if (_pickupDate == null || _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both pickup and return dates.')),
      );
      return;
    }

    if (_returnDate!.isBefore(_pickupDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return date must be after pickup date.')),
      );
      return;
    }

    if (!AuthService.isAuthenticated) {
      final authSuccess = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (authSuccess != true || !mounted) {
        return;
      }
    }

    setState(() {
      _processingPayment = true;
    });

    try {
      final startDate = _pickupDate!.toIso8601String().split('T').first;
      final endDate = _returnDate!.toIso8601String().split('T').first;

      await _carApiService.createBooking(
        vehicleId: widget.car.id,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Payment Complete'),
            content: Text(
              'Your booking for ${widget.car.name} has been confirmed. Total paid: ₹${_totalAmount.toStringAsFixed(0)}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _processingPayment = false;
      });
    }
  }

  Widget _buildDetailTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (car.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    car.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 220,
                      color: const Color(0xFFEAF2FF),
                      child: const Icon(Icons.directions_car_rounded, size: 56, color: AppColors.primary),
                    ),
                  ),
                )
              else
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.directions_car_rounded, size: 56, color: AppColors.primary),
                ),
              const SizedBox(height: 18),
              Text(car.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(car.city, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 18, color: AppColors.rating),
                  const SizedBox(width: 6),
                  Text(car.rating.toStringAsFixed(1), style: const TextStyle(color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    const BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.03), blurRadius: 14, offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailTile('Transmission', car.transmission),
                    _buildDetailTile('Fuel Type', car.fuelType),
                    _buildDetailTile('Seats', '${car.seats}'),
                    _buildDetailTile('Price/Day', '₹${car.pricePerDay.toStringAsFixed(0)}'),
                    _buildDetailTile('Status', car.status),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Choose Dates', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(isPickup: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Column(
                        children: [
                          const Text('Pickup Date', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Text(
                            _pickupDate != null ? _formatDate(_pickupDate!) : 'Select',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickupDate == null ? null : () => _selectDate(isPickup: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Column(
                        children: [
                          const Text('Return Date', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Text(
                            _returnDate != null ? _formatDate(_returnDate!) : 'Select',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    const BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.03), blurRadius: 14, offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildDetailTile('Days', _pickupDate != null && _returnDate != null && !_returnDate!.isBefore(_pickupDate!) ? '${_returnDate!.difference(_pickupDate!).inDays + 1}' : '0'),
                    _buildDetailTile('Total Amount', _totalAmount > 0 ? '₹${_totalAmount.toStringAsFixed(0)}' : '₹0'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _processingPayment ? null : _handlePayNow,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _processingPayment
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Pay Now', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
