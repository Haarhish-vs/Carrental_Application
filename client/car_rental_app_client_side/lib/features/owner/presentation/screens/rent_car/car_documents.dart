import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _registrationCertificateController;
  late final TextEditingController _insurancePolicyController;
  late final TextEditingController _ownerIdController;
  late final TextEditingController _permitController;

  XFile? _rcDocumentFile;
  String? _rcDocumentUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _registrationCertificateController = TextEditingController(
      text: widget.draft.registrationNumber,
    );
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

  Future<void> _pickRcDocument() async {
    final file = await showModalBottomSheet<XFile?>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Upload RC Document / PDF',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF103B66),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose camera or gallery to upload your Registration Certificate document scan.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF57718A),
                      ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    final picked = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                    );
                    if (context.mounted) Navigator.of(context).pop(picked);
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take Document Photo'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (context.mounted) Navigator.of(context).pop(picked);
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Choose Document from Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (file != null) {
      setState(() {
        _rcDocumentFile = file;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_rcDocumentFile == null && (_rcDocumentUrl == null || _rcDocumentUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the Registration Certificate (RC) document.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload RC document file to get permanent URL or Base64 URL
      String uploadedRcUrl = _rcDocumentUrl ?? '';
      if (_rcDocumentFile != null) {
        try {
          final urls = await _apiService.uploadFiles([_rcDocumentFile!], (p) {});
          if (urls.isNotEmpty) {
            uploadedRcUrl = urls.first;
          }
        } catch (_) {
          final bytes = await _rcDocumentFile!.readAsBytes();
          uploadedRcUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      }

      // 2. Prepare vehicle payload
      final payload = VehicleModel.fromDraft(widget.draft);
      payload['rc_number'] = _registrationCertificateController.text.trim();

      // 3. Post vehicle listing to backend
      final vehicle = await _apiService.createVehicle(payload);
      final vehicleId = vehicle['id'] as String?;

      if (vehicleId != null) {
        // 4. Post RC document metadata to vehicle_documents table
        await _apiService.uploadVehicleDocument(
          vehicleId: vehicleId,
          documentType: 'rc_book',
          documentUrl: uploadedRcUrl,
        );

        if (_insurancePolicyController.text.isNotEmpty) {
          await _apiService.uploadVehicleDocument(
            vehicleId: vehicleId,
            documentType: 'insurance',
            documentUrl: _insurancePolicyController.text.trim(),
          );
        }

        if (_permitController.text.isNotEmpty) {
          await _apiService.uploadVehicleDocument(
            vehicleId: vehicleId,
            documentType: 'fc',
            documentUrl: _permitController.text.trim(),
          );
        }
      }

      if (!mounted) return;

      // 5. Show success dialog
      final summary = <String, String>{
        'Brand': widget.draft.brand,
        'Model': widget.draft.model,
        'Year': widget.draft.manufacturingYear,
        'Daily Price': widget.draft.dailyPrice,
        'RC Number': _registrationCertificateController.text.trim(),
        'RC Document': 'Attached & Saved',
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
                const Text('Your vehicle listing and RC documents have been successfully submitted and stored in the database.'),
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
                'Upload your Registration Certificate (RC) PDF/document for vehicle verification.',
            onBack: _isLoading ? null : _goBack,
            onNext: _isLoading ? null : _submit,
            nextLabel: 'Submit',
            backLabel: 'Back',
            isLastStep: true,
            child: Column(
              children: [
                RentCarSectionCard(
                  title: 'Upload RC Book Document (Required)',
                  icon: Icons.upload_file_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _isLoading ? null : _pickRcDocument,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _rcDocumentFile != null
                                ? const Color(0xFFEAF2FF)
                                : const Color(0xFFF7FAFD),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _rcDocumentFile != null
                                  ? const Color(0xFF1E5AA8)
                                  : const Color(0xFFD7E2EF),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _rcDocumentFile != null
                                      ? const Color(0xFF1E5AA8)
                                      : const Color(0xFFE0EBF8),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _rcDocumentFile != null
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.cloud_upload_outlined,
                                  color: _rcDocumentFile != null
                                      ? Colors.white
                                      : const Color(0xFF1E5AA8),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _rcDocumentFile != null
                                          ? 'RC Document Attached'
                                          : 'Upload RC Book Document / PDF',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: const Color(0xFF103B66),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _rcDocumentFile != null
                                          ? _rcDocumentFile!.name
                                          : 'Tap to pick PDF scan or document image',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF57718A),
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _rcDocumentFile != null
                                    ? Icons.check_circle_rounded
                                    : Icons.add_a_photo_outlined,
                                color: _rcDocumentFile != null
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF1E5AA8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RentCarTextField(
                        controller: _registrationCertificateController,
                        label: 'Registration Certificate Number',
                        hint: 'Enter official RC number',
                        icon: Icons.receipt_long_outlined,
                        validator: (value) =>
                            _requiredText(value, 'registration certificate number'),
                        textInputAction: TextInputAction.next,
                        readOnly: _isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                RentCarSectionCard(
                  title: 'Optional Document References',
                  icon: Icons.article_outlined,
                  child: Column(
                    children: [
                      RentCarTextField(
                        controller: _insurancePolicyController,
                        label: 'Insurance Policy Number (Optional)',
                        hint: 'Enter active insurance reference',
                        icon: Icons.policy_outlined,
                        textInputAction: TextInputAction.next,
                        readOnly: _isLoading,
                      ),
                      const SizedBox(height: 14),
                      RentCarTextField(
                        controller: _ownerIdController,
                        label: 'Owner ID Reference (Optional)',
                        hint: 'Enter owner identity reference',
                        icon: Icons.badge_outlined,
                        textInputAction: TextInputAction.next,
                        readOnly: _isLoading,
                      ),
                      const SizedBox(height: 14),
                      RentCarTextField(
                        controller: _permitController,
                        label: 'Permit / Fitness Reference (Optional)',
                        hint: 'Enter permit or license number',
                        icon: Icons.credit_card_outlined,
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
                      Text('Daily Price: ₹${widget.draft.dailyPrice}'),
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
                            'Submitting Listing & Documents...',
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
