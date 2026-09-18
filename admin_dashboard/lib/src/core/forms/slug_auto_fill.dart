import 'package:flutter/widgets.dart';

import '../localization/app_localizations.dart';

final _asciiTextPattern = RegExp(r'^[\x00-\x7F]+$');
final _nonSlugCharacterPattern = RegExp(r'[^a-z0-9]+');
final _edgeHyphenPattern = RegExp(r'^-+|-+$');
final _duplicateHyphenPattern = RegExp(r'-{2,}');
final _slugPattern = RegExp(r'^[a-z0-9-]+$');
final _lowercaseLetterPattern = RegExp(r'[a-z]');

/// Suggests a slug from a title while preserving manual edits.
class SlugAutoFill {
  String? _lastAutoSlug;

  /// Clears the remembered automatic slug before editing a different record.
  void reset() => _lastAutoSlug = null;

  /// Updates the slug from the title when it is empty or still matches the previous
  /// suggestion.
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

/// Returns a valid slug derived from the supplied text, or null when none can be formed.
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

/// Returns a localized validation error for an invalid slug, or null when valid.
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

/// Returns whether the text matches the accepted slug character pattern.
bool isSlugText(String value) => _slugPattern.hasMatch(value);

/// Returns whether the slug contains at least one lowercase letter.
bool hasLowercaseSlugLetter(String value) =>
    _lowercaseLetterPattern.hasMatch(value);
