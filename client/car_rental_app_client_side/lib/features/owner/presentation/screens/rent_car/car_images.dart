import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:car_rental_app_client_side/features/auth/services/auth_service.dart';

import 'car_documents.dart';
import 'car_image_upload_components.dart';
import 'rent_car_shared.dart';

class CarImagesScreen extends StatefulWidget {
  const CarImagesScreen({
    super.key,
    required this.draft,
    this.onUploadRequested,
  });

  final RentCarDraft draft;
  final RentCarMultipartUpload? onUploadRequested;

  @override
  State<CarImagesScreen> createState() => _CarImagesScreenState();
}

class _CarImagesScreenState extends State<CarImagesScreen> {
  static const int _minImages = 4;
  static const int _maxImages = 12;

  final ImagePicker _imagePicker = ImagePicker();
  final List<RentCarUploadImageItem> _items = <RentCarUploadImageItem>[];

  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _statusMessage;

  List<RentCarImageSlot> get _requiredSlots => rentCarRequiredImageSlots;

  List<RentCarImageSlot> get _missingRequiredSlots => _requiredSlots
      .where(
        (slot) => !_items.any((item) => item.slot == slot && item.isUploaded),
      )
      .toList();

  List<XFile> get _pendingLocalFiles => _items
      .where((item) => item.file != null && !item.isUploaded)
      .map((item) => item.file!)
      .toList();

  List<String> get _uploadedUrls => _items
      .where((item) => item.isUploaded && item.uploadedUrl != null)
      .map((item) => item.uploadedUrl!)
      .toList();

  @override
  void initState() {
    super.initState();
    _seedExistingImages();
  }

  void _seedExistingImages() {
    // Seed local photos first (if any)
    for (var index = 0; index < widget.draft.localPhotos.length; index++) {
      final file = widget.draft.localPhotos[index];
      final slot = index < _requiredSlots.length
          ? _requiredSlots[index]
          : RentCarImageSlot.additional;

      final id = _buildImageId();
      _items.add(
        RentCarUploadImageItem(
          id: id,
          slot: slot,
          file: file,
          state: RentCarImageUploadState.pending,
        ),
      );

      file.readAsBytes().then((bytes) {
        if (!mounted) return;
        setState(() {
          final idx = _items.indexWhere((item) => item.id == id);
          if (idx != -1) {
            _items[idx] = _items[idx].copyWith(bytes: bytes);
          }
        });
      });
    }

    // Seed remote photos if any
    for (var index = 0; index < widget.draft.selectedPhotos.length; index++) {
      final url = widget.draft.selectedPhotos[index];
      final slot = _items.length < _requiredSlots.length
          ? _requiredSlots[_items.length]
          : RentCarImageSlot.additional;
      _items.add(
        RentCarUploadImageItem.remote(id: 'seed_$index', slot: slot, url: url),
      );
    }
  }

  String _buildImageId() {
    return 'img_${DateTime.now().microsecondsSinceEpoch}_${_items.length}';
  }

  void _showMessage(String message) {
    setState(() => _statusMessage = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSourceSelection({RentCarImageSlot? targetSlot}) async {
    final source = await showRentCarImageSourceSheet(context);
    if (source == null) {
      return;
    }

    if (source == RentCarImageSourceChoice.camera) {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 82,
      );
      if (file != null) {
        await _addPickedFiles([file], targetSlot: targetSlot);
      }
      return;
    }

    if (targetSlot != null) {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (file != null) {
        await _addPickedFiles([file], targetSlot: targetSlot);
      }
      return;
    }

    final files = await _imagePicker.pickMultiImage(imageQuality: 82);
    if (files.isNotEmpty) {
      await _addPickedFiles(files);
    }
  }

  void _handleAddSlot(RentCarImageSlot slot) {
    _handleSourceSelection(targetSlot: slot);
  }

  void _handleReplaceImage(RentCarUploadImageItem item) {
    _handleSourceSelection(targetSlot: item.slot);
  }

  Future<void> _addPickedFiles(
    List<XFile> files, {
    RentCarImageSlot? targetSlot,
  }) async {
    if (_items.length >= _maxImages && targetSlot == null) {
      _showMessage('You can add up to $_maxImages images only.');
      return;
    }

    final freeSlots = List<RentCarImageSlot>.from(_missingRequiredSlots);
    final appended = <RentCarUploadImageItem>[];

    for (final file in files) {
      if (_items.length + appended.length >= _maxImages) {
        _showMessage(
          'Maximum $_maxImages images allowed. Extra files were ignored.',
        );
        break;
      }

      final itemSlot =
          targetSlot ??
          (freeSlots.isNotEmpty
              ? freeSlots.removeAt(0)
              : RentCarImageSlot.additional);
      final bytes = await file.readAsBytes();

      final item = RentCarUploadImageItem.local(
        id: _buildImageId(),
        slot: itemSlot,
        file: file,
        bytes: bytes,
      );

      if (targetSlot != null) {
        _upsertImageForSlot(item);
      } else {
        appended.add(item);
      }

      if (targetSlot != null) {
        break;
      }
    }

    if (appended.isNotEmpty) {
      setState(() => _items.addAll(appended));
    }
  }

  void _upsertImageForSlot(RentCarUploadImageItem newItem) {
    setState(() {
      final existingIndex = _items.indexWhere(
        (item) => item.slot == newItem.slot,
      );
      if (existingIndex == -1) {
        _items.add(newItem);
      } else {
        _items[existingIndex] = newItem;
      }
    });
  }

  void _removeImage(RentCarUploadImageItem item) {
    setState(() {
      _items.removeWhere((current) => current.id == item.id);
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  Future<void> _uploadSelectedImages() async {
    if (!AuthService.isAuthenticated) {
      _showMessage('Please log in before uploading images.');
      return;
    }

    if (_pendingLocalFiles.isEmpty) {
      _showMessage('Select images first, then upload them.');
      return;
    }

    if (widget.onUploadRequested == null) {
      _showMessage(
        'Multipart upload is ready. Connect the backend callback to upload files and return permanent URLs.',
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _statusMessage = 'Uploading selected files...';
      for (var index = 0; index < _items.length; index++) {
        final item = _items[index];
        if (item.file != null) {
          _items[index] = item.copyWith(
            state: RentCarImageUploadState.uploading,
            progress: 0,
            errorMessage: null,
          );
        }
      }
    });

    try {
      final returnedUrls = await widget.onUploadRequested!(_pendingLocalFiles, (
        progress,
      ) {
        if (!mounted) {
          return;
        }
        setState(() => _uploadProgress = progress.clamp(0, 1));
      });

      if (!mounted) {
        return;
      }

      if (returnedUrls.length != _pendingLocalFiles.length) {
        _showMessage(
          'Upload completed, but the returned URL count did not match the selected files.',
        );
        return;
      }

      var urlIndex = 0;
      setState(() {
        for (var index = 0; index < _items.length; index++) {
          final current = _items[index];
          if (current.file == null) {
            continue;
          }
          _items[index] = current.copyWith(
            uploadedUrl: returnedUrls[urlIndex++],
            state: RentCarImageUploadState.uploaded,
            progress: 1,
            errorMessage: null,
          );
        }
      });

      _showMessage(
        'Images uploaded successfully. Returned URLs are now displayed.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        for (var index = 0; index < _items.length; index++) {
          final current = _items[index];
          if (current.file != null) {
            _items[index] = current.copyWith(
              state: RentCarImageUploadState.failed,
              errorMessage: 'Upload failed. Retry or replace the image.',
            );
          }
        }
      });
      _showMessage('Upload failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  Future<void> _goNext() async {
    if (_items.length < _minImages) {
      _showMessage('Add at least $_minImages images before continuing.');
      return;
    }

    final missingSlots = _requiredSlots
        .where(
          (slot) => !_items.any(
            (item) =>
                item.slot == slot && (item.file != null || item.hasRemoteUrl),
          ),
        )
        .toList();

    if (missingSlots.isNotEmpty) {
      _showMessage('Please add all required images before continuing.');
      return;
    }

    final localFiles = _items
        .where((item) => item.file != null)
        .map((item) => item.file!)
        .toList();
    final remoteUrls = _items
        .where((item) => item.hasRemoteUrl)
        .map((item) => item.uploadedUrl!)
        .toList();

    final updatedDraft = widget.draft.copyWith(
      localPhotos: localFiles,
      selectedPhotos: remoteUrls,
    );

    if (!mounted) return;

    Navigator.of(
      context,
    ).push(buildRentCarSlideRoute(CarDocumentsScreen(draft: updatedDraft)));
  }

  @override
  Widget build(BuildContext context) {
    return RentCarScreenScaffold(
      currentStep: 3,
      title: 'Car Images',
      subtitle:
          'Select car photos from the camera or gallery, then preview, reorder, and save them locally.',
      onBack: _goBack,
      onNext: _goNext,
      nextLabel: 'Submit',
      backLabel: 'Back',
      child: Column(
        children: [
          RentCarImageRequirementCard(
            selectedCount: _items.length,
            minCount: _minImages,
            maxCount: _maxImages,
            missingSlots: _requiredSlots
                .where(
                  (slot) => !_items.any(
                    (item) =>
                        item.slot == slot &&
                        (item.file != null || item.hasRemoteUrl),
                  ),
                )
                .toList(),
            onAddSlot: _handleAddSlot,
          ),
          const SizedBox(height: 16),
          RentCarImageDropArea(onTap: _handleSourceSelection),
          const SizedBox(height: 16),
          RentCarSectionCard(
            title: 'Preview Grid',
            icon: Icons.grid_view_rounded,
            child: Column(
              children: [
                RentCarImageGrid(
                  items: _items,
                  onPreview: (item) =>
                      showRentCarImagePreviewDialog(context, item),
                  onReplace: _handleReplaceImage,
                  onRemove: _removeImage,
                  onReorder: _reorderImages,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          RentCarSectionCard(
            title: 'Photo Guidelines',
            icon: Icons.tips_and_updates_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Use bright, straight-on shots for best presentation.'),
                SizedBox(height: 8),
                Text('Keep the car clean and visible in every photo.'),
                SizedBox(height: 8),
                Text('Upload the required four images first, then add extras.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
