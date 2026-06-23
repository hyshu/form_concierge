import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:go_router/go_router.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../capsules/password_reset_capsule.dart';
import '../widgets/auth_card_scaffold.dart';

/// Page for entering verification code for password reset.
class VerifyResetCodePage extends RearchConsumer {
  const VerifyResetCodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final resetManager = use(passwordResetCapsule);
    final controllers = use(passwordResetControllersCapsule);

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

    return AuthCardScaffold(
      icon: LucideIcons.mailCheck,
      title: context.tr('Check Your Email'),
      subtitle: Column(
        children: [
          Text(
            context.tr('We sent a verification code to:'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HuxTokens.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            resetManager.state.email ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      children: [
        HuxInput(
          controller: controllers.code,
          label: context.tr('Verification Code'),
          prefixIcon: const Icon(LucideIcons.hash),
          hint: context.tr('Enter 6-digit code'),
          keyboardType: TextInputType.number,
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
          icon: LucideIcons.check,
          child: Text(context.tr('Verify')),
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
    PasswordResetManager manager,
    PasswordResetControllers controllers,
  ) {
    final code = controllers.code.text.trim();
    if (code.isEmpty) return;
    manager.verifyCode(code);
  }
}
