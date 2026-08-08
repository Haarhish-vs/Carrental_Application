import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:car_rental_app_client_side/core/theme/app_colors.dart';
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
  XFile? _insuranceDocumentFile;
  XFile? _dlDocumentFile;
  XFile? _pollutionDocumentFile;

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

    // Load any existing local documents from the draft
    _rcDocumentFile = widget.draft.localDocuments['rc_book'];
    _insuranceDocumentFile = widget.draft.localDocuments['insurance'];
    _dlDocumentFile = widget.draft.localDocuments['driving_license'];
    _pollutionDocumentFile = widget.draft.localDocuments['pollution_certificate'];
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
    final updatedDocs = <String, XFile>{};
    if (_rcDocumentFile != null) updatedDocs['rc_book'] = _rcDocumentFile!;
    if (_insuranceDocumentFile != null) updatedDocs['insurance'] = _insuranceDocumentFile!;
    if (_dlDocumentFile != null) updatedDocs['driving_license'] = _dlDocumentFile!;
    if (_pollutionDocumentFile != null) updatedDocs['pollution_certificate'] = _pollutionDocumentFile!;

    final updatedDraft = widget.draft.copyWith(
      localDocuments: updatedDocs,
      registrationNumber: _registrationCertificateController.text.trim(),
    );

    Navigator.of(context).pop(updatedDraft);
  }

  Future<XFile?> _pickDocument(String title) async {
    return showModalBottomSheet<XFile?>(
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
                  'Upload $title',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose camera, gallery, or file to upload your document scan or PDF.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
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
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final pickedFile = result.files.first;
                      XFile? xfile;

                      if (pickedFile.path != null) {
                        xfile = XFile(pickedFile.path!);
                      } else if (pickedFile.bytes != null) {
                        xfile = XFile.fromData(
                          pickedFile.bytes!,
                          name: pickedFile.name,
                          mimeType: pickedFile.extension == 'pdf'
                              ? 'application/pdf'
                              : 'image/${pickedFile.extension ?? 'jpeg'}',
                        );
                      }

                      if (context.mounted) Navigator.of(context).pop(xfile);
                      return;
                    }

                    if (context.mounted) Navigator.of(context).pop(null);
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Choose Document from Files'),
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
  }

  void _showDocumentPreviewDialog(XFile file) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final isImage = ['jpg', 'jpeg', 'png'].contains(file.name.split('.').last.toLowerCase()) || 
          (file.mimeType?.startsWith('image/') ?? false);

        return AlertDialog(
          title: Text(file.name),
          content: isImage
              ? FutureBuilder<Uint8List>(
                  future: file.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasData) {
                      return Image.memory(snapshot.data!);
                    }
                    return const Text('Failed to load image');
                  },
                )
              : const SizedBox(
                  height: 120,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text('PDF Scan Document', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_rcDocumentFile == null) {
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
      // 1. Upload car images to Cloudinary (using existing uploadFiles flow)
      final List<XFile> localCarImages = widget.draft.localPhotos;
      final List<String> uploadedCarUrls = List<String>.from(widget.draft.selectedPhotos);

      if (localCarImages.isNotEmpty) {
        final cloudUrls = await _apiService.uploadFiles(localCarImages, (progress) {});
        uploadedCarUrls.addAll(cloudUrls);
      }

      // 2. Upload verification documents to Supabase storage flow
      String? rcDocUrl;
      String? insuranceDocUrl;
      String? dlDocUrl;
      String? pollutionDocUrl;

      // RC Book
      rcDocUrl = await _apiService.uploadDocument(_rcDocumentFile!);

      // Insurance (Optional)
      if (_insuranceDocumentFile != null) {
        insuranceDocUrl = await _apiService.uploadDocument(_insuranceDocumentFile!);
      }

      // Driving License (Optional)
      if (_dlDocumentFile != null) {
        dlDocUrl = await _apiService.uploadDocument(_dlDocumentFile!);
      }

      // Pollution Certificate (Optional)
      if (_pollutionDocumentFile != null) {
        pollutionDocUrl = await _apiService.uploadDocument(_pollutionDocumentFile!);
      }

      // 3. Prepare vehicle payload
      final payload = VehicleModel.fromDraft(widget.draft.copyWith(
        selectedPhotos: uploadedCarUrls,
      ));
      payload['rc_number'] = _registrationCertificateController.text.trim();

      // 4. Create vehicle listing
      final vehicle = await _apiService.createVehicle(payload);
      final vehicleId = vehicle['id'] as String?;

      if (vehicleId != null) {
        // 5. Submit documents metadata to vehicle_documents table
        // RC Book metadata
        await _apiService.uploadVehicleDocument(
          vehicleId: vehicleId,
          documentType: 'rc_book',
          documentUrl: rcDocUrl,
        );

        // Insurance metadata
        if (insuranceDocUrl != null || _insurancePolicyController.text.isNotEmpty) {
          await _apiService.uploadVehicleDocument(
            vehicleId: vehicleId,
            documentType: 'insurance',
            documentUrl: insuranceDocUrl ?? _insurancePolicyController.text.trim(),
          );
        }

        // Driving license metadata
        if (dlDocUrl != null || _ownerIdController.text.isNotEmpty) {
          await _apiService.uploadVehicleDocument(
            vehicleId: vehicleId,
            documentType: 'driving_license',
            documentUrl: dlDocUrl ?? _ownerIdController.text.trim(),
          );
        }

        // Pollution Certificate metadata
        if (pollutionDocUrl != null || _permitController.text.isNotEmpty) {
          await _apiService.uploadVehicleDocument(
            vehicleId: vehicleId,
            documentType: 'pollution_certificate',
            documentUrl: pollutionDocUrl ?? _permitController.text.trim(),
          );
        }
      }

      if (!mounted) return;

      // 6. Show success summary dialog
      final summary = <String, String>{
        'Brand': widget.draft.brand,
        'Model': widget.draft.model,
        'Year': widget.draft.manufacturingYear,
        'Daily Price': '₹${widget.draft.dailyPrice}',
        'RC Number': _registrationCertificateController.text.trim(),
        'RC Document': 'Uploaded & Verified',
        'Car Images': '${uploadedCarUrls.length} Uploaded to Cloudinary',
        'Listing Status': vehicle['status'] ?? 'under_review',
      };

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Listing Created!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your vehicle listing has been successfully saved, and documents have been uploaded to Supabase Storage.'),
                const SizedBox(height: 16),
                ...summary.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF103B66),
                            ),
                        children: [
                          TextSpan(
                            text: '${entry.key}: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: entry.value),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Back to Home'),
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

  Widget _buildDocUploadCard({
    required String title,
    required String subtitle,
    required XFile? file,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    required VoidCallback onPreview,
    required IconData icon,
  }) {
    final hasFile = file != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasFile ? AppColors.primaryLight : AppColors.inputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasFile ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasFile ? AppColors.primary : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasFile ? Icons.picture_as_pdf_rounded : icon,
              color: hasFile ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasFile ? file.name : subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (hasFile) ...[
            IconButton(
              icon: const Icon(Icons.visibility_outlined, color: AppColors.textSecondary),
              onPressed: onPreview,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: onRemove,
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              onPressed: onPick,
            ),
        ],
      ),
    );
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
                'Select your RC Book and optional verification documents to list your vehicle.',
            onBack: _isLoading ? null : _goBack,
            onNext: _isLoading ? null : _submit,
            nextLabel: 'Upload',
            backLabel: 'Back',
            isLastStep: true,
            child: Column(
              children: [
                RentCarSectionCard(
                  title: 'Required Verification Documents',
                  icon: Icons.upload_file_rounded,
                  child: Column(
                    children: [
                      _buildDocUploadCard(
                        title: 'RC Book Document (Required)',
                        subtitle: 'Tap to pick PDF scan or document image',
                        file: _rcDocumentFile,
                        icon: Icons.receipt_long_outlined,
                        onPick: () async {
                          final file = await _pickDocument('RC Book');
                          if (file != null) setState(() => _rcDocumentFile = file);
                        },
                        onRemove: () => setState(() => _rcDocumentFile = null),
                        onPreview: () => _showDocumentPreviewDialog(_rcDocumentFile!),
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
                  title: 'Optional Verification Documents',
                  icon: Icons.article_outlined,
                  child: Column(
                    children: [
                      _buildDocUploadCard(
                        title: 'Insurance Policy',
                        subtitle: 'Tap to pick insurance scan/PDF',
                        file: _insuranceDocumentFile,
                        icon: Icons.policy_outlined,
                        onPick: () async {
                          final file = await _pickDocument('Insurance Policy');
                          if (file != null) setState(() => _insuranceDocumentFile = file);
                        },
                        onRemove: () => setState(() => _insuranceDocumentFile = null),
                        onPreview: () => _showDocumentPreviewDialog(_insuranceDocumentFile!),
                      ),
                      const SizedBox(height: 14),
                      RentCarTextField(
                        controller: _insurancePolicyController,
                        label: 'Insurance Policy Number (Optional)',
                        hint: 'Enter active insurance reference',
                        icon: Icons.policy_outlined,
                        textInputAction: TextInputAction.next,
                        readOnly: _isLoading,
                      ),
                      const SizedBox(height: 20),
                      _buildDocUploadCard(
                        title: 'Driving License',
                        subtitle: 'Tap to pick driving license scan/PDF',
                        file: _dlDocumentFile,
                        icon: Icons.badge_outlined,
                        onPick: () async {
                          final file = await _pickDocument('Driving License');
                          if (file != null) setState(() => _dlDocumentFile = file);
                        },
                        onRemove: () => setState(() => _dlDocumentFile = null),
                        onPreview: () => _showDocumentPreviewDialog(_dlDocumentFile!),
                      ),
                      const SizedBox(height: 14),
                      RentCarTextField(
                        controller: _ownerIdController,
                        label: 'Owner ID Reference / DL Number (Optional)',
                        hint: 'Enter owner DL reference',
                        icon: Icons.badge_outlined,
                        textInputAction: TextInputAction.next,
                        readOnly: _isLoading,
                      ),
                      const SizedBox(height: 20),
                      _buildDocUploadCard(
                        title: 'Pollution Certificate / Permit',
                        subtitle: 'Tap to pick permit or pollution scan/PDF',
                        file: _pollutionDocumentFile,
                        icon: Icons.credit_card_outlined,
                        onPick: () async {
                          final file = await _pickDocument('Pollution Certificate / Permit');
                          if (file != null) setState(() => _pollutionDocumentFile = file);
                        },
                        onRemove: () => setState(() => _pollutionDocumentFile = null),
                        onPreview: () => _showDocumentPreviewDialog(_pollutionDocumentFile!),
                      ),
                      const SizedBox(height: 14),
                      RentCarTextField(
                        controller: _permitController,
                        label: 'Permit / Fitness / Pollution Reference (Optional)',
                        hint: 'Enter permit or pollution number',
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
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text(
                            'Uploading Listing & Documents...',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please do not close the app.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
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
