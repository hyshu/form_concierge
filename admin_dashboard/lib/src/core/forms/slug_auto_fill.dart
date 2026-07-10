import 'package:flutter/widgets.dart';

import '../localization/app_localizations.dart';

final _asciiTextPattern = RegExp(r'^[\x00-\x7F]+$');
final _nonSlugCharacterPattern = RegExp(r'[^a-z0-9]+');
final _edgeHyphenPattern = RegExp(r'^-+|-+$');
final _duplicateHyphenPattern = RegExp(r'-{2,}');
final _slugPattern = RegExp(r'^[a-z0-9-]+$');
final _lowercaseLetterPattern = RegExp(r'[a-z]');

class SlugAutoFill {
  String? _lastAutoSlug;

  void reset() => _lastAutoSlug = null;

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
  if (requireAsciiSource && !_asciiTextPattern.hasMatch(trimmed)) {
    return null;
  }

  final slug = trimmed
      .toLowerCase()
      .replaceAll(_nonSlugCharacterPattern, '-')
      .replaceAll(_edgeHyphenPattern, '')
      .replaceAll(_duplicateHyphenPattern, '-');
  if (slug.isEmpty) return null;
  if (requireLowercaseLetter && !hasLowercaseSlugLetter(slug)) return null;
  return slug;
}

String? validateSlug(
  BuildContext context,
  String? value, {
  bool requireLowercaseLetter = true,
}) {
  final slug = value?.trim() ?? '';
  if (slug.isEmpty) return context.tr('Slug is required');
  if (!isSlugText(slug)) {
    return context.tr('Only lowercase letters, numbers, and hyphens allowed');
  }
  if (requireLowercaseLetter && !hasLowercaseSlugLetter(slug)) {
    return context.tr('Slug must include a lowercase letter');
  }
  return null;
}

bool isSlugText(String value) => _slugPattern.hasMatch(value);

bool hasLowercaseSlugLetter(String value) =>
    _lowercaseLetterPattern.hasMatch(value);
