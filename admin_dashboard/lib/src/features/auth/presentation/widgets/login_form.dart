import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

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
