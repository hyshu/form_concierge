import 'package:flutter/material.dart';
import 'package:rearch/rearch.dart';

/// Capsule that manages login form controllers with proper cleanup.
LoginFormControllers loginFormControllersCapsule(CapsuleHandle use) {
  final emailController = use.memo(() => TextEditingController());
  final passwordController = use.memo(() => TextEditingController());

  use.effect(
    () => () {
      emailController.dispose();
      passwordController.dispose();
    },
    [],
  );

  return LoginFormControllers(
    email: emailController,
    password: passwordController,
  );
}

/// Container for login form controllers.
class LoginFormControllers {
  /// Controls the email input.
  final TextEditingController email;

  /// Controls the password input.
  final TextEditingController password;

  /// Creates LoginFormControllers with the supplied values.
  const LoginFormControllers({
    required this.email,
    required this.password,
  });
}
