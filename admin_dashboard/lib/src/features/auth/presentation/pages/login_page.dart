import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:go_router/go_router.dart';
import 'package:hux/hux.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/auth_state_capsule.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/capsules/public_config_capsule.dart';
import '../capsules/login_form_capsule.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/login_form.dart';

/// Login page for admin authentication.
class LoginPage extends RearchConsumer {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final authManager = use(authStateCapsule);
    final configManager = use(publicConfigCapsule);
    final controllers = use(loginFormControllersCapsule);

    // Load login prerequisites after stored auth restoration has completed.
    use.effect(
      () {
        if (authManager.state.hasCheckedAuth &&
            !authManager.state.isAuthenticated) {
          authManager.checkFirstUser();
          configManager.loadConfig();
        }
        return null;
      },
      [
        authManager.state.hasCheckedAuth,
        authManager.state.isAuthenticated,
      ],
    );

    final isFirstUser = authManager.state.isFirstUser == true;
    final hasCheckedFirstUser = authManager.state.hasCheckedFirstUser;

    return AuthPageScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.clipboardList,
            size: 64,
            color: HuxTokens.primary(context),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('Form Concierge'),
            style:
                Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(
                  color: HuxTokens.primary(context),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('Admin Dashboard'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: HuxTokens.textSecondary(context),
            ),
          ),
          const SizedBox(height: 48),
          if (!hasCheckedFirstUser)
            const HuxLoading(size: HuxLoadingSize.large)
          else if (isFirstUser) ...[
            HuxCard(
              child: Row(
                children: [
                  Icon(LucideIcons.info, color: HuxTokens.primary(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr(
                        'Welcome! Create your admin account to get started.',
                      ),
                      style: TextStyle(color: HuxTokens.textSecondary(context)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            HuxCard(
              child: LoginForm(
                controllers: controllers,
                isLoading: authManager.state.isLoading,
                error: authManager.state.error,
                isRegistration: true,
                onSubmit: () => authManager.registerFirstUser(
                  controllers.email.text.trim(),
                  controllers.password.text,
                ),
              ),
            ),
          ] else
            HuxCard(
              child: LoginForm(
                controllers: controllers,
                isLoading: authManager.state.isLoading,
                error: authManager.state.error,
                isRegistration: false,
                onSubmit: () => authManager.login(
                  controllers.email.text.trim(),
                  controllers.password.text,
                ),
                onForgotPassword: configManager.state.passwordResetEnabled
                    ? () => context.push('/forgot-password')
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
