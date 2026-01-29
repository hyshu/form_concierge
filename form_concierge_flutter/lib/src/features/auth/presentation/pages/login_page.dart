import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:go_router/go_router.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/auth_state_capsule.dart';
import '../../../../core/capsules/public_config_capsule.dart';
import '../capsules/login_form_capsule.dart';
import '../widgets/login_form.dart';

/// Login page for admin authentication.
class LoginPage extends RearchConsumer {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final authManager = use(authStateCapsule);
    final configManager = use(publicConfigCapsule);
    final controllers = use(loginFormControllersCapsule);
    final colorScheme = Theme.of(context).colorScheme;

    // Check for first user and load config on mount
    use.effect(
      () {
        authManager.checkFirstUser();
        configManager.loadConfig();
        return null;
      },
      [],
    );

    final isFirstUser = authManager.state.isFirstUser == true;
    final hasCheckedFirstUser = authManager.state.hasCheckedFirstUser;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Form Concierge',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin Dashboard',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (!hasCheckedFirstUser)
                      const CircularProgressIndicator()
                    else if (isFirstUser) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Welcome! Create your admin account to get started.',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      LoginForm(
                        controllers: controllers,
                        isLoading: authManager.state.isLoading,
                        error: authManager.state.error,
                        isRegistration: true,
                        onSubmit: () => authManager.registerFirstUser(
                          controllers.email.text.trim(),
                          controllers.password.text,
                        ),
                      ),
                    ] else
                      LoginForm(
                        controllers: controllers,
                        isLoading: authManager.state.isLoading,
                        error: authManager.state.error,
                        isRegistration: false,
                        onSubmit: () => authManager.login(
                          controllers.email.text.trim(),
                          controllers.password.text,
                        ),
                        onForgotPassword:
                            configManager.state.passwordResetEnabled
                            ? () => context.push('/forgot-password')
                            : null,
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
}
