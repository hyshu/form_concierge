import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:go_router/go_router.dart';
import 'package:hux/hux.dart';

import '../../../../core/forms/password_validation.dart';
import '../../../../core/localization/app_localizations.dart';
import '../capsules/password_reset_capsule.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/auth_page_scaffold.dart';

/// Page for entering new password to complete reset.
class ResetPasswordPage extends RearchConsumer {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final resetManager = use(passwordResetCapsule);
    final controllers = use(passwordResetControllersCapsule);

    // Redirect if no reset token (user navigated directly)
    if (resetManager.state.resetToken == null &&
        resetManager.state.step != PasswordResetStep.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/forgot-password');
      });
      return const SizedBox.shrink();
    }

    // Show success state
    if (resetManager.state.step == PasswordResetStep.completed) {
      return AuthPageScaffold(
        scrollable: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.circleCheck,
              size: 80,
              color: HuxTokens.primary(context),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('Password Reset Complete'),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                'Your password has been successfully reset. You can now login with your new password.',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HuxTokens.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            HuxButton(
              onPressed: () {
                resetManager.reset();
                controllers.clear();
                context.go('/login');
              },
              icon: LucideIcons.logIn,
              child: Text(context.tr('Go to Login')),
            ),
          ],
        ),
      );
    }

    return AuthCardScaffold(
      icon: LucideIcons.lock,
      title: context.tr('Create New Password'),
      subtitle: Text(
        context.tr('Enter a new password for your account.'),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: HuxTokens.textSecondary(context),
        ),
        textAlign: TextAlign.center,
      ),
      children: [
        HuxInput(
          controller: controllers.password,
          label: context.tr('New Password'),
          prefixIcon: const Icon(LucideIcons.lock),
          obscureText: true,
          enabled: !resetManager.state.isLoading,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        HuxInput(
          controller: controllers.confirmPassword,
          label: context.tr('Confirm Password'),
          prefixIcon: const Icon(LucideIcons.lock),
          obscureText: true,
          enabled: !resetManager.state.isLoading,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(context, resetManager, controllers),
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
              : () => _submit(context, resetManager, controllers),
          isLoading: resetManager.state.isLoading,
          width: HuxButtonWidth.expand,
          icon: LucideIcons.keyRound,
          child: Text(context.tr('Reset Password')),
        ),
        const SizedBox(height: 16),
        HuxButton(
          onPressed: () {
            resetManager.reset();
            controllers.clear();
            context.go('/login');
          },
          variant: HuxButtonVariant.secondary,
          width: HuxButtonWidth.expand,
          child: Text(context.tr('Cancel')),
        ),
      ],
    );
  }

  void _submit(
    BuildContext context,
    PasswordResetManager manager,
    PasswordResetControllers controllers,
  ) {
    final password = controllers.password.text;
    final confirmPassword = controllers.confirmPassword.text;

    if (password.isEmpty) {
      context.showHuxSnackbar(
        message: context.tr('Please enter a password'),
        variant: HuxSnackbarVariant.error,
      );
      return;
    }

    if (!hasMinimumPasswordLength(password)) {
      context.showHuxSnackbar(
        message: context.tr('Password must be at least 8 characters'),
        variant: HuxSnackbarVariant.error,
      );
      return;
    }

    if (password != confirmPassword) {
      context.showHuxSnackbar(
        message: context.tr('Passwords do not match'),
        variant: HuxSnackbarVariant.error,
      );
      return;
    }

    manager.finishPasswordReset(password);
  }
}
