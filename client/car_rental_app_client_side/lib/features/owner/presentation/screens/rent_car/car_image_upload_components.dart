import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum RentCarImageSlot {
  front,
  rear,
  interior,
  dashboard,
  additional,
}

extension RentCarImageSlotX on RentCarImageSlot {
  String get label => switch (this) {
        RentCarImageSlot.front => 'Front View',
        RentCarImageSlot.rear => 'Rear View',
        RentCarImageSlot.interior => 'Interior View',
        RentCarImageSlot.dashboard => 'Dashboard View',
        RentCarImageSlot.additional => 'Additional',
      };

  IconData get icon => switch (this) {
        RentCarImageSlot.front => Icons.photo_camera_front_outlined,
        RentCarImageSlot.rear => Icons.photo_camera_back_outlined,
        RentCarImageSlot.interior => Icons.chair_outlined,
        RentCarImageSlot.dashboard => Icons.dashboard_outlined,
        RentCarImageSlot.additional => Icons.photo_library_outlined,
      };

  bool get isRequired => this != RentCarImageSlot.additional;
}

enum RentCarImageUploadState { pending, uploading, uploaded, failed }

enum RentCarImageSourceChoice { camera, gallery }

typedef RentCarMultipartUpload = Future<List<String>> Function(
  List<XFile> files,
  ValueChanged<double> onProgress,
);

class RentCarUploadImageItem {
  const RentCarUploadImageItem({
    required this.id,
    required this.slot,
    this.file,
    this.bytes,
    this.uploadedUrl,
    this.state = RentCarImageUploadState.pending,
    this.progress = 0,
    this.errorMessage,
  });

  factory RentCarUploadImageItem.local({
    required String id,
    required RentCarImageSlot slot,
    required XFile file,
    required Uint8List bytes,
  }) {
    return RentCarUploadImageItem(
      id: id,
      slot: slot,
      file: file,
      bytes: bytes,
    );
  }

  factory RentCarUploadImageItem.remote({
    required String id,
    required RentCarImageSlot slot,
    required String url,
  }) {
    return RentCarUploadImageItem(
      id: id,
      slot: slot,
      uploadedUrl: url,
      state: RentCarImageUploadState.uploaded,
      progress: 1,
    );
  }

  final String id;
  final RentCarImageSlot slot;
  final XFile? file;
  final Uint8List? bytes;
  final String? uploadedUrl;
  final RentCarImageUploadState state;
  final double progress;
  final String? errorMessage;

  bool get hasLocalFile => file != null;
  bool get hasRemoteUrl => uploadedUrl != null && uploadedUrl!.isNotEmpty;
  bool get isUploaded => state == RentCarImageUploadState.uploaded || hasRemoteUrl;

  RentCarUploadImageItem copyWith({
    XFile? file,
    Uint8List? bytes,
    String? uploadedUrl,
    RentCarImageUploadState? state,
    double? progress,
    String? errorMessage,
  }) {
    return RentCarUploadImageItem(
      id: id,
      slot: slot,
      file: file ?? this.file,
      bytes: bytes ?? this.bytes,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
    );
  }
}

const List<RentCarImageSlot> rentCarRequiredImageSlots = <RentCarImageSlot>[
  RentCarImageSlot.front,
  RentCarImageSlot.rear,
  RentCarImageSlot.interior,
  RentCarImageSlot.dashboard,
];

Future<RentCarImageSourceChoice?> showRentCarImageSourceSheet(
  BuildContext context, {
  String title = 'Add car images',
}) {
  return showModalBottomSheet<RentCarImageSourceChoice>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF103B66),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a source for the next image.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF57718A),
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(RentCarImageSourceChoice.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Take Photo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(RentCarImageSourceChoice.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from Gallery'),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showRentCarImagePreviewDialog(
  BuildContext context,
  RentCarUploadImageItem item,
) {
  final imageWidget = item.hasRemoteUrl
      ? Image.network(
          item.uploadedUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)),
        )
      : Image.memory(
          item.bytes!,
          fit: BoxFit.contain,
        );

  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.slot.label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF103B66),
                    ),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: const Color(0xFFF4F7FB),
                    child: imageWidget,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.hasRemoteUrl ? item.uploadedUrl! : item.file?.name ?? 'Local image',
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class RentCarImageRequirementCard extends StatelessWidget {
  const RentCarImageRequirementCard({
    super.key,
    required this.selectedCount,
    required this.minCount,
    required this.maxCount,
    required this.missingSlots,
    required this.onAddSlot,
  });

  final int selectedCount;
  final int minCount;
  final int maxCount;
  final List<RentCarImageSlot> missingSlots;
  final ValueChanged<RentCarImageSlot> onAddSlot;

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
            Row(
              children: [
                const Icon(Icons.rule_folder_outlined, color: Color(0xFF1E5AA8)),
                const SizedBox(width: 10),
                Text(
                  'Image Requirements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF103B66),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _RequirementPill(
                  label: '$selectedCount selected',
                  color: const Color(0xFFEAF2FF),
                  textColor: const Color(0xFF103B66),
                ),
                _RequirementPill(
                  label: 'Min $minCount',
                  color: const Color(0xFFF1F8E9),
                  textColor: const Color(0xFF2E7D32),
                ),
                _RequirementPill(
                  label: 'Max $maxCount',
                  color: const Color(0xFFFFF4E5),
                  textColor: const Color(0xFFB26A00),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (missingSlots.isEmpty)
              const _RequirementStatusRow(
                icon: Icons.verified_rounded,
                label: 'All required images are present.',
                color: Color(0xFF2E7D32),
              )
            else ...[
              const _RequirementStatusRow(
                icon: Icons.warning_amber_rounded,
                label: 'Missing required images:',
                color: Color(0xFFC62828),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: missingSlots
                    .map(
                      (slot) => ActionChip(
                        avatar: Icon(slot.icon, size: 18),
                        label: Text(slot.label),
                        onPressed: () => onAddSlot(slot),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RentCarImageDropArea extends StatelessWidget {
  const RentCarImageDropArea({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD8E4F2)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: Color(0xFF1E5AA8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload car images',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF103B66),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to take a photo or choose multiple images from the gallery.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF57718A),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF8EA6BE)),
          ],
        ),
      ),
    );
  }
}

class RentCarImageGrid extends StatelessWidget {
  const RentCarImageGrid({
    super.key,
    required this.items,
    required this.onPreview,
    required this.onReplace,
    required this.onRemove,
    required this.onReorder,
  });

  final List<RentCarUploadImageItem> items;
  final ValueChanged<RentCarUploadImageItem> onPreview;
  final ValueChanged<RentCarUploadImageItem> onReplace;
  final ValueChanged<RentCarUploadImageItem> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 700 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return DragTarget<int>(
              onWillAcceptWithDetails: (details) => details.data != index,
              onAcceptWithDetails: (details) => onReorder(details.data, index),
              builder: (context, candidateData, rejectedData) {
                return LongPressDraggable<int>(
                  data: index,
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: 150,
                      child: _ImageTileCard(
                        item: item,
                        isDragging: true,
                        onPreview: () {},
                        onReplace: () {},
                        onRemove: () {},
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.45,
                    child: _ImageTileCard(
                      item: item,
                      isDragging: false,
                      onPreview: () => onPreview(item),
                      onReplace: () => onReplace(item),
                      onRemove: () => onRemove(item),
                    ),
                  ),
                  child: _ImageTileCard(
                    item: item,
                    isDragging: false,
                    onPreview: () => onPreview(item),
                    onReplace: () => onReplace(item),
                    onRemove: () => onRemove(item),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ImageTileCard extends StatelessWidget {
  const _ImageTileCard({
    required this.item,
    required this.isDragging,
    required this.onPreview,
    required this.onReplace,
    required this.onRemove,
  });

  final RentCarUploadImageItem item;
  final bool isDragging;
  final VoidCallback onPreview;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final preview = item.hasRemoteUrl
        ? Image.network(
            item.uploadedUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackPreview(item),
          )
        : item.bytes != null
            ? Image.memory(item.bytes!, fit: BoxFit.cover)
            : _fallbackPreview(item);

    return Card(
      elevation: isDragging ? 8 : 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        onTap: onPreview,
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: ColoredBox(
                      color: const Color(0xFFF4F7FB),
                      child: SizedBox.expand(child: preview),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.slot.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: PopupMenuButton<String>(
                      icon: const CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.more_vert_rounded, size: 18),
                      ),
                      onSelected: (value) {
                        if (value == 'preview') {
                          onPreview();
                        } else if (value == 'replace') {
                          onReplace();
                        } else if (value == 'remove') {
                          onRemove();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'preview', child: Text('Preview')),
                        PopupMenuItem(value: 'replace', child: Text('Replace')),
                        PopupMenuItem(value: 'remove', child: Text('Remove')),
                      ],
                    ),
                  ),
                  if (item.state == RentCarImageUploadState.uploading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.2),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ),
                    ),
                  if (item.isUploaded)
                    const Positioned(
                      right: 10,
                      bottom: 10,
                      child: _UploadBadge(
                        label: 'Uploaded',
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  if (item.state == RentCarImageUploadState.failed)
                    const Positioned(
                      right: 10,
                      bottom: 10,
                      child: _UploadBadge(
                        label: 'Retry',
                        color: Color(0xFFC62828),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.slot.icon, size: 18, color: const Color(0xFF1E5AA8)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item.slot.label,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: const Color(0xFF103B66),
                                fontWeight: FontWeight.w700,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (item.state == RentCarImageUploadState.uploading)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: item.progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE6EEF7),
                      ),
                    )
                  else if (item.state == RentCarImageUploadState.failed)
                    Text(
                      item.errorMessage ?? 'Upload failed. Retry replacement or upload again.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFC62828),
                          ),
                    )
                  else if (item.isUploaded)
                    Text(
                      item.uploadedUrl ?? 'Uploaded image URL ready',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF57718A),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      item.file?.name ?? 'Local file selected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF57718A),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackPreview(RentCarUploadImageItem item) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.slot.icon, size: 40, color: const Color(0xFF8EA6BE)),
          const SizedBox(height: 8),
          Text(
            item.slot.label,
            style: const TextStyle(
              color: Color(0xFF57718A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementPill extends StatelessWidget {
  const _RequirementPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _RequirementStatusRow extends StatelessWidget {
  const _RequirementStatusRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _UploadBadge extends StatelessWidget {
  const _UploadBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}