import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';

/// State for password reset flow.
class PasswordResetState {
  final PasswordResetStep step;
  final String? email;
  final UuidValue? passwordResetRequestId;
  final String? resetToken;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const PasswordResetState({
    this.step = PasswordResetStep.enterEmail,
    this.email,
    this.passwordResetRequestId,
    this.resetToken,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  PasswordResetState copyWith({
    PasswordResetStep? step,
    String? email,
    UuidValue? passwordResetRequestId,
    String? resetToken,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return PasswordResetState(
      step: step ?? this.step,
      email: email ?? this.email,
      passwordResetRequestId:
          passwordResetRequestId ?? this.passwordResetRequestId,
      resetToken: resetToken ?? this.resetToken,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Steps in the password reset flow.
enum PasswordResetStep {
  enterEmail,
  enterCode,
  enterNewPassword,
  completed,
}

/// Capsule that provides text controllers for password reset forms.
PasswordResetControllers passwordResetControllersCapsule(CapsuleHandle use) {
  final emailController = use.memo(() => TextEditingController());
  final codeController = use.memo(() => TextEditingController());
  final passwordController = use.memo(() => TextEditingController());
  final confirmPasswordController = use.memo(() => TextEditingController());

  use.effect(() {
    return () {
      emailController.dispose();
      codeController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
    };
  }, []);

  return PasswordResetControllers(
    email: emailController,
    code: codeController,
    password: passwordController,
    confirmPassword: confirmPasswordController,
  );
}

/// Container for password reset form controllers.
class PasswordResetControllers {
  final TextEditingController email;
  final TextEditingController code;
  final TextEditingController password;
  final TextEditingController confirmPassword;

  const PasswordResetControllers({
    required this.email,
    required this.code,
    required this.password,
    required this.confirmPassword,
  });

  void clear() {
    email.clear();
    code.clear();
    password.clear();
    confirmPassword.clear();
  }
}

/// Capsule that manages password reset flow state.
PasswordResetManager passwordResetCapsule(CapsuleHandle use) {
  final (state, setState) = use.state(const PasswordResetState());
  final client = use(clientCapsule);

  return PasswordResetManager(
    state: state,
    setState: setState,
    client: client,
  );
}

/// Manager class for password reset operations.
class PasswordResetManager {
  final PasswordResetState state;
  final void Function(PasswordResetState) _setState;
  final Client _client;

  PasswordResetManager({
    required this.state,
    required void Function(PasswordResetState) setState,
    required Client client,
  }) : _setState = setState,
       _client = client;

  /// Start password reset by requesting a verification code.
  Future<void> startPasswordReset(String email) async {
    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final requestId = await _client.emailIdp.startPasswordReset(email: email);
      _setState(
        state.copyWith(
          step: PasswordResetStep.enterCode,
          email: email,
          passwordResetRequestId: requestId,
          isLoading: false,
        ),
      );
    } on Exception catch (e) {
      _setState(
        state.copyWith(
          isLoading: false,
          error: _parseError(e),
        ),
      );
    }
  }

  /// Verify the reset code entered by user.
  Future<void> verifyCode(String code) async {
    if (state.passwordResetRequestId == null) {
      _setState(state.copyWith(error: 'Invalid state. Please start over.'));
      return;
    }

    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final token = await _client.emailIdp.verifyPasswordResetCode(
        passwordResetRequestId: state.passwordResetRequestId!,
        verificationCode: code,
      );
      _setState(
        state.copyWith(
          step: PasswordResetStep.enterNewPassword,
          resetToken: token,
          isLoading: false,
        ),
      );
    } on Exception catch (e) {
      _setState(
        state.copyWith(
          isLoading: false,
          error: _parseError(e),
        ),
      );
    }
  }

  /// Complete password reset with new password.
  Future<void> finishPasswordReset(String password) async {
    if (state.resetToken == null) {
      _setState(state.copyWith(error: 'Invalid state. Please start over.'));
      return;
    }

    _setState(state.copyWith(isLoading: true, error: null));
    try {
      await _client.emailIdp.finishPasswordReset(
        finishPasswordResetToken: state.resetToken!,
        newPassword: password,
      );
      _setState(
        state.copyWith(
          step: PasswordResetStep.completed,
          isLoading: false,
          successMessage: 'Password reset successful! You can now login.',
        ),
      );
    } on Exception catch (e) {
      _setState(
        state.copyWith(
          isLoading: false,
          error: _parseError(e),
        ),
      );
    }
  }

  /// Reset the state to start over.
  void reset() {
    _setState(const PasswordResetState());
  }

  String _parseError(Exception e) {
    final message = e.toString();
    if (message.contains('EmailNotConfigured')) {
      return 'Password reset is not available. Please contact an administrator.';
    }
    if (message.contains('invalidCode')) {
      return 'Invalid verification code. Please try again.';
    }
    if (message.contains('expired')) {
      return 'The verification code has expired. Please request a new one.';
    }
    if (message.contains('tooManyAttempts')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'An error occurred. Please try again.';
  }
}
