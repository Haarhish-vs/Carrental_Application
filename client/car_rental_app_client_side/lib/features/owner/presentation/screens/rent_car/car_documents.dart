import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:car_rental_app_client_side/core/theme/app_colors.dart';
import 'package:car_rental_app_client_side/features/owner/data/models/vehicle_model.dart';
import 'package:car_rental_app_client_side/features/owner/data/services/car_api_service.dart';
import 'package:car_rental_app_client_side/features/owner/data/models/document_verification_models.dart';
import 'package:car_rental_app_client_side/features/owner/data/controllers/document_verification_controller.dart';
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
  late final TextEditingController _fitnessController;
  late final TextEditingController _pucController;

  XFile? _rcDocumentFile;
  XFile? _insuranceDocumentFile;
  XFile? _dlDocumentFile;
  XFile? _fitnessDocumentFile;
  XFile? _pucDocumentFile;
  XFile? _permitDocumentFile;

  bool _isLoading = false;
  late final void Function(DocumentVerificationState) _verificationListener;
  DocumentVerificationState _verificationState = DocumentVerificationState();

  @override
  void initState() {
    super.initState();
    _registrationCertificateController = TextEditingController(
      text: widget.draft.registrationNumber,
    );
    _insurancePolicyController = TextEditingController();
    _ownerIdController = TextEditingController();
    _permitController = TextEditingController();
    _fitnessController = TextEditingController();
    _pucController = TextEditingController();

    // Load any existing local documents from the draft
    _rcDocumentFile = widget.draft.localDocuments['rc_book'];
    _insuranceDocumentFile = widget.draft.localDocuments['insurance'];
    _dlDocumentFile = widget.draft.localDocuments['driving_license'];
    _fitnessDocumentFile = widget.draft.localDocuments['fitness_certificate'];
    _pucDocumentFile = widget.draft.localDocuments['puc'];
    _permitDocumentFile = widget.draft.localDocuments['permit'];

    // Listen to verification flow updates
    _verificationListener = (state) {
      if (mounted) {
        setState(() {
          _verificationState = state;
        });
      }
    };
    DocumentVerificationController.instance.addListener(_verificationListener);
  }

  @override
  void dispose() {
    DocumentVerificationController.instance.removeListener(
      _verificationListener,
    );
    _registrationCertificateController.dispose();
    _insurancePolicyController.dispose();
    _ownerIdController.dispose();
    _permitController.dispose();
    _fitnessController.dispose();
    _pucController.dispose();
    super.dispose();
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $label';
    }
    return null;
  }

  void _goBack() {
    // Save state back to localDocuments before pop
    final updatedDocs = <String, XFile>{};
    if (_rcDocumentFile != null) {
      updatedDocs['rc_book'] = _rcDocumentFile!;
    }
    if (_insuranceDocumentFile != null) {
      updatedDocs['insurance'] = _insuranceDocumentFile!;
    }
    if (_dlDocumentFile != null) {
      updatedDocs['driving_license'] = _dlDocumentFile!;
    }
    if (_fitnessDocumentFile != null) {
      updatedDocs['fitness_certificate'] = _fitnessDocumentFile!;
    }
    if (_pucDocumentFile != null) {
      updatedDocs['puc'] = _pucDocumentFile!;
    }
    if (_permitDocumentFile != null) {
      updatedDocs['permit'] = _permitDocumentFile!;
    }

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
                    color: const Color(0xFF103B66),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose camera, gallery, or file to upload your document scan or PDF.',
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
        final isImage =
            [
              'jpg',
              'jpeg',
              'png',
            ].contains(file.name.split('.').last.toLowerCase()) ||
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
                        Text(
                          'PDF Scan Document',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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
          content: Text(
            'Please upload the Registration Certificate (RC) document.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload car images to Cloudinary (using existing uploadFiles flow)
      final List<XFile> localCarImages = widget.draft.localPhotos;
      final List<String> uploadedCarUrls = List<String>.from(
        widget.draft.selectedPhotos,
      );

      if (localCarImages.isNotEmpty) {
        final cloudUrls = await _apiService.uploadFiles(
          localCarImages,
          (progress) {},
        );
        uploadedCarUrls.addAll(cloudUrls);
      }

      // 2. Prepare vehicle payload & create vehicle (if not already created)
      String? vehicleId = _verificationState.vehicleId;
      Map<String, dynamic> vehicle;

      if (vehicleId == null) {
        final payload = VehicleModel.fromDraft(
          widget.draft.copyWith(selectedPhotos: uploadedCarUrls),
        );
        payload['rc_number'] = _registrationCertificateController.text.trim();

        vehicle = await _apiService.createVehicle(payload);
        vehicleId = vehicle['id'] as String?;
        if (vehicleId == null) {
          throw Exception('Failed to obtain vehicle ID from listing response.');
        }
      }

      // 3. Upload driving license (if present) to Supabase (old flow)
      if (_dlDocumentFile != null) {
        final dlDocUrl = await _apiService.uploadDocument(_dlDocumentFile!);
        await _apiService.uploadVehicleDocument(
          vehicleId: vehicleId,
          documentType: 'driving_license',
          documentUrl: dlDocUrl,
        );
      }

      // 4. Trigger document verification workflow on the OCR backend
      await DocumentVerificationController.instance.startVerificationFlow(
        vehicleId: vehicleId,
        rc: _rcDocumentFile,
        insurance: _insuranceDocumentFile,
        fc: _fitnessDocumentFile,
        puc: _pucDocumentFile,
        permit: _permitDocumentFile,
      );

      // Check for validation errors
      final state = DocumentVerificationController.instance.state;
      if (state.errorMessage != null) {
        throw Exception(state.errorMessage);
      }

      final result = state.verificationResult;
      if (result != null) {
        if (result.overallStatus == 'VERIFIED' ||
            result.overallStatus == 'APPROVED') {
          _showSuccessDialog(uploadedCarUrls, vehicleId);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Submission failed: ${e.toString().replaceAll('Exception:', '').trim()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(List<String> uploadedCarUrls, String vehicleId) {
    final summary = <String, String>{
      'Brand': widget.draft.brand,
      'Model': widget.draft.model,
      'Year': widget.draft.manufacturingYear,
      'Daily Price': '₹${widget.draft.dailyPrice}',
      'RC Number': _registrationCertificateController.text.trim(),
      'Verification Status': 'VERIFIED',
      'Car Images': '${uploadedCarUrls.length} Uploaded to Cloudinary',
    };

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Listing Created!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your vehicle listing has been successfully saved, and documents have passed OCR verification.',
              ),
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
                // Wipes registration cache on final success
                DocumentVerificationController.instance.reset();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Back to Home'),
            ),
          ],
        );
      },
    );
  }

  String _maskSensitiveText(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.length <= 4) return str;
    final first = str.substring(0, 2);
    final last = str.substring(str.length - 2);
    final mask = '*' * (str.length - 4);
    return '$first$mask$last';
  }

  dynamic _getValueSafely(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) return map[key];
    }
    return null;
  }

  Widget _buildExtractedFieldRow(
    String label,
    String key,
    Map<String, dynamic> fields, {
    bool shouldMask = false,
  }) {
    final val = _getValueSafely(fields, [
      key,
      key.replaceAll(RegExp(r'(?=[A-Z])'), '_').toLowerCase(),
    ]);
    if (val == null) return const SizedBox.shrink();
    final displayVal = shouldMask ? _maskSensitiveText(val) : val.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF57718A), fontSize: 13),
          ),
          Text(
            displayVal,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF103B66),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedInfoSection() {
    if (_verificationState.analysisResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return RentCarSectionCard(
      title: 'Extracted OCR Information',
      icon: Icons.document_scanner_outlined,
      child: Column(
        children: _verificationState.analysisResults.entries.map((entry) {
          final docType = entry.key;
          final analysisResult = entry.value;
          final fields = analysisResult.extractedFields;

          if (fields.isEmpty) return const SizedBox.shrink();

          return ExpansionTile(
            title: Text(
              docType.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF103B66),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    if (docType == 'rc') ...[
                      _buildExtractedFieldRow(
                        'Registration Number',
                        'registrationNumber',
                        fields,
                        shouldMask: true,
                      ),
                      _buildExtractedFieldRow(
                        'Owner Name',
                        'ownerName',
                        fields,
                      ),
                      _buildExtractedFieldRow(
                        'Engine Number',
                        'engineNumber',
                        fields,
                        shouldMask: true,
                      ),
                      _buildExtractedFieldRow(
                        'Chassis Number',
                        'chassisNumber',
                        fields,
                        shouldMask: true,
                      ),
                      _buildExtractedFieldRow(
                        'Registration Date',
                        'registrationDate',
                        fields,
                      ),
                    ] else if (docType == 'insurance') ...[
                      _buildExtractedFieldRow(
                        'Policy Number',
                        'policyNumber',
                        fields,
                        shouldMask: true,
                      ),
                      _buildExtractedFieldRow(
                        'Expiry Date',
                        'expiryDate',
                        fields,
                      ),
                    ] else if (docType == 'fc') ...[
                      _buildExtractedFieldRow(
                        'Certificate Number',
                        'certificateNumber',
                        fields,
                        shouldMask: true,
                      ),
                      _buildExtractedFieldRow(
                        'Expiry Date',
                        'expiryDate',
                        fields,
                      ),
                    ] else if (docType == 'puc') ...[
                      _buildExtractedFieldRow(
                        'Certificate Number',
                        'certificateNumber',
                        fields,
                        shouldMask: true,
                      ),
                      _buildExtractedFieldRow(
                        'Expiry Date',
                        'expiryDate',
                        fields,
                      ),
                    ] else if (docType == 'permit') ...[
                      _buildExtractedFieldRow(
                        'Permit Number',
                        'permitNumber',
                        fields,
                        shouldMask: true,
                      ),
                      _buildExtractedFieldRow(
                        'Expiry Date',
                        'expiryDate',
                        fields,
                      ),
                    ] else ...[
                      ...fields.entries.map(
                        (e) => _buildExtractedFieldRow(
                          e.key
                              .replaceAll(RegExp(r'(?=[A-Z])'), ' ')
                              .toUpperCase(),
                          e.key,
                          fields,
                          shouldMask:
                              e.key.toLowerCase().contains('number') ||
                              e.key.toLowerCase().contains('no'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVerificationDetailRow(
    String label,
    DocumentVerificationStatus? status,
  ) {
    final failed = status == DocumentVerificationStatus.failed;
    final verified = status == DocumentVerificationStatus.verified;
    final statusColor = failed
        ? Colors.red
        : (verified ? Colors.green : Colors.grey);
    final icon = failed
        ? Icons.cancel_rounded
        : (verified ? Icons.check_circle_rounded : Icons.info_outline);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF103B66),
            ),
          ),
          const Spacer(),
          Text(
            failed ? 'REJECTED' : (verified ? 'VALID' : 'PENDING'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationResultPanel() {
    final result = _verificationState.verificationResult;
    if (result == null) return const SizedBox.shrink();

    final isFailed =
        result.overallStatus == 'FAILED' ||
        result.overallStatus == 'NEEDS_ATTENTION';
    final statusColor = isFailed ? Colors.red : Colors.green;
    final statusBg = isFailed
        ? const Color(0xFFFFF2F2)
        : const Color(0xFFF2FFF2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isFailed
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                    color: statusColor,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isFailed
                          ? 'Verification Requires Attention'
                          : 'Verification Complete',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Score: ${(result.overallScore * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.summary.isNotEmpty
                    ? result.summary
                    : 'All uploaded documents have been processed.',
                style: const TextStyle(color: Color(0xFF103B66), fontSize: 14),
              ),
              if (result.recommendation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Recommendation: ${result.recommendation}',
                  style: const TextStyle(
                    color: Color(0xFF57718A),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        RentCarSectionCard(
          title: 'Verification Status Details',
          icon: Icons.assignment_turned_in_outlined,
          child: Column(
            children: [
              _buildVerificationDetailRow(
                'RC Book',
                _verificationState.documentStatuses['rc'],
              ),
              if (_insuranceDocumentFile != null)
                _buildVerificationDetailRow(
                  'Insurance',
                  _verificationState.documentStatuses['insurance'],
                ),
              if (_fitnessDocumentFile != null)
                _buildVerificationDetailRow(
                  'Fitness Certificate (FC)',
                  _verificationState.documentStatuses['fc'],
                ),
              if (_pucDocumentFile != null)
                _buildVerificationDetailRow(
                  'PUC Certificate',
                  _verificationState.documentStatuses['puc'],
                ),
              if (_permitDocumentFile != null)
                _buildVerificationDetailRow(
                  'Permit Document',
                  _verificationState.documentStatuses['permit'],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (result.crossValidationResults.isNotEmpty)
          RentCarSectionCard(
            title: 'Cross-Document Validations',
            icon: Icons.compare_arrows_rounded,
            child: Column(
              children: result.crossValidationResults.entries.map((e) {
                final Map<String, dynamic> valMap = e.value is Map
                    ? e.value
                    : {};
                final passed =
                    valMap['passed'] == true ||
                    valMap['status'] == 'success' ||
                    valMap['status'] == 'VALID';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        passed
                            ? Icons.check_circle_outline
                            : Icons.error_outline_rounded,
                        color: passed ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.key
                              .replaceAll(RegExp(r'(?=[A-Z])'), ' ')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF103B66),
                          ),
                        ),
                      ),
                      Text(
                        valMap['message']?.toString() ??
                            (passed ? 'PASSED' : 'MISMATCH'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: passed ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressRow(String label, DocumentVerificationStatus? status) {
    if (status == null || status == DocumentVerificationStatus.notUploaded) {
      return const SizedBox.shrink();
    }

    IconData icon = Icons.circle_outlined;
    Color color = Colors.grey;
    String statusStr = 'Pending';

    switch (status) {
      case DocumentVerificationStatus.uploading:
        icon = Icons.cloud_upload_outlined;
        color = AppColors.primary;
        statusStr = 'Uploading...';
        break;
      case DocumentVerificationStatus.uploaded:
        icon = Icons.cloud_done_outlined;
        color = Colors.blue;
        statusStr = 'Uploaded';
        break;
      case DocumentVerificationStatus.analyzing:
        icon = Icons.hourglass_empty_rounded;
        color = Colors.orange;
        statusStr = 'Extracting info...';
        break;
      case DocumentVerificationStatus.analyzed:
        icon = Icons.fact_check_outlined;
        color = Colors.purple;
        statusStr = 'Extracted';
        break;
      case DocumentVerificationStatus.verifying:
        icon = Icons.gpp_maybe_outlined;
        color = Colors.blue;
        statusStr = 'Verifying...';
        break;
      case DocumentVerificationStatus.verified:
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        statusStr = 'Verified';
        break;
      case DocumentVerificationStatus.failed:
        icon = Icons.cancel_rounded;
        color = Colors.red;
        statusStr = 'Failed';
        break;
      default:
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const Spacer(),
          Text(
            statusStr,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
        color: hasFile ? const Color(0xFFEAF2FF) : const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasFile ? AppColors.primary : const Color(0xFFD7E2EF),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasFile ? AppColors.primary : const Color(0xFFE0EBF8),
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
                    color: const Color(0xFF103B66),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasFile ? file.name : subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF57718A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (hasFile) ...[
            IconButton(
              icon: const Icon(
                Icons.visibility_outlined,
                color: Color(0xFF57718A),
              ),
              onPressed: onPreview,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: onRemove,
            ),
          ] else
            IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primary,
              ),
              onPressed: onPick,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _verificationState.verificationResult;
    final hasFailed =
        result != null &&
        (result.overallStatus == 'FAILED' ||
            result.overallStatus == 'NEEDS_ATTENTION');

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
            nextLabel: hasFailed ? 'Retry' : 'Upload',
            backLabel: 'Back',
            isLastStep: true,
            child: Column(
              children: [
                if (result != null) ...[
                  _buildVerificationResultPanel(),
                  const SizedBox(height: 16),
                  _buildExtractedInfoSection(),
                  const SizedBox(height: 16),
                ],
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
                          if (file != null) {
                            setState(() => _rcDocumentFile = file);
                          }
                        },
                        onRemove: () => setState(() => _rcDocumentFile = null),
                        onPreview: () =>
                            _showDocumentPreviewDialog(_rcDocumentFile!),
                      ),
                      const SizedBox(height: 16),
                      RentCarTextField(
                        controller: _registrationCertificateController,
                        label: 'Registration Certificate Number',
                        hint: 'Enter official RC number',
                        icon: Icons.receipt_long_outlined,
                        validator: (value) => _requiredText(
                          value,
                          'registration certificate number',
                        ),
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
                          if (file != null) {
                            setState(() => _insuranceDocumentFile = file);
                          }
                        },
                        onRemove: () =>
                            setState(() => _insuranceDocumentFile = null),
                        onPreview: () =>
                            _showDocumentPreviewDialog(_insuranceDocumentFile!),
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
                        title: 'Fitness Certificate (FC)',
                        subtitle: 'Tap to pick fitness scan/PDF',
                        file: _fitnessDocumentFile,
                        icon: Icons.health_and_safety_outlined,
                        onPick: () async {
                          final file = await _pickDocument(
                            'Fitness Certificate (FC)',
                          );
                          if (file != null) {
                            setState(() => _fitnessDocumentFile = file);
                          }
                        },
                        onRemove: () =>
                            setState(() => _fitnessDocumentFile = null),
                        onPreview: () =>
                            _showDocumentPreviewDialog(_fitnessDocumentFile!),
                      ),
                      const SizedBox(height: 14),
                      RentCarTextField(
                        controller: _fitnessController,
                        label: 'Fitness Certificate Reference (Optional)',
                        hint: 'Enter fitness certificate reference number',
                        icon: Icons.health_and_safety_outlined,
                        textInputAction: TextInputAction.next,
                        readOnly: _isLoading,
                      ),
                      const SizedBox(height: 20),
                      _buildDocUploadCard(
                        title: 'Pollution Under Control (PUC)',
                        subtitle: 'Tap to pick PUC certificate scan/PDF',
                        file: _pucDocumentFile,
                        icon: Icons.wb_cloudy_outlined,
                        onPick: () async {
                          final file = await _pickDocument('PUC Certificate');
                          if (file != null) {
                            setState(() => _pucDocumentFile = file);
                          }
                        },
                        onRemove: () => setState(() => _pucDocumentFile = null),
                        onPreview: () =>
                            _showDocumentPreviewDialog(_pucDocumentFile!),
                      ),
                      const SizedBox(height: 14),
                      RentCarTextField(
                        controller: _pucController,
                        label: 'PUC Reference (Optional)',
                        hint: 'Enter PUC certificate number',
                        icon: Icons.wb_cloudy_outlined,
                        textInputAction: TextInputAction.next,
                        readOnly: _isLoading,
                      ),
                      const SizedBox(height: 20),
                      _buildDocUploadCard(
                        title: 'Permit Document',
                        subtitle: 'Tap to pick permit scan/PDF',
                        file: _permitDocumentFile,
                        icon: Icons.credit_card_outlined,
                        onPick: () async {
                          final file = await _pickDocument('Permit Document');
                          if (file != null) {
                            setState(() => _permitDocumentFile = file);
                          }
                        },
                        onRemove: () =>
                            setState(() => _permitDocumentFile = null),
                        onPreview: () =>
                            _showDocumentPreviewDialog(_permitDocumentFile!),
                      ),
                      const SizedBox(height: 14),
                      RentCarTextField(
                        controller: _permitController,
                        label: 'Permit Reference (Optional)',
                        hint: 'Enter permit reference number',
                        icon: Icons.credit_card_outlined,
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
                          if (file != null) {
                            setState(() => _dlDocumentFile = file);
                          }
                        },
                        onRemove: () => setState(() => _dlDocumentFile = null),
                        onPreview: () =>
                            _showDocumentPreviewDialog(_dlDocumentFile!),
                      ),
                      const SizedBox(height: 14),
                      RentCarTextField(
                        controller: _ownerIdController,
                        label: 'Owner ID Reference / DL Number (Optional)',
                        hint: 'Enter owner DL reference',
                        icon: Icons.badge_outlined,
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
          if (_isLoading ||
              _verificationState.isUploading ||
              _verificationState.isAnalyzing ||
              _verificationState.isVerifying)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: Center(
                  child: Card(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 24),
                          const Text(
                            'Document Verification In Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF103B66),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Please wait while we run OCR verification.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          _buildProgressRow(
                            'RC Book Document',
                            _verificationState.documentStatuses['rc'],
                          ),
                          _buildProgressRow(
                            'Insurance Policy',
                            _verificationState.documentStatuses['insurance'],
                          ),
                          _buildProgressRow(
                            'Fitness Certificate (FC)',
                            _verificationState.documentStatuses['fc'],
                          ),
                          _buildProgressRow(
                            'PUC Certificate',
                            _verificationState.documentStatuses['puc'],
                          ),
                          _buildProgressRow(
                            'Permit Document',
                            _verificationState.documentStatuses['permit'],
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
