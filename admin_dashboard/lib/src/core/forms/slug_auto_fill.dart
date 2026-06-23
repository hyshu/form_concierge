import 'package:flutter/widgets.dart';

class SlugAutoFill {
  String? _lastAutoSlug;

  void reset() {
    _lastAutoSlug = null;
  }

  void update({
    required TextEditingController slugController,
    required Iterable<String?> sourceValues,
    bool requireAsciiSource = true,
    bool requireLowercaseLetter = true,
  }) {
    final currentSlug = slugController.text.trim();
    if (currentSlug.isNotEmpty && currentSlug != _lastAutoSlug) return;

    for (final value in sourceValues.whereType<String>()) {
      final slug = slugFromText(
        value,
        requireAsciiSource: requireAsciiSource,
        requireLowercaseLetter: requireLowercaseLetter,
      );
      if (slug == null) continue;
      _lastAutoSlug = slug;
      if (currentSlug != slug) slugController.text = slug;
      return;
    }
  }
}

String? slugFromText(
  String value, {
  bool requireAsciiSource = true,
  bool requireLowercaseLetter = true,
}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (requireAsciiSource && !RegExp(r'^[\x00-\x7F]+$').hasMatch(trimmed)) {
    return null;
  }

  final slug = trimmed
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '')
      .replaceAll(RegExp(r'-{2,}'), '-');
  if (slug.isEmpty) return null;
  if (requireLowercaseLetter && !RegExp(r'[a-z]').hasMatch(slug)) return null;
  return slug;
}
