import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/localization/app_localizations.dart';

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AdminRole _role = AdminRole.viewer;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      Navigator.of(context).pop({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': _role,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(context.tr('Create User')),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: context.tr('Email'),
                hintText: 'user@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('Email is required');
                }
                if (!value.contains('@')) {
                  return context.tr('Please enter a valid email');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: context.tr('Password'),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr('Password is required');
                }
                if (value.length < 8) {
                  return context.tr('Password must be at least 8 characters');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AdminRole>(
              initialValue: _role,
              decoration: InputDecoration(labelText: context.tr('Role')),
              items: [
                DropdownMenuItem(
                  value: AdminRole.viewer,
                  child: Text(context.tr('Viewer')),
                ),
                DropdownMenuItem(
                  value: AdminRole.editor,
                  child: Text(context.tr('Editor')),
                ),
                DropdownMenuItem(
                  value: AdminRole.admin,
                  child: Text(context.tr('Admin')),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _role = value);
              },
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(_roleDescription(_role)),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('Create')),
        ),
      ],
    );
  }
}

String _roleDescription(AdminRole role) {
  return switch (role) {
    AdminRole.admin => 'Can manage users, surveys, responses, and settings.',
    AdminRole.editor => 'Can create surveys and manage responses.',
    AdminRole.viewer => 'Can view surveys and responses only.',
  };
}
