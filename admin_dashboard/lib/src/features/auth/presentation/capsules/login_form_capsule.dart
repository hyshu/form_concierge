import 'package:flutter/material.dart';
import 'package:rearch/rearch.dart';

/// Capsule that manages login form controllers with proper cleanup.
LoginFormControllers loginFormControllersCapsule(CapsuleHandle use) {
  final emailController = use.memo(() => TextEditingController());
  final passwordController = use.memo(() => TextEditingController());

  use.effect(() {
    return () {
      emailController.dispose();
      passwordController.dispose();
    };
  }, []);

  return LoginFormControllers(
    email: emailController,
    password: passwordController,
  );
}

/// Container for login form controllers.
class LoginFormControllers {
  final TextEditingController email;
  final TextEditingController password;

  const LoginFormControllers({
    required this.email,
    required this.password,
  });
}
