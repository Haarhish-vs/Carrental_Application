import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';

const List<String> rentCarStepTitles = <String>[
  'Car Specifications',
  'Pricing & Availability',
  'Car Images',
  'Documents',
];

Route<T> buildRentCarSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0.14, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

class RentCarDraft {
  const RentCarDraft({
    this.brand = '',
    this.model = '',
    this.variant = '',
    this.manufacturingYear = '',
    this.registrationNumber = '',
    this.fuelType = '',
    this.transmission = '',
    this.mileage = '',
    this.seatingCapacity = '',
    this.color = '',
    this.engineCapacity = '',
    this.odometerReading = '',
    this.vehicleDescription = '',
    this.dailyPrice = '',
    this.securityDeposit = '',
    this.minimumRentalDays = '',
    this.pickupLocation = '',
    this.availabilityFrom = '',
    this.availabilityTo = '',
    this.deliveryFee = '',
    this.selectedPhotos = const <String>[],
    this.selectedDocuments = const <String>[],
    this.localPhotos = const <XFile>[],
    this.localDocuments = const <String, XFile>{},
  });

  final String brand;
  final String model;
  final String variant;
  final String manufacturingYear;
  final String registrationNumber;
  final String fuelType;
  final String transmission;
  final String mileage;
  final String seatingCapacity;
  final String color;
  final String engineCapacity;
  final String odometerReading;
  final String vehicleDescription;
  final String dailyPrice;
  final String securityDeposit;
  final String minimumRentalDays;
  final String pickupLocation;
  final String availabilityFrom;
  final String availabilityTo;
  final String deliveryFee;
  final List<String> selectedPhotos;
  final List<String> selectedDocuments;
  final List<XFile> localPhotos;
  final Map<String, XFile> localDocuments;

  RentCarDraft copyWith({
    String? brand,
    String? model,
    String? variant,
    String? manufacturingYear,
    String? registrationNumber,
    String? fuelType,
    String? transmission,
    String? mileage,
    String? seatingCapacity,
    String? color,
    String? engineCapacity,
    String? odometerReading,
    String? vehicleDescription,
    String? dailyPrice,
    String? securityDeposit,
    String? minimumRentalDays,
    String? pickupLocation,
    String? availabilityFrom,
    String? availabilityTo,
    String? deliveryFee,
    List<String>? selectedPhotos,
    List<String>? selectedDocuments,
    List<XFile>? localPhotos,
    Map<String, XFile>? localDocuments,
  }) {
    return RentCarDraft(
      brand: brand ?? this.brand,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      manufacturingYear: manufacturingYear ?? this.manufacturingYear,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      mileage: mileage ?? this.mileage,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      color: color ?? this.color,
      engineCapacity: engineCapacity ?? this.engineCapacity,
      odometerReading: odometerReading ?? this.odometerReading,
      vehicleDescription: vehicleDescription ?? this.vehicleDescription,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      minimumRentalDays: minimumRentalDays ?? this.minimumRentalDays,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      availabilityFrom: availabilityFrom ?? this.availabilityFrom,
      availabilityTo: availabilityTo ?? this.availabilityTo,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
      selectedDocuments: selectedDocuments ?? this.selectedDocuments,
      localPhotos: localPhotos ?? this.localPhotos,
      localDocuments: localDocuments ?? this.localDocuments,
    );
  }
}

class RentCarScreenScaffold extends StatelessWidget {
  const RentCarScreenScaffold({
    super.key,
    required this.currentStep,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.onNext,
    this.nextLabel = 'Next',
    this.backLabel = 'Back',
    this.isLastStep = false,
  });

  final int currentStep;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final String backLabel;
  final bool isLastStep;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Rent Out Your Car'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF103B66),
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepHeader(currentStep: currentStep),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF103B66),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF57718A),
                ),
              ),
              const SizedBox(height: 20),
              child,
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(backLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onNext,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(nextLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: currentStep / rentCarStepTitles.length,
                      backgroundColor: const Color(0xFFE5EEF8),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$currentStep/${rentCarStepTitles.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF103B66),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.generate(rentCarStepTitles.length, (
                index,
              ) {
                final isActive = index + 1 == currentStep;
                final isDone = index + 1 < currentStep;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colorScheme.primary
                        : isDone
                        ? const Color(0xFFE6F0FF)
                        : const Color(0xFFF5F8FC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive
                          ? colorScheme.primary
                          : const Color(0xFFD9E4F1),
                    ),
                  ),
                  child: Text(
                    rentCarStepTitles[index],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isActive ? Colors.white : const Color(0xFF103B66),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class RentCarSectionCard extends StatelessWidget {
  const RentCarSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: const Color(0xFF1E5AA8)),
              const SizedBox(height: 12),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF103B66),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class RentCarToggleTile extends StatelessWidget {
  const RentCarToggleTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? const Color(0xFFEAF2FF) : const Color(0xFFF7FAFD),
          border: Border.all(
            color: selected ? colorScheme.primary : const Color(0xFFDDE6F2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? colorScheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF1E5AA8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF103B66),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF62778F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.add_circle_outline,
              color: selected ? colorScheme.primary : const Color(0xFF9AAEC4),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration rentCarInputDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  IconData? icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF7FAFD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD7E2EF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD7E2EF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 1.4,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE06B6B)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE06B6B), width: 1.4),
    ),
  );
}

class RentCarTextField extends StatelessWidget {
  const RentCarTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      textInputAction: textInputAction,
      decoration: rentCarInputDecoration(
        context,
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }
}

class RentCarDropdownField<T> extends StatelessWidget {
  const RentCarDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
    this.hint,
    this.validator,
  });

  final String label;
  final T? value;
  final List<T> options;
  final ValueChanged<T?> onChanged;
  final IconData? icon;
  final String? hint;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option,
              child: Text(option.toString()),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: rentCarInputDecoration(
        context,
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }
}
