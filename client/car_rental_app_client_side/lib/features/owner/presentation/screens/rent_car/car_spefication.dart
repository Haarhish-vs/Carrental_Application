import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'car_pricingandavilablity.dart';
import 'rent_car_shared.dart';

class CarSpecificationScreen extends StatefulWidget {
  const CarSpecificationScreen({super.key, this.draft = const RentCarDraft()});

  final RentCarDraft draft;

  @override
  State<CarSpecificationScreen> createState() => _CarSpecificationScreenState();
}

class _CarSpecificationScreenState extends State<CarSpecificationScreen> {
  static const List<String> _fuelTypes = <String>[
    'Petrol',
    'Diesel',
    'Hybrid',
    'Electric',
    'CNG',
  ];
  static const List<String> _transmissions = <String>['Manual', 'Automatic'];
  static const double _fieldGap = 14;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _variantController;
  late final TextEditingController _yearController;
  late final TextEditingController _registrationController;
  late final TextEditingController _mileageController;
  late final TextEditingController _seatingController;
  late final TextEditingController _colorController;
  late final TextEditingController _engineController;
  late final TextEditingController _odometerController;
  late final TextEditingController _descriptionController;

  String? _fuelType;
  String? _transmission;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.draft.brand);
    _modelController = TextEditingController(text: widget.draft.model);
    _variantController = TextEditingController(text: widget.draft.variant);
    _yearController = TextEditingController(
      text: widget.draft.manufacturingYear,
    );
    _registrationController = TextEditingController(
      text: widget.draft.registrationNumber,
    );
    _mileageController = TextEditingController(text: widget.draft.mileage);
    _seatingController = TextEditingController(
      text: widget.draft.seatingCapacity,
    );
    _colorController = TextEditingController(text: widget.draft.color);
    _engineController = TextEditingController(
      text: widget.draft.engineCapacity,
    );
    _odometerController = TextEditingController(
      text: widget.draft.odometerReading,
    );
    _descriptionController = TextEditingController(
      text: widget.draft.vehicleDescription,
    );
    _fuelType = widget.draft.fuelType.isEmpty ? null : widget.draft.fuelType;
    _transmission = widget.draft.transmission.isEmpty
        ? null
        : widget.draft.transmission;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _yearController.dispose();
    _registrationController.dispose();
    _mileageController.dispose();
    _seatingController.dispose();
    _colorController.dispose();
    _engineController.dispose();
    _odometerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _requiredText(String? value, String label, {int maxLen = 20}) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $label';
    }
    if (value.trim().length > maxLen) {
      return '$label cannot exceed $maxLen characters';
    }
    return null;
  }

  String? _yearValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Enter manufacturing year';
    }
    final parsed = int.tryParse(text);
    if (parsed == null ||
        text.length != 4 ||
        parsed < 1980 ||
        parsed > DateTime.now().year + 1) {
      return 'Enter a valid year';
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

  Widget _gap() => const SizedBox(height: _fieldGap);

  Widget _sectionField(Widget child) => child;

  Widget _buildVehicleIdentitySection() {
    return RentCarSectionCard(
      title: 'Vehicle Identity',
      icon: Icons.directions_car_rounded,
      child: Column(
        children: [
          _sectionField(
            RentCarTextField(
              controller: _brandController,
              label: 'Brand',
              hint: 'e.g. Toyota',
              icon: Icons.badge_outlined,
              maxLength: 20,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              validator: (value) => _requiredText(value, 'brand'),
              textInputAction: TextInputAction.next,
            ),
          ),
          _gap(),
          _sectionField(
            RentCarTextField(
              controller: _modelController,
              label: 'Model',
              hint: 'e.g. Corolla',
              icon: Icons.directions_car_filled_outlined,
              maxLength: 20,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              validator: (value) => _requiredText(value, 'model'),
              textInputAction: TextInputAction.next,
            ),
          ),
          _gap(),
          _sectionField(
            RentCarTextField(
              controller: _variantController,
              label: 'Variant',
              hint: 'e.g. GX CVT',
              icon: Icons.layers_outlined,
              maxLength: 20,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              validator: (value) => _requiredText(value, 'variant'),
              textInputAction: TextInputAction.next,
            ),
          ),
          _gap(),
          _sectionField(
            RentCarTextField(
              controller: _yearController,
              label: 'Manufacturing Year',
              hint: 'e.g. 2022',
              icon: Icons.event_outlined,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: _yearValidator,
              textInputAction: TextInputAction.next,
            ),
          ),
          _gap(),
          _sectionField(
            RentCarTextField(
              controller: _registrationController,
              label: 'Registration Number',
              hint: 'e.g. KDA-1234',
              icon: Icons.confirmation_number_outlined,
              maxLength: 20,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              validator: (value) => _requiredText(value, 'registration number'),
              textInputAction: TextInputAction.next,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalDetailsSection() {
    return RentCarSectionCard(
      title: 'Technical Details',
      icon: Icons.engineering_outlined,
      child: Column(
        children: [
          _sectionField(
            RentCarDropdownField<String>(
              label: 'Fuel Type',
              value: _fuelType,
              options: _fuelTypes,
              icon: Icons.local_gas_station_outlined,
              validator: (value) => value == null ? 'Select fuel type' : null,
              onChanged: (value) => setState(() => _fuelType = value),
            ),
          ),
          _gap(),
          _sectionField(
            RentCarDropdownField<String>(
              label: 'Transmission',
              value: _transmission,
              options: _transmissions,
              icon: Icons.settings_outlined,
              validator: (value) =>
                  value == null ? 'Select transmission' : null,
              onChanged: (value) => setState(() => _transmission = value),
            ),
          ),
          _gap(),
          _sectionField(
            RentCarTextField(
              controller: _mileageController,
              label: 'Mileage',
              hint: 'e.g. 18.5 km/l',
              icon: Icons.speed_outlined,
              keyboardType: TextInputType.number,
              validator: (value) => _numericValidator(value, 'mileage'),
              textInputAction: TextInputAction.next,
            ),
          ),
          _gap(),
          _sectionField(
            RentCarTextField(
              controller: _seatingController,
              label: 'Seating Capacity',
              hint: 'e.g. 5',
              icon: Icons.event_seat_outlined,
              keyboardType: TextInputType.number,
              validator: (value) =>
                  _numericValidator(value, 'seating capacity'),
              textInputAction: TextInputAction.next,
            ),
          ),
          _gap(),
          _sectionField(
            RentCarTextField(
              controller: _colorController,
              label: 'Color',
              hint: 'e.g. Pearl White',
              icon: Icons.color_lens_outlined,
              maxLength: 20,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              validator: (value) => _requiredText(value, 'color'),
              textInputAction: TextInputAction.next,
            ),
          ),
          _gap(),
          _sectionField(
            RentCarTextField(
              controller: _engineController,
              label: 'Engine Capacity',
              hint: 'e.g. 1500 cc',
              icon: Icons.precision_manufacturing_outlined,
              keyboardType: TextInputType.number,
              validator: (value) => _numericValidator(value, 'engine capacity'),
              textInputAction: TextInputAction.next,
            ),
          ),
          _gap(),
          _sectionField(
            RentCarTextField(
              controller: _odometerController,
              label: 'Odometer Reading',
              hint: 'e.g. 42000 km',
              icon: Icons.display_settings_outlined,
              keyboardType: TextInputType.number,
              validator: (value) =>
                  _numericValidator(value, 'odometer reading'),
              textInputAction: TextInputAction.next,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return RentCarSectionCard(
      title: 'Vehicle Description',
      icon: Icons.description_outlined,
      child: RentCarTextField(
        controller: _descriptionController,
        label: 'Description',
        hint: 'Add a short, clear description for renters',
        icon: Icons.notes_outlined,
        maxLines: 5,
        validator: (value) => _requiredText(value, 'vehicle description'),
      ),
    );
  }

  void _goNext() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedDraft = widget.draft.copyWith(
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      variant: _variantController.text.trim(),
      manufacturingYear: _yearController.text.trim(),
      registrationNumber: _registrationController.text.trim(),
      fuelType: _fuelType ?? '',
      transmission: _transmission ?? '',
      mileage: _mileageController.text.trim(),
      seatingCapacity: _seatingController.text.trim(),
      color: _colorController.text.trim(),
      engineCapacity: _engineController.text.trim(),
      odometerReading: _odometerController.text.trim(),
      vehicleDescription: _descriptionController.text.trim(),
    );

    Navigator.of(context).push(
      buildRentCarSlideRoute(
        CarPricingAndAvailabilityScreen(draft: updatedDraft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: RentCarScreenScaffold(
        currentStep: 1,
        title: 'Car Specifications',
        subtitle:
            'Capture the vehicle identity and technical details with clear, structured inputs.',
        onBack: () => Navigator.of(context).maybePop(),
        onNext: _goNext,
        nextLabel: 'Next',
        backLabel: 'Back',
        child: Column(
          children: [
            _buildVehicleIdentitySection(),
            const SizedBox(height: 16),
            _buildTechnicalDetailsSection(),
            const SizedBox(height: 16),
            _buildDescriptionSection(),
          ],
        ),
      ),
    );
  }
}
