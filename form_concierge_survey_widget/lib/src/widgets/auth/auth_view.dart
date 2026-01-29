import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../state/auth_state.dart';
import 'login_form.dart';
import 'register_form.dart';
import 'verify_code_form.dart';
import 'set_password_form.dart';

class AuthView extends StatelessWidget {
  final Client client;
  final SurveyAuthState authState;
  final ValueChanged<SurveyAuthState> onAuthStateChanged;
  final VoidCallback onAuthSuccess;

  const AuthView({
    super.key,
    required this.client,
    required this.authState,
    required this.onAuthStateChanged,
    required this.onAuthSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Authentication Required',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please sign in to complete this survey.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildCurrentView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    return switch (authState.viewMode) {
      AuthViewMode.login => LoginForm(
        client: client,
        isLoading: authState.isLoading,
        error: authState.error,
        onStateChanged: onAuthStateChanged,
        onSuccess: onAuthSuccess,
        onSwitchToRegister: () {
          onAuthStateChanged(
            authState.copyWith(viewMode: AuthViewMode.register, error: null),
          );
        },
      ),
      AuthViewMode.register => RegisterForm(
        client: client,
        isLoading: authState.isLoading,
        error: authState.error,
        onStateChanged: onAuthStateChanged,
        onSwitchToLogin: () {
          onAuthStateChanged(
            authState.copyWith(viewMode: AuthViewMode.login, error: null),
          );
        },
      ),
      AuthViewMode.verifyCode => VerifyCodeForm(
        client: client,
        email: authState.registrationEmail!,
        requestId: authState.registrationRequestId!,
        isLoading: authState.isLoading,
        error: authState.error,
        onStateChanged: onAuthStateChanged,
        onBack: () {
          onAuthStateChanged(
            authState.copyWith(viewMode: AuthViewMode.register, error: null),
          );
        },
      ),
      AuthViewMode.setPassword => SetPasswordForm(
        client: client,
        registrationToken: authState.registrationToken!,
        isLoading: authState.isLoading,
        error: authState.error,
        onStateChanged: onAuthStateChanged,
        onSuccess: onAuthSuccess,
      ),
    };
  }
}
