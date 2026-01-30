import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../capsules/survey_form_capsule.dart';

/// Form widget for creating/editing survey basic info (title, slug, etc.).
class SurveyForm extends StatefulWidget {
  final SurveyFormControllers controllers;
  final Survey? existingSurvey;
  final bool isSaving;
  final String? error;
  final Future<void> Function({
    required String title,
    required String slug,
    String? description,
    required AuthRequirement authRequirement,
  })
  onSave;

  const SurveyForm({
    super.key,
    required this.controllers,
    this.existingSurvey,
    required this.isSaving,
    this.error,
    required this.onSave,
  });

  @override
  State<SurveyForm> createState() => _SurveyFormState();
}

class _SurveyFormState extends State<SurveyForm> {
  final _formKey = GlobalKey<FormState>();
  AuthRequirement _authRequirement = AuthRequirement.anonymous;

  @override
  void initState() {
    super.initState();
    if (widget.existingSurvey != null) {
      widget.controllers.populateFrom(widget.existingSurvey!);
      _authRequirement = widget.existingSurvey!.authRequirement;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: widget.controllers.title,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'Enter survey title',
            ),
            enabled: !widget.isSaving,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.controllers.slug,
            decoration: InputDecoration(
              labelText: 'URL Slug',
              hintText: 'my-survey',
              prefixText: '/s/',
              prefixStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            enabled: !widget.isSaving,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Slug is required';
              }
              if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
                return 'Only lowercase letters, numbers, and hyphens allowed';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.controllers.description,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Brief description of the survey',
            ),
            enabled: !widget.isSaving,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Authentication',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<AuthRequirement>(
            segments: const [
              ButtonSegment(
                value: AuthRequirement.anonymous,
                label: Text('Anonymous'),
                icon: Icon(Icons.public),
              ),
              ButtonSegment(
                value: AuthRequirement.authenticated,
                label: Text('Login Required'),
                icon: Icon(Icons.lock_outline),
              ),
            ],
            selected: {_authRequirement},
            onSelectionChanged: widget.isSaving
                ? null
                : (selected) {
                    setState(() {
                      _authRequirement = selected.first;
                    });
                  },
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.error!,
              style: TextStyle(color: colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.isSaving ? null : _submit,
            child: widget.isSaving
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    widget.existingSurvey != null
                        ? 'Save Changes'
                        : 'Create Survey',
                  ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(
        title: widget.controllers.title.text.trim(),
        slug: widget.controllers.slug.text.trim(),
        description: widget.controllers.description.text.trim().isEmpty
            ? null
            : widget.controllers.description.text.trim(),
        authRequirement: _authRequirement,
      );
    }
  }
}
