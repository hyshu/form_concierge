import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:serverpod_auth_core_flutter/serverpod_auth_core_flutter.dart';

import '../../state/auth_state.dart';

class SetPasswordForm extends StatefulWidget {
  final Client client;
  final String registrationToken;
  final bool isLoading;
  final String? error;
  final ValueChanged<SurveyAuthState> onStateChanged;
  final VoidCallback onSuccess;

  const SetPasswordForm({
    super.key,
    required this.client,
    required this.registrationToken,
    required this.isLoading,
    this.error,
    required this.onStateChanged,
    required this.onSuccess,
  });

  @override
  State<SetPasswordForm> createState() => _SetPasswordFormState();
}

class _SetPasswordFormState extends State<SetPasswordForm> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      widget.onStateChanged(
        SurveyAuthState(
          isLoading: false,
          error: 'Please enter a password',
          viewMode: AuthViewMode.setPassword,
          registrationToken: widget.registrationToken,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      widget.onStateChanged(
        SurveyAuthState(
          isLoading: false,
          error: 'Passwords do not match',
          viewMode: AuthViewMode.setPassword,
          registrationToken: widget.registrationToken,
        ),
      );
      return;
    }

    if (password.length < 8) {
      widget.onStateChanged(
        SurveyAuthState(
          isLoading: false,
          error: 'Password must be at least 8 characters',
          viewMode: AuthViewMode.setPassword,
          registrationToken: widget.registrationToken,
        ),
      );
      return;
    }

    widget.onStateChanged(
      SurveyAuthState(
        isLoading: true,
        viewMode: AuthViewMode.setPassword,
        registrationToken: widget.registrationToken,
      ),
    );

    try {
      final auth = await widget.client.emailIdp.finishRegistration(
        registrationToken: widget.registrationToken,
        password: password,
      );
      await widget.client.auth.updateSignedInUser(auth);
      widget.onSuccess();
    } on Exception catch (e) {
      widget.onStateChanged(
        SurveyAuthState(
          isLoading: false,
          error: _parseError(e),
          viewMode: AuthViewMode.setPassword,
          registrationToken: widget.registrationToken,
        ),
      );
    }
  }

  String _parseError(Exception e) {
    final message = e.toString();
    if (message.contains('policyViolation')) {
      return 'Password does not meet security requirements.';
    }
    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Set Password',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a password for your account.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !widget.isLoading,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          decoration: const InputDecoration(
            labelText: 'Confirm Password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !widget.isLoading,
          onSubmitted: (_) => _submit(),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 16),
          Text(widget.error!, style: TextStyle(color: colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: widget.isLoading ? null : _submit,
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Complete Registration'),
        ),
      ],
    );
  }
}
