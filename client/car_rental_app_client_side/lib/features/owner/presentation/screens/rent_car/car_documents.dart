import 'package:flutter/material.dart';
import 'package:car_rental_app_client_side/features/owner/data/models/vehicle_model.dart';
import 'package:car_rental_app_client_side/features/owner/data/services/car_api_service.dart';
import 'rent_car_shared.dart';

class CarDocumentsScreen extends StatefulWidget {
  const CarDocumentsScreen({super.key, required this.draft});

  final RentCarDraft draft;

  @override
  State<CarDocumentsScreen> createState() => _CarDocumentsScreenState();
}

class _CarDocumentsScreenState extends State<CarDocumentsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CarApiService _apiService = CarApiService();

  late final TextEditingController _registrationCertificateController;
  late final TextEditingController _insurancePolicyController;
  late final TextEditingController _ownerIdController;
  late final TextEditingController _permitController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _registrationCertificateController = TextEditingController();
    _insurancePolicyController = TextEditingController();
    _ownerIdController = TextEditingController();
    _permitController = TextEditingController();
  }

  @override
  void dispose() {
    _registrationCertificateController.dispose();
    _insurancePolicyController.dispose();
    _ownerIdController.dispose();
    _permitController.dispose();
    super.dispose();
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $label';
    }
    return null;
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Prepare vehicle payload
      final payload = VehicleModel.fromDraft(widget.draft);
      
      // Send the actual registration certificate number as the rc_number in payload
      payload['rc_number'] = _registrationCertificateController.text.trim();

      // 2. Post vehicle listing to backend
      final vehicle = await _apiService.createVehicle(payload);
      final vehicleId = vehicle['id'] as String?;

      if (vehicleId != null) {
        // 3. Post document metadata associated with the vehicle
        await _apiService.uploadVehicleDocument(
          vehicleId: vehicleId,
          documentType: 'rc_book',
          documentUrl: _registrationCertificateController.text.trim(),
        );

        await _apiService.uploadVehicleDocument(
          vehicleId: vehicleId,
          documentType: 'insurance',
          documentUrl: _insurancePolicyController.text.trim(),
        );

        if (_permitController.text.isNotEmpty) {
          await _apiService.uploadVehicleDocument(
            vehicleId: vehicleId,
            documentType: 'fc',
            documentUrl: _permitController.text.trim(),
          );
        }
      }

      if (!mounted) return;

      // 4. Show success dialog
      final summary = <String, String>{
        'Brand': widget.draft.brand,
        'Model': widget.draft.model,
        'Year': widget.draft.manufacturingYear,
        'Daily price': widget.draft.dailyPrice,
        'RC Number': _registrationCertificateController.text.trim(),
        'Listing Status': vehicle['status'] ?? 'under_review',
      };

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Car Listing Submitted'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your vehicle listing has been successfully submitted and is under review.'),
                const SizedBox(height: 16),
                ...summary.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Navigate back to the homepage
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit listing: ${e.toString().replaceAll('Exception:', '').trim()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Stack(
        children: [
          RentCarScreenScaffold(
            currentStep: 4,
            title: 'Documents',
            subtitle:
                'Capture the document references needed for verification and approval.',
            onBack: _isLoading ? null : _goBack,
            onNext: _isLoading ? null : _submit,
            nextLabel: 'Submit',
            backLabel: 'Back',
            isLastStep: true,
            child: Column(
              children: [
                RentCarSectionCard(
                  title: 'Verification Details',
                  icon: Icons.verified_user_outlined,
                  child: Column(
                    children: [
                      RentCarTextField(
                        controller: _registrationCertificateController,
                        label: 'Registration Certificate Number',
                        hint: 'Enter official document number',
                        icon: Icons.receipt_long_outlined,
                        validator: (value) =>
                            _requiredText(value, 'registration certificate number'),
                        textInputAction: TextInputAction.next,
                        readOnly: _isLoading,
                      ),
                      const SizedBox(height: 14),
                      RentCarTextField(
                        controller: _insurancePolicyController,
                        label: 'Insurance Policy Number',
                        hint: 'Enter active insurance reference',
                        icon: Icons.policy_outlined,
                        validator: (value) =>
                            _requiredText(value, 'insurance policy number'),
                        textInputAction: TextInputAction.next,
                        readOnly: _isLoading,
                      ),
                      const SizedBox(height: 14),
                      RentCarTextField(
                        controller: _ownerIdController,
                        label: 'Owner ID Reference',
                        hint: 'Enter owner identity reference',
                        icon: Icons.badge_outlined,
                        validator: (value) =>
                            _requiredText(value, 'owner ID reference'),
                        textInputAction: TextInputAction.next,
                        readOnly: _isLoading,
                      ),
                      const SizedBox(height: 14),
                      RentCarTextField(
                        controller: _permitController,
                        label: 'Permit / License Reference',
                        hint: 'Enter permit or license number',
                        icon: Icons.credit_card_outlined,
                        validator: (value) =>
                            _requiredText(value, 'permit or license reference'),
                        readOnly: _isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                RentCarSectionCard(
                  title: 'Review Summary',
                  icon: Icons.fact_check_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Brand: ${widget.draft.brand}'),
                      const SizedBox(height: 8),
                      Text('Model: ${widget.draft.model}'),
                      const SizedBox(height: 8),
                      Text('Year: ${widget.draft.manufacturingYear}'),
                      const SizedBox(height: 8),
                      Text('Daily Price: ${widget.draft.dailyPrice}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Submitting Listing...',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
