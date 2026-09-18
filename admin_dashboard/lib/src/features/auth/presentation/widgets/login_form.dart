import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../capsules/login_form_capsule.dart';

/// Login form widget with email and password fields.
class LoginForm extends StatelessWidget {
  /// The text controllers and validation key used by the form.
  final LoginFormControllers controllers;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// The error message, when the operation could not complete.
  final String? error;

  /// Called when the respondent requests submission.
  final VoidCallback onSubmit;

  /// Whether the form is creating the first administrator account.
  final bool isRegistration;

  /// Called when the user requests the password reset flow.
  final VoidCallback? onForgotPassword;

  /// An optional CAPTCHA widget displayed before authentication.
  final Widget? captcha;

  /// Creates LoginForm with the supplied values.
  const LoginForm({
    super.key,
    required this.controllers,
    required this.isLoading,
    this.error,
    required this.onSubmit,
    this.isRegistration = false,
    this.onForgotPassword,
    this.captcha,
  });

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => AutofillGroup(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HuxInput(
          controller: controllers.email,
          label: context.tr('Email'),
          prefixIcon: const Icon(LucideIcons.mail),
          keyboardType: TextInputType.emailAddress,
          enabled: !isLoading,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        HuxInput(
          controller: controllers.password,
          label: context.tr('Password'),
          prefixIcon: const Icon(LucideIcons.lock),
          obscureText: true,
          enabled: !isLoading,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        if (!isRegistration && onForgotPassword != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: HuxButton(
              onPressed: isLoading ? null : onForgotPassword,
              variant: HuxButtonVariant.ghost,
              size: HuxButtonSize.small,
              child: Text(context.tr('Forgot Password?')),
            ),
          ),
        ],
        if (captcha != null) ...[
          const SizedBox(height: 16),
          captcha!,
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            context.trMessage(error!),
            style: TextStyle(color: HuxTokens.textDestructive(context)),
          ),
        ],
        const SizedBox(height: 24),
        HuxButton(
          onPressed: isLoading ? null : onSubmit,
          isLoading: isLoading,
          width: HuxButtonWidth.expand,
          icon: isRegistration ? LucideIcons.userPlus : LucideIcons.logIn,
          child: Text(
            context.tr(isRegistration ? 'Create Account' : 'Login'),
          ),
        ),
      ],
    ),
  );
}
