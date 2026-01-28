import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:go_router/go_router.dart';

import '../capsules/password_reset_capsule.dart';

/// Page for entering email to start password reset.
class ForgotPasswordPage extends RearchConsumer {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final resetManager = use(passwordResetCapsule);
    final controllers = use(passwordResetControllersCapsule);
    final colorScheme = Theme.of(context).colorScheme;

    // Navigate to next step when state changes
    if (resetManager.state.step == PasswordResetStep.enterCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/verify-reset-code');
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
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
                      Icons.lock_reset_outlined,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Reset Your Password',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your email address and we\'ll send you a verification code.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: controllers.email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      enabled: !resetManager.state.isLoading,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(resetManager, controllers),
                    ),
                    if (resetManager.state.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        resetManager.state.error!,
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
                          : const Text('Send Code'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        resetManager.reset();
                        controllers.clear();
                        context.pop();
                      },
                      child: const Text('Back to Login'),
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
    final email = controllers.email.text.trim();
    if (email.isEmpty) return;
    manager.startPasswordReset(email);
  }
}
