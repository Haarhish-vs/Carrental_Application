import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/error_handling/app_error_handler.dart';
import '../../../owner/data/services/car_api_service.dart';

class RatingDialog extends StatefulWidget {
  final String carId;
  final String bookingId;
  final VoidCallback onSubmitted;

  const RatingDialog({
    super.key,
    required this.carId,
    required this.bookingId,
    required this.onSubmitted,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _selectedStars = 5;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  void _submitReview() async {
    if (_feedbackController.text.trim().isEmpty) {
      AppErrorHandler.showInfo(context, 'Please provide some feedback before submitting.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await CarApiService().submitReview(
        vehicleId: widget.carId,
        bookingId: widget.bookingId,
        rating: _selectedStars.toDouble(),
        feedback: _feedbackController.text.trim(),
      );
      
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      Navigator.of(context).pop();
      widget.onSubmitted();
      
      AppErrorHandler.showSuccess(context, 'Thank you for your feedback!');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      AppErrorHandler.show(context, e);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.rating, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Rate Your Trip',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How was your experience with this car?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedStars = index + 1;
                    });
                  },
                  icon: Icon(
                    index < _selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < _selectedStars ? AppColors.rating : Colors.grey.shade300,
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share details of your experience...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
