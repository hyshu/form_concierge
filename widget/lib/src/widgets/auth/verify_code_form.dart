import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../state/auth_state.dart';

class VerifyCodeForm extends StatefulWidget {
  final Client client;
  final String email;
  final UuidValue requestId;
  final bool isLoading;
  final String? error;
  final ValueChanged<SurveyAuthState> onStateChanged;
  final VoidCallback onBack;

  const VerifyCodeForm({
    super.key,
    required this.client,
    required this.email,
    required this.requestId,
    required this.isLoading,
    this.error,
    required this.onStateChanged,
    required this.onBack,
  });

  @override
  State<VerifyCodeForm> createState() => _VerifyCodeFormState();
}

class _VerifyCodeFormState extends State<VerifyCodeForm> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      widget.onStateChanged(
        SurveyAuthState(
          isLoading: false,
          error: 'Please enter the verification code',
          viewMode: AuthViewMode.verifyCode,
          registrationRequestId: widget.requestId,
          registrationEmail: widget.email,
        ),
      );
      return;
    }

    widget.onStateChanged(
      SurveyAuthState(
        isLoading: true,
        viewMode: AuthViewMode.verifyCode,
        registrationRequestId: widget.requestId,
        registrationEmail: widget.email,
      ),
    );

    try {
      final token = await widget.client.emailIdp.verifyRegistrationCode(
        accountRequestId: widget.requestId,
        verificationCode: code,
      );

      widget.onStateChanged(
        SurveyAuthState(
          isLoading: false,
          viewMode: AuthViewMode.setPassword,
          registrationToken: token,
          registrationEmail: widget.email,
        ),
      );
    } on Exception catch (e) {
      widget.onStateChanged(
        SurveyAuthState(
          isLoading: false,
          error: _parseError(e),
          viewMode: AuthViewMode.verifyCode,
          registrationRequestId: widget.requestId,
          registrationEmail: widget.email,
        ),
      );
    }
  }

  String _parseError(Exception e) {
    final message = e.toString();
    if (message.contains('invalidVerificationCode')) {
      return 'Invalid verification code. Please try again.';
    }
    if (message.contains('expired')) {
      return 'Verification code has expired. Please request a new one.';
    }
    return 'Verification failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verify Email',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the verification code sent to ${widget.email}',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Verification Code',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
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
              : const Text('Verify'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: widget.isLoading ? null : widget.onBack,
          child: const Text('Back'),
        ),
      ],
    );
  }
}
