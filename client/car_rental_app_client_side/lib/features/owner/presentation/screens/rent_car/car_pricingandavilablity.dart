import 'package:flutter/material.dart';
import 'package:car_rental_app_client_side/features/owner/data/services/car_api_service.dart';

import 'car_images.dart';
import 'rent_car_shared.dart';

class CarPricingAndAvailabilityScreen extends StatefulWidget {
  const CarPricingAndAvailabilityScreen({super.key, required this.draft});

  final RentCarDraft draft;

  @override
  State<CarPricingAndAvailabilityScreen> createState() =>
      _CarPricingAndAvailabilityScreenState();
}

class _CarPricingAndAvailabilityScreenState
    extends State<CarPricingAndAvailabilityScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _dailyPriceController;
  late final TextEditingController _securityDepositController;
  late final TextEditingController _pickupLocationController;
  late final TextEditingController _availabilityFromController;
  late final TextEditingController _availabilityToController;
  late final TextEditingController _deliveryFeeController;

  @override
  void initState() {
    super.initState();
    _dailyPriceController = TextEditingController(
      text: widget.draft.dailyPrice,
    );
    _securityDepositController = TextEditingController(
      text: widget.draft.securityDeposit,
    );
    _pickupLocationController = TextEditingController(
      text: widget.draft.pickupLocation,
    );
    _availabilityFromController = TextEditingController(
      text: widget.draft.availabilityFrom,
    );
    _availabilityToController = TextEditingController(
      text: widget.draft.availabilityTo,
    );
    _deliveryFeeController = TextEditingController(
      text: widget.draft.deliveryFee,
    );
  }

  @override
  void dispose() {
    _dailyPriceController.dispose();
    _securityDepositController.dispose();
    _pickupLocationController.dispose();
    _availabilityFromController.dispose();
    _availabilityToController.dispose();
    _deliveryFeeController.dispose();
    super.dispose();
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $label';
    }
    return null;
  }

  String? _numericValidator(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Enter $label';
    }
    if (double.tryParse(text) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF1E5AA8),
              surface: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (selectedDate != null) {
      controller.text = _formatDate(selectedDate);
    }
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  void _goNext() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedDraft = widget.draft.copyWith(
      dailyPrice: _dailyPriceController.text.trim(),
      securityDeposit: _securityDepositController.text.trim(),
      pickupLocation: _pickupLocationController.text.trim(),
      availabilityFrom: _availabilityFromController.text.trim(),
      availabilityTo: _availabilityToController.text.trim(),
      deliveryFee: _deliveryFeeController.text.trim(),
    );

    Navigator.of(context).push(
      buildRentCarSlideRoute(
        CarImagesScreen(
          draft: updatedDraft,
          onUploadRequested: CarApiService().uploadFiles,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: RentCarScreenScaffold(
        currentStep: 2,
        title: 'Pricing & Availability',
        subtitle:
            'Define pricing clearly and set the time window where the car can be rented.',
        onBack: _goBack,
        onNext: _goNext,
        nextLabel: 'Next',
        backLabel: 'Back',
        child: Column(
          children: [
            RentCarSectionCard(
              title: 'Pricing',
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  RentCarTextField(
                    controller: _dailyPriceController,
                    label: 'Daily Price (INR)',
                    hint: 'e.g. ₹ 5,000',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        _numericValidator(value, 'daily price'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  RentCarTextField(
                    controller: _securityDepositController,
                    label: 'Security Deposit (INR)',
                    hint: 'e.g. ₹ 25,000',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        _numericValidator(value, 'security deposit'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  RentCarTextField(
                    controller: _deliveryFeeController,
                    label: 'Delivery Fee (INR)',
                    hint: 'e.g. ₹ 500',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        _numericValidator(value, 'delivery fee'),
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            RentCarSectionCard(
              title: 'Availability',
              icon: Icons.schedule_outlined,
              child: Column(
                children: [
                  RentCarTextField(
                    controller: _pickupLocationController,
                    label: 'Pickup Location',
                    hint: 'e.g. Downtown garage',
                    icon: Icons.location_on_outlined,
                    validator: (value) =>
                        _requiredText(value, 'pickup location'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  RentCarTextField(
                    controller: _availabilityFromController,
                    label: 'Available From',
                    hint: 'YYYY-MM-DD',
                    icon: Icons.date_range_outlined,
                    readOnly: true,
                    onTap: () => _pickDate(_availabilityFromController),
                    validator: (value) =>
                        _requiredText(value, 'available from date'),
                  ),
                  const SizedBox(height: 14),
                  RentCarTextField(
                    controller: _availabilityToController,
                    label: 'Available To',
                    hint: 'YYYY-MM-DD',
                    icon: Icons.event_available_outlined,
                    readOnly: true,
                    onTap: () => _pickDate(_availabilityToController),
                    validator: (value) =>
                        _requiredText(value, 'available to date'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
