import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:go_router/go_router.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../capsules/password_reset_capsule.dart';
import '../widgets/auth_card_scaffold.dart';

/// Page for entering email to start password reset.
class ForgotPasswordPage extends RearchConsumer {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(context, use) {
    final resetManager = use(passwordResetCapsule);
    final controllers = use(passwordResetControllersCapsule);

    // Navigate to next step when state changes
    if (resetManager.state.step == PasswordResetStep.enterCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/verify-reset-code');
      });
    }

    return AuthCardScaffold(
      icon: LucideIcons.rotateCcwKey,
      title: context.tr('Reset Your Password'),
      subtitle: Text(
        context.tr(
          'Enter your email address and we\'ll send you a verification code.',
        ),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: HuxTokens.textSecondary(context),
        ),
        textAlign: TextAlign.center,
      ),
      children: [
        HuxInput(
          controller: controllers.email,
          label: context.tr('Email'),
          prefixIcon: const Icon(LucideIcons.mail),
          keyboardType: TextInputType.emailAddress,
          enabled: !resetManager.state.isLoading,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(resetManager, controllers),
        ),
        if (resetManager.state.error != null) ...[
          const SizedBox(height: 16),
          Text(
            context.trMessage(resetManager.state.error!),
            style: TextStyle(color: HuxTokens.textDestructive(context)),
          ),
        ],
        const SizedBox(height: 24),
        HuxButton(
          onPressed: resetManager.state.isLoading
              ? null
              : () => _submit(resetManager, controllers),
          isLoading: resetManager.state.isLoading,
          width: HuxButtonWidth.expand,
          icon: LucideIcons.send,
          child: Text(context.tr('Send Code')),
        ),
        const SizedBox(height: 16),
        HuxButton(
          onPressed: () {
            resetManager.reset();
            controllers.clear();
            context.pop();
          },
          variant: HuxButtonVariant.secondary,
          width: HuxButtonWidth.expand,
          child: Text(context.tr('Back to Login')),
        ),
      ],
    );
  }

  void _submit(
    PasswordResetManager manager,
    PasswordResetControllers controllers,
  ) {
    final email = controllers.email.text.trim();
    if (email.isEmpty) return;
    manager.startPasswordReset(email);
  }
}
