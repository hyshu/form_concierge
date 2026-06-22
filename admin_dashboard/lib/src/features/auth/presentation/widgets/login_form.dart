import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../capsules/login_form_capsule.dart';

/// Login form widget with email and password fields.
class LoginForm extends StatelessWidget {
  final LoginFormControllers controllers;
  final bool isLoading;
  final String? error;
  final VoidCallback onSubmit;
  final bool isRegistration;
  final VoidCallback? onForgotPassword;

  const LoginForm({
    super.key,
    required this.controllers,
    required this.isLoading,
    this.error,
    required this.onSubmit,
    this.isRegistration = false,
    this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controllers.email,
            decoration: InputDecoration(
              labelText: context.tr('Email'),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controllers.password,
            decoration: InputDecoration(
              labelText: context.tr('Password'),
              prefixIcon: const Icon(Icons.lock_outlined),
            ),
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
          ),
          if (!isRegistration && onForgotPassword != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading ? null : onForgotPassword,
                child: Text(context.tr('Forgot Password?')),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              context.trMessage(error!),
              style: TextStyle(color: colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    context.tr(isRegistration ? 'Create Account' : 'Login'),
                  ),
          ),
        ],
      ),
    );
  }
}
