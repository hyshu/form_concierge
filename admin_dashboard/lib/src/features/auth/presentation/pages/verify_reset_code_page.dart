import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../capsules/password_reset_capsule.dart';

/// Page for entering verification code for password reset.
class VerifyResetCodePage extends RearchConsumer {
  const VerifyResetCodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final resetManager = use(passwordResetCapsule);
    final controllers = use(passwordResetControllersCapsule);
    final colorScheme = Theme.of(context).colorScheme;

    // Redirect if no email (user navigated directly)
    if (resetManager.state.email == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/forgot-password');
      });
      return const SizedBox.shrink();
    }

    // Navigate to next step when state changes
    if (resetManager.state.step == PasswordResetStep.enterNewPassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/reset-password');
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Verify Code')),
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
                      Icons.mark_email_read_outlined,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.tr('Check Your Email'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('We sent a verification code to:'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resetManager.state.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: controllers.code,
                      decoration: InputDecoration(
                        labelText: context.tr('Verification Code'),
                        prefixIcon: const Icon(Icons.pin_outlined),
                        hintText: context.tr('Enter 6-digit code'),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !resetManager.state.isLoading,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(resetManager, controllers),
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
                          : () => _submit(resetManager, controllers),
                      child: resetManager.state.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text(context.tr('Verify')),
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
    PasswordResetManager manager,
    PasswordResetControllers controllers,
  ) {
    final code = controllers.code.text.trim();
    if (code.isEmpty) return;
    manager.verifyCode(code);
  }
}
