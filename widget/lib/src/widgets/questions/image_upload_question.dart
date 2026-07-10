import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:image_picker/image_picker.dart';

/// Image bytes chosen for upload (or returned from host-side processing).
class PickedSurveyImage {
  final List<int> bytes;
  final String contentType;

  const PickedSurveyImage({required this.bytes, required this.contentType});

  PickedSurveyImage copyWith({List<int>? bytes, String? contentType}) {
    return PickedSurveyImage(
      bytes: bytes ?? this.bytes,
      contentType: contentType ?? this.contentType,
    );
  }
}

/// Host transform applied after pick and before upload.
///
/// Return a (possibly compressed/resized) image to upload, or `null` to skip
/// that image without failing the whole batch.
typedef ProcessSurveyImage =
    Future<PickedSurveyImage?> Function(PickedSurveyImage image);

/// Local image selection + upload for [QuestionType.imageUpload].
class ImageUploadQuestion extends StatefulWidget {
  final Client client;
  final int maxFiles;
  final List<String> fileKeys;
  final String locale;
  final bool enabled;
  final ValueChanged<List<String>> onChanged;

  /// Ensures an anonymous session exists before upload (main-form answers).
  final Future<void> Function()? ensureAuthenticated;

  /// Optional host-side resize/compress/edit step before upload.
  final ProcessSurveyImage? processImage;

  /// Optional override for tests / host apps.
  final Future<List<PickedSurveyImage>> Function({required int maxImages})?
  pickImages;

  const ImageUploadQuestion({
    super.key,
    required this.client,
    required this.maxFiles,
    required this.fileKeys,
    required this.locale,
    required this.onChanged,
    this.enabled = true,
    this.ensureAuthenticated,
    this.processImage,
    this.pickImages,
  });

  @override
  State<ImageUploadQuestion> createState() => _ImageUploadQuestionState();
}

class _ImageUploadQuestionState extends State<ImageUploadQuestion> {
  bool _uploading = false;
  String? _localError;
  final Map<String, Uint8List> _previews = {};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canAdd =
        widget.enabled &&
        !_uploading &&
        widget.fileKeys.length < widget.maxFiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.fileKeys.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in widget.fileKeys)
                _ImageChip(
                  bytes: _previews[key],
                  onRemove: widget.enabled && !_uploading
                      ? () {
                          final next = List<String>.from(widget.fileKeys)
                            ..remove(key);
                          _previews.remove(key);
                          widget.onChanged(next);
                        }
                      : null,
                ),
            ],
          ),
        if (widget.fileKeys.isNotEmpty) const SizedBox(height: 12),
        Text(
          FormContentMessages.text(
            widget.locale,
            'maxPhotosReached',
          ).replaceAll('{count}', '${widget.maxFiles}'),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: canAdd ? _pickAndUpload : null,
          icon: _uploading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              : const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            FormContentMessages.text(
              widget.locale,
              _uploading ? 'uploadingPhotos' : 'addPhotos',
            ),
          ),
        ),
        if (_localError != null) ...[
          const SizedBox(height: 8),
          Text(
            _localError!,
            style: TextStyle(color: colorScheme.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Future<void> _pickAndUpload() async {
    setState(() {
      _uploading = true;
      _localError = null;
    });
    try {
      await widget.ensureAuthenticated?.call();
      if (!widget.client.anonymous.isAuthenticated) {
        await widget.client.anonymous.createAccount();
      }

      final remaining = widget.maxFiles - widget.fileKeys.length;
      final picked = await (widget.pickImages ?? defaultPickSurveyImages)(
        maxImages: remaining,
      );
      if (picked.isEmpty) {
        if (mounted) setState(() => _uploading = false);
        return;
      }

      final keys = List<String>.from(widget.fileKeys);
      final process = widget.processImage;
      for (final image in picked) {
        if (keys.length >= widget.maxFiles) break;
        final prepared = process == null ? image : await process(image);
        if (prepared == null || prepared.bytes.isEmpty) continue;
        final uploaded = await widget.client.survey.uploadMedia(
          bytes: prepared.bytes,
          contentType: prepared.contentType,
        );
        keys.add(uploaded.key);
        _previews[uploaded.key] = Uint8List.fromList(prepared.bytes);
      }
      widget.onChanged(keys);
      if (mounted) setState(() => _uploading = false);
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _localError = FormContentMessages.text(
          widget.locale,
          'photoUploadFailed',
        );
      });
    }
  }
}

Future<List<PickedSurveyImage>> defaultPickSurveyImages({
  required int maxImages,
}) async {
  final picker = ImagePicker();
  if (maxImages <= 1) {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (file == null) return const [];
    final bytes = await file.readAsBytes();
    return [
      PickedSurveyImage(
        bytes: bytes,
        contentType: _contentTypeForName(file.name, file.mimeType),
      ),
    ];
  }

  final files = await picker.pickMultiImage(
    imageQuality: 85,
    maxWidth: 2048,
    maxHeight: 2048,
    limit: maxImages,
  );
  final result = <PickedSurveyImage>[];
  for (final file in files.take(maxImages)) {
    final bytes = await file.readAsBytes();
    result.add(
      PickedSurveyImage(
        bytes: bytes,
        contentType: _contentTypeForName(file.name, file.mimeType),
      ),
    );
  }
  return result;
}

String _contentTypeForName(String name, String? mimeType) {
  if (mimeType != null && mimeType.startsWith('image/')) return mimeType;
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

class _ImageChip extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback? onRemove;

  const _ImageChip({required this.bytes, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: bytes == null
              ? Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant)
              : Image.memory(bytes!, fit: BoxFit.cover),
        ),
        if (onRemove != null)
          Positioned(
            top: -8,
            right: -8,
            child: IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              onPressed: onRemove,
              icon: const Icon(Icons.close),
              tooltip: 'Remove',
            ),
          ),
      ],
    );
  }
}
