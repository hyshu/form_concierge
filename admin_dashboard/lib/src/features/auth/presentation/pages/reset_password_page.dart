import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../capsules/password_reset_capsule.dart';

/// Page for entering new password to complete reset.
class ResetPasswordPage extends RearchConsumer {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final resetManager = use(passwordResetCapsule);
    final controllers = use(passwordResetControllersCapsule);
    final colorScheme = Theme.of(context).colorScheme;

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
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: colorScheme.primary,
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
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () {
                        resetManager.reset();
                        controllers.clear();
                        context.go('/login');
                      },
                      child: Text(context.tr('Go to Login')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('New Password')),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_outlined,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.tr('Create New Password'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('Enter a new password for your account.'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: controllers.password,
                      decoration: InputDecoration(
                        labelText: context.tr('New Password'),
                        prefixIcon: const Icon(Icons.lock_outlined),
                      ),
                      obscureText: true,
                      enabled: !resetManager.state.isLoading,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controllers.confirmPassword,
                      decoration: InputDecoration(
                        labelText: context.tr('Confirm Password'),
                        prefixIcon: const Icon(Icons.lock_outlined),
                      ),
                      obscureText: true,
                      enabled: !resetManager.state.isLoading,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) =>
                          _submit(context, resetManager, controllers),
                    ),
                    if (resetManager.state.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        context.trMessage(resetManager.state.error!),
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: resetManager.state.isLoading
                          ? null
                          : () => _submit(context, resetManager, controllers),
                      child: resetManager.state.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text(context.tr('Reset Password')),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        resetManager.reset();
                        controllers.clear();
                        context.go('/login');
                      },
                      child: Text(context.tr('Cancel')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter a password'))),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('Password must be at least 8 characters'),
          ),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Passwords do not match'))),
      );
      return;
    }

    manager.finishPasswordReset(password);
  }
}
