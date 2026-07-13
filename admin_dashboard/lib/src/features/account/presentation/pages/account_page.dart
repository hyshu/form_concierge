import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/forms/password_validation.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_admin_shell.dart';
import '../../../../core/widgets/hux_states.dart';

class AccountPage extends RearchConsumer {
  const AccountPage({super.key});

  @override
  Widget build(context, use) {
    final client = use(clientCapsule);
    final user = client.auth.signedInUser;
    return HuxAdminShell(
      title: context.tr('Account'),
      selectedItemId: 'account',
      showUsers: user?.role == AdminRole.admin,
      showSettings: user?.role == AdminRole.admin,
      child: HuxPageBody(
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HuxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Your account'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AccountValue(
                    label: context.tr('Email'),
                    value: user?.email ?? '—',
                  ),
                  const SizedBox(height: 16),
                  _AccountValue(
                    label: context.tr('Role'),
                    value: context.tr(_roleLabel(user?.role)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ChangePasswordCard(client: client),
          ],
        ),
      ),
    );
  }
}

class _AccountValue extends StatelessWidget {
  const _AccountValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: HuxTokens.textSecondary(context),
        ),
      ),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.bodyLarge),
    ],
  );
}

class _ChangePasswordCard extends StatefulWidget {
  const _ChangePasswordCard({required this.client});

  final Client client;

  @override
  State<_ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends State<_ChangePasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isSaving = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(context) => HuxCard(
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('Change password'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('Update the password used to sign in.'),
            style: TextStyle(color: HuxTokens.textSecondary(context)),
          ),
          const SizedBox(height: 20),
          HuxInput(
            controller: _currentPassword,
            label: context.tr('Current Password'),
            prefixIcon: const Icon(LucideIcons.lockKeyhole),
            obscureText: true,
            enabled: !_isSaving,
            textInputAction: TextInputAction.next,
            validator: (value) => value == null || value.isEmpty
                ? context.tr('Current password is required')
                : null,
          ),
          const SizedBox(height: 16),
          HuxInput(
            controller: _newPassword,
            label: context.tr('New Password'),
            hint: context.tr('At least 8 characters'),
            prefixIcon: const Icon(LucideIcons.keyRound),
            obscureText: true,
            enabled: !_isSaving,
            textInputAction: TextInputAction.next,
            validator: (value) => !hasMinimumPasswordLength(value ?? '')
                ? context.tr('Password must be at least 8 characters')
                : null,
          ),
          const SizedBox(height: 16),
          HuxInput(
            controller: _confirmPassword,
            label: context.tr('Confirm Password'),
            prefixIcon: const Icon(LucideIcons.keyRound),
            obscureText: true,
            enabled: !_isSaving,
            textInputAction: TextInputAction.done,
            validator: (value) => value != _newPassword.text
                ? context.tr('Passwords do not match')
                : null,
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              context.trMessage(_error!),
              style: TextStyle(color: HuxTokens.textDestructive(context)),
            ),
          ],
          if (_success != null) ...[
            const SizedBox(height: 16),
            Text(
              context.tr(_success!),
              style: TextStyle(color: HuxTokens.textSuccess(context)),
            ),
          ],
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: HuxButton(
              onPressed: _isSaving ? null : _submit,
              isLoading: _isSaving,
              icon: LucideIcons.keyRound,
              child: Text(context.tr('Change password')),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
      _success = null;
    });
    try {
      await widget.client.userAdmin.changeOwnPassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      if (mounted) setState(() => _success = 'Password changed successfully');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

String _roleLabel(AdminRole? role) => switch (role) {
  AdminRole.admin => 'Admin',
  AdminRole.editor => 'Editor',
  AdminRole.viewer => 'Viewer',
  null => 'Unknown',
};
