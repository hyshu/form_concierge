import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../state/auth_state.dart';

/// Fixed verification code used when email verification is disabled.
/// Must match the server-side devVerificationCode in server.dart.
const _devVerificationCode = '00000000';

class RegisterForm extends StatefulWidget {
  final Client client;
  final bool isLoading;
  final String? error;
  final ValueChanged<SurveyAuthState> onStateChanged;
  final VoidCallback onSwitchToLogin;

  const RegisterForm({
    super.key,
    required this.client,
    required this.isLoading,
    this.error,
    required this.onStateChanged,
    required this.onSwitchToLogin,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      widget.onStateChanged(
        SurveyAuthState(
          isLoading: false,
          error: 'Please enter your email',
          viewMode: AuthViewMode.register,
        ),
      );
      return;
    }

    widget.onStateChanged(
      const SurveyAuthState(isLoading: true, viewMode: AuthViewMode.register),
    );

    try {
      // Check if email verification is required
      final config = await widget.client.config.getPublicConfig();

      final requestId = await widget.client.emailIdp.startRegistration(
        email: email,
      );

      if (!config.requireEmailVerification) {
        // Skip verification step - auto-verify with fixed code
        final registrationToken =
            await widget.client.emailIdp.verifyRegistrationCode(
          accountRequestId: requestId,
          verificationCode: _devVerificationCode,
        );

        widget.onStateChanged(
          SurveyAuthState(
            isLoading: false,
            viewMode: AuthViewMode.setPassword,
            registrationToken: registrationToken,
            registrationEmail: email,
          ),
        );
      } else {
        // Proceed to verification code entry
        widget.onStateChanged(
          SurveyAuthState(
            isLoading: false,
            viewMode: AuthViewMode.verifyCode,
            registrationRequestId: requestId,
            registrationEmail: email,
          ),
        );
      }
    } on Exception catch (e) {
      widget.onStateChanged(
        SurveyAuthState(
          isLoading: false,
          error: _parseError(e),
          viewMode: AuthViewMode.register,
        ),
      );
    }
  }

  String _parseError(Exception e) {
    final message = e.toString();
    if (message.contains('emailAlreadyInUse')) {
      return 'This email is already registered. Please sign in instead.';
    }
    if (message.contains('invalidEmail')) {
      return 'Please enter a valid email address.';
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
          'Create Account',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email to get started.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
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
              : const Text('Continue'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: widget.isLoading ? null : widget.onSwitchToLogin,
          child: const Text('Already have an account? Sign in'),
        ),
      ],
    );
  }
}
