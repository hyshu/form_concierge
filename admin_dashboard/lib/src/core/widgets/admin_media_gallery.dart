import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../localization/app_localizations.dart';

/// Simple in-memory cache so expanding many responses reuses bytes.
/// Bounded (oldest-inserted evicted first) and cleared on logout.
final Map<String, Uint8List> _adminMediaCache = {};
const _adminMediaCacheMaxEntries = 100;

/// Drop cached media bytes (e.g. when the admin session ends).
void clearAdminMediaCache() => _adminMediaCache.clear();

/// Horizontal/wrapping gallery of authenticated media thumbnails.
class AdminMediaGallery extends StatelessWidget {
  final Client client;
  final List<String> fileKeys;
  final double thumbnailSize;

  const AdminMediaGallery({
    super.key,
    required this.client,
    required this.fileKeys,
    this.thumbnailSize = 96,
  });

  @override
  Widget build(context) {
    if (fileKeys.isEmpty) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final key in fileKeys)
          AdminMediaThumbnail(
            key: ValueKey(key),
            client: client,
            fileKey: key,
            size: thumbnailSize,
          ),
      ],
    );
  }
}

/// Loads one media object with the admin session and shows a tappable preview.
class AdminMediaThumbnail extends StatefulWidget {
  final Client client;
  final String fileKey;
  final double size;

  const AdminMediaThumbnail({
    super.key,
    required this.client,
    required this.fileKey,
    this.size = 96,
  });

  @override
  State<AdminMediaThumbnail> createState() => _AdminMediaThumbnailState();
}

class _AdminMediaThumbnailState extends State<AdminMediaThumbnail> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _load();
  }

  @override
  void didUpdateWidget(covariant AdminMediaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileKey != widget.fileKey ||
        oldWidget.client != widget.client) {
      _bytesFuture = _load();
    }
  }

  Future<Uint8List> _load() async {
    final cached = _adminMediaCache[widget.fileKey];
    if (cached != null) return cached;
    final bytes = await widget.client.survey.getMediaBytes(
      widget.fileKey,
      authenticated: true,
    );
    final data = Uint8List.fromList(bytes);
    while (_adminMediaCache.length >= _adminMediaCacheMaxEntries) {
      _adminMediaCache.remove(_adminMediaCache.keys.first);
    }
    _adminMediaCache[widget.fileKey] = data;
    return data;
  }

  @override
  Widget build(context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        final child = switch (snapshot.connectionState) {
          ConnectionState.waiting => Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: HuxTokens.primary(context),
              ),
            ),
          ),
          _ when snapshot.hasError => Tooltip(
            message: context.tr('Failed to load image'),
            child: Icon(
              LucideIcons.imageOff,
              color: colorScheme.error,
              semanticLabel: context.tr('Failed to load image'),
            ),
          ),
          _ when snapshot.hasData => Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
          _ => Icon(
            LucideIcons.image,
            color: HuxTokens.iconSecondary(context),
          ),
        };

        return Material(
          color: HuxTokens.surfaceSecondary(context),
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: snapshot.hasData
                ? () => _showFullPreview(context, snapshot.data!)
                : null,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: child,
            ),
          ),
        );
      },
    );
  }

  void _showFullPreview(BuildContext context, Uint8List bytes) =>
      showDialog<void>(
        context: context,
        builder: (context) {
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
              child: Stack(
                children: [
                  InteractiveViewer(
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        semanticLabel: context.tr('Close'),
                      ),
                      tooltip: context.tr('Close'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
