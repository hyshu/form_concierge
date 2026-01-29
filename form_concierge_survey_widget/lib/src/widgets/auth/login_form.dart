import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:serverpod_auth_core_flutter/serverpod_auth_core_flutter.dart';

import '../../state/auth_state.dart';

class LoginForm extends StatefulWidget {
  final Client client;
  final bool isLoading;
  final String? error;
  final ValueChanged<SurveyAuthState> onStateChanged;
  final VoidCallback onSuccess;
  final VoidCallback onSwitchToRegister;

  const LoginForm({
    super.key,
    required this.client,
    required this.isLoading,
    this.error,
    required this.onStateChanged,
    required this.onSuccess,
    required this.onSwitchToRegister,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      widget.onStateChanged(
        SurveyAuthState(
          isLoading: false,
          error: 'Please enter email and password',
          viewMode: AuthViewMode.login,
        ),
      );
      return;
    }

    widget.onStateChanged(
      const SurveyAuthState(isLoading: true, viewMode: AuthViewMode.login),
    );

    try {
      final auth = await widget.client.emailIdp.login(
        email: email,
        password: password,
      );
      await widget.client.auth.updateSignedInUser(auth);
      widget.onSuccess();
    } on Exception catch (e) {
      widget.onStateChanged(
        SurveyAuthState(
          isLoading: false,
          error: _parseError(e),
          viewMode: AuthViewMode.login,
        ),
      );
    }
  }

  String _parseError(Exception e) {
    final message = e.toString();
    if (message.contains('invalidCredentials')) {
      return 'Invalid email or password';
    }
    if (message.contains('tooManyAttempts')) {
      return 'Too many login attempts. Please try again later.';
    }
    return 'Login failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            autofillHints: const [AutofillHints.password],
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
                : const Text('Sign In'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.isLoading ? null : widget.onSwitchToRegister,
            child: const Text("Don't have an account? Create one"),
          ),
        ],
      ),
    );
  }
}
