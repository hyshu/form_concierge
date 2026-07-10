import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/forms/email_validation.dart';
import '../../../../core/forms/password_validation.dart';
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
  Widget build(context) => HuxDialog(
    title: context.tr('Create User'),
    size: HuxDialogSize.medium,
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HuxInput(
              controller: _emailController,
              label: context.tr('Email'),
              hint: 'user@example.com',
              prefixIcon: const Icon(LucideIcons.mail),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('Email is required');
                }
                if (!isValidEmailAddress(value)) {
                  return context.tr('Please enter a valid email');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            HuxInput(
              controller: _passwordController,
              label: context.tr('Password'),
              prefixIcon: const Icon(LucideIcons.lock),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr('Password is required');
                }
                if (!hasMinimumPasswordLength(value)) {
                  return context.tr('Password must be at least 8 characters');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Role'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: HuxTokens.textSecondary(context),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: HuxDropdown<AdminRole>(
                value: _role,
                useItemWidgetAsValue: true,
                items: [
                  HuxDropdownItem(
                    value: AdminRole.viewer,
                    child: Text(context.tr('Viewer')),
                  ),
                  HuxDropdownItem(
                    value: AdminRole.editor,
                    child: Text(context.tr('Editor')),
                  ),
                  HuxDropdownItem(
                    value: AdminRole.admin,
                    child: Text(context.tr('Admin')),
                  ),
                ],
                onChanged: (value) => setState(() => _role = value),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(_roleDescription(_role)),
              style: TextStyle(color: HuxTokens.textSecondary(context)),
            ),
          ],
        ),
      ),
    ),
    actions: [
      HuxButton(
        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
        variant: HuxButtonVariant.secondary,
        child: Text(context.tr('Cancel')),
      ),
      HuxButton(
        onPressed: _isSubmitting ? null : _submit,
        isLoading: _isSubmitting,
        child: Text(context.tr('Create')),
      ),
    ],
  );
}

String _roleDescription(AdminRole role) => switch (role) {
  AdminRole.admin => 'Can manage users, surveys, responses, and settings.',
  AdminRole.editor => 'Can create surveys and manage responses.',
  AdminRole.viewer => 'Can view surveys and responses only.',
};
