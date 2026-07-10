import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_icon_action_button.dart';
import 'localized_text_helpers.dart';

/// Callback used to translate the primary locale into the remaining locales.
typedef LocalizedTextTranslate =
    Future<Map<String, String>> Function({
      required String sourceLocale,
      required String sourceText,
      required List<String> targetLocales,
    });

class LocalizedTextFieldGroup extends StatefulWidget {
  const LocalizedTextFieldGroup({
    super.key,
    required this.controllers,
    required this.primaryLocale,
    required this.labelText,
    this.locales = formContentLocaleCodes,
    this.hintText,
    this.enabled = true,
    this.maxLines = 1,
    this.requiredMessage,
    this.textInputAction,
    this.autofocus = false,
    this.aiTranslateEnabled = false,
    this.onTranslate,
  });

  final Map<String, TextEditingController> controllers;
  final String primaryLocale;
  final String labelText;
  final Iterable<String> locales;
  final String? hintText;
  final bool enabled;
  final int maxLines;
  final String? requiredMessage;
  final TextInputAction? textInputAction;
  final bool autofocus;

  /// When true and [onTranslate] is set, show a sparkle action to auto-fill
  /// secondary locales from the primary locale text.
  final bool aiTranslateEnabled;
  final LocalizedTextTranslate? onTranslate;

  @override
  State<LocalizedTextFieldGroup> createState() =>
      _LocalizedTextFieldGroupState();
}

class _LocalizedTextFieldGroupState extends State<LocalizedTextFieldGroup> {
  bool _isTranslating = false;
  String? _translateError;
  bool _otherLanguagesExpanded = false;

  String get _primary {
    final supported = orderedFormContentLocales(widget.locales);
    final normalized = normalizedPrimaryLocale(widget.primaryLocale);
    return supported.contains(normalized) ? normalized : supported.first;
  }

  List<String> get _secondaryLocales {
    return orderedFormContentLocales(
      widget.locales,
    ).where((locale) => locale != _primary).toList();
  }

  TextEditingController? get _primaryController => widget.controllers[_primary];

  bool get _canTranslate {
    if (!widget.aiTranslateEnabled || widget.onTranslate == null) {
      return false;
    }
    if (!widget.enabled || _isTranslating || _secondaryLocales.isEmpty) {
      return false;
    }
    return (_primaryController?.text.trim().isNotEmpty ?? false);
  }

  @override
  void initState() {
    super.initState();
    _primaryController?.addListener(_onPrimaryChanged);
  }

  @override
  void didUpdateWidget(LocalizedTextFieldGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSupported = orderedFormContentLocales(oldWidget.locales);
    final oldNormalized = normalizedPrimaryLocale(oldWidget.primaryLocale);
    final oldPrimary = oldSupported.contains(oldNormalized)
        ? oldNormalized
        : oldSupported.first;
    if (oldWidget.controllers != widget.controllers || oldPrimary != _primary) {
      oldWidget.controllers[oldPrimary]?.removeListener(_onPrimaryChanged);
      _primaryController?.addListener(_onPrimaryChanged);
    }
  }

  @override
  void dispose() {
    _primaryController?.removeListener(_onPrimaryChanged);
    super.dispose();
  }

  void _onPrimaryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _runTranslate() async {
    final onTranslate = widget.onTranslate;
    final source = _primaryController?.text.trim() ?? '';
    if (onTranslate == null || source.isEmpty || _isTranslating) return;

    setState(() {
      _isTranslating = true;
      _translateError = null;
    });

    try {
      final translations = await onTranslate(
        sourceLocale: _primary,
        sourceText: source,
        targetLocales: _secondaryLocales,
      );
      if (!mounted) return;
      for (final locale in _secondaryLocales) {
        final text = translations[locale]?.trim();
        if (text == null || text.isEmpty) continue;
        widget.controllers[locale]?.text = text;
      }
      setState(() {
        _isTranslating = false;
        _otherLanguagesExpanded = true;
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      setState(() {
        _isTranslating = false;
        _translateError = message.startsWith('Failed to translate: ')
            ? message
            : 'Failed to translate: $message';
      });
    }
  }

  @override
  Widget build(context) {
    final primary = _primary;
    final secondaryLocales = _secondaryLocales;
    final showTranslate =
        widget.aiTranslateEnabled &&
        widget.onTranslate != null &&
        secondaryLocales.isNotEmpty;

    String? requiredValidator(String? value) {
      if (widget.requiredMessage != null &&
          (value == null || value.trim().isEmpty)) {
        return widget.requiredMessage;
      }
      return null;
    }

    String? secondaryRequiredValidator() {
      if (widget.requiredMessage == null) return null;
      for (final locale in secondaryLocales) {
        if ((widget.controllers[locale]?.text ?? '').trim().isEmpty) {
          return widget.requiredMessage;
        }
      }
      return null;
    }

    Widget fieldFor(
      String locale, {
      required bool isPrimary,
      String? Function(String?)? validator,
    }) {
      return _LocalizedField(
        controller: widget.controllers[locale],
        label: isPrimary
            ? widget.labelText
            : '${widget.labelText} (${formContentLocaleLabels[locale]!})',
        hint: widget.hintText,
        enabled: widget.enabled && !_isTranslating,
        maxLines: widget.maxLines,
        textInputAction: widget.textInputAction,
        autofocus: isPrimary && widget.autofocus,
        validator: validator,
      );
    }

    final primaryField = fieldFor(
      primary,
      isPrimary: true,
      validator: widget.requiredMessage == null ? null : requiredValidator,
    );

    final primaryRow = showTranslate
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: primaryField),
              const SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(top: widget.maxLines > 1 ? 28 : 28),
                child: _isTranslating
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : HuxIconActionButton(
                        icon: LucideIcons.sparkles,
                        onPressed: _canTranslate ? _runTranslate : null,
                        tooltip: context.tr('Translate other languages'),
                      ),
              ),
            ],
          )
        : primaryField;

    if (secondaryLocales.isEmpty) primaryRow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        primaryRow,
        if (_translateError != null) ...[
          const SizedBox(height: 8),
          Text(
            context.trMessage(_translateError!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: HuxTokens.textDestructive(context),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _OtherLanguagesExpansion(
          expanded: _otherLanguagesExpanded,
          onExpandedChanged: (value) {
            setState(() => _otherLanguagesExpanded = value);
          },
          secondaryValidator: secondaryRequiredValidator,
          children: [
            for (final locale in secondaryLocales)
              fieldFor(
                locale,
                isPrimary: false,
                validator: widget.requiredMessage == null
                    ? null
                    : requiredValidator,
              ),
          ],
        ),
      ],
    );
  }
}

/// Collapsible secondary locales that stay mounted for form validation.
class _OtherLanguagesExpansion extends StatefulWidget {
  const _OtherLanguagesExpansion({
    required this.children,
    required this.expanded,
    required this.onExpandedChanged,
    this.secondaryValidator,
  });

  final List<Widget> children;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final String? Function()? secondaryValidator;

  @override
  State<_OtherLanguagesExpansion> createState() =>
      _OtherLanguagesExpansionState();
}

class _OtherLanguagesExpansionState extends State<_OtherLanguagesExpansion> {
  @override
  Widget build(context) => FormField<void>(
    validator: (_) => widget.secondaryValidator?.call(),
    builder: (field) {
      if (field.hasError && !widget.expanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !widget.expanded) {
            widget.onExpandedChanged(true);
          }
        });
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => widget.onExpandedChanged(!widget.expanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('Other languages'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Icon(
                      widget.expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 18,
                      color: HuxTokens.iconSecondary(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (field.hasError && field.errorText != null) ...[
            Text(
              field.errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HuxTokens.textDestructive(context),
              ),
            ),
            const SizedBox(height: 8),
          ],
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: widget.expanded ? 1 : 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    widget.children[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _LocalizedField extends StatelessWidget {
  const _LocalizedField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.maxLines,
    this.hint,
    this.textInputAction,
    this.autofocus = false,
    this.validator,
  });

  final TextEditingController? controller;
  final String label;
  final bool enabled;
  final int maxLines;
  final String? hint;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final String? Function(String?)? validator;

  @override
  Widget build(context) {
    if (maxLines > 1) {
      return HuxTextarea(
        controller: controller,
        label: label,
        hint: hint,
        enabled: enabled,
        minLines: maxLines,
        maxLines: maxLines + 2,
        textInputAction: textInputAction,
        validator: validator,
      );
    }

    return HuxInput(
      controller: controller,
      label: label,
      hint: hint,
      enabled: enabled,
      textInputAction: textInputAction,
      validator: validator,
    );
  }
}
