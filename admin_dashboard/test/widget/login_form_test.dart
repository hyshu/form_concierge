import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_concierge_flutter/src/features/auth/presentation/capsules/login_form_capsule.dart';
import 'package:form_concierge_flutter/src/features/auth/presentation/widgets/login_form.dart';

import '../support/given_when_then.dart';

void main() {
  group('LoginForm', () {
    late TextEditingController emailController;
    late TextEditingController passwordController;
    late LoginFormControllers controllers;
    late bool submitWasCalled;

    setUp(() {
      emailController = TextEditingController();
      passwordController = TextEditingController();
      controllers = LoginFormControllers(
        email: emailController,
        password: passwordController,
      );
      submitWasCalled = false;
    });

    tearDown(() {
      emailController.dispose();
      passwordController.dispose();
    });

    Widget buildSubject({
      bool isLoading = false,
      String? error,
      bool isRegistration = false,
      VoidCallback? onForgotPassword,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: LoginForm(
            controllers: controllers,
            isLoading: isLoading,
            error: error,
            isRegistration: isRegistration,
            onForgotPassword: onForgotPassword,
            onSubmit: () {
              submitWasCalled = true;
            },
          ),
        ),
      );
    }

    group('loading state', () {
      testWidgets('shows loading indicator when isLoading is true', (
        tester,
      ) async {
        await tester.pumpWidget(buildSubject(isLoading: true));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Login'), findsNothing);
      });

      testWidgets('disables email field when isLoading is true', (
        tester,
      ) async {
        await tester.pumpWidget(buildSubject(isLoading: true));

        final emailField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Email'),
        );
        expect(emailField.enabled, isFalse);
      });

      testWidgets('disables password field when isLoading is true', (
        tester,
      ) async {
        await tester.pumpWidget(buildSubject(isLoading: true));

        final passwordField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Password'),
        );
        expect(passwordField.enabled, isFalse);
      });

      testWidgets('disables submit button when isLoading is true', (
        tester,
      ) async {
        await tester.pumpWidget(buildSubject(isLoading: true));

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      });
    });

    group('error display', () {
      testWidgets('displays error message when error is provided', (
        tester,
      ) async {
        await tester.pumpWidget(buildSubject(error: 'Invalid credentials'));

        expect(find.text('Invalid credentials'), findsOneWidget);
      });

      testWidgets('does not display error when error is null', (tester) async {
        await tester.pumpWidget(buildSubject(error: null));

        expect(find.text('Invalid credentials'), findsNothing);
      });
    });

    group('button text', () {
      testWidgets('shows Login button for login mode', (tester) async {
        await tester.pumpWidget(buildSubject(isRegistration: false));

        expect(find.text('Login'), findsOneWidget);
        expect(find.text('Create Account'), findsNothing);
      });

      testWidgets('shows Create Account button for registration mode', (
        tester,
      ) async {
        await tester.pumpWidget(buildSubject(isRegistration: true));

        expect(find.text('Create Account'), findsOneWidget);
        expect(find.text('Login'), findsNothing);
      });
    });

    group('forgot password', () {
      testWidgets('shows Forgot Password link in login mode', (tester) async {
        await tester.pumpWidget(
          buildSubject(isRegistration: false, onForgotPassword: () {}),
        );

        expect(find.text('Forgot Password?'), findsOneWidget);
      });

      testWidgets('hides Forgot Password link in registration mode', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildSubject(isRegistration: true, onForgotPassword: () {}),
        );

        expect(find.text('Forgot Password?'), findsNothing);
      });

      testWidgets('hides Forgot Password link when callback is null', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildSubject(isRegistration: false, onForgotPassword: null),
        );

        expect(find.text('Forgot Password?'), findsNothing);
      });
    });

    group('form submission', () {
      scenarioWidget(
        'tapping submit button calls onSubmit',
        given: (tester) async {
          await tester.pumpWidget(buildSubject());
          emailController.text = 'test@example.com';
          passwordController.text = 'password123';
        },
        when: (tester) async {
          await tester.tap(find.text('Login'));
          await tester.pump();
        },
        then: (tester) async {
          expect(submitWasCalled, isTrue);
        },
      );

      testWidgets('password field has done action for keyboard submission', (
        tester,
      ) async {
        await tester.pumpWidget(buildSubject());

        final passwordField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Password'),
        );
        expect(passwordField.textInputAction, TextInputAction.done);
      });
    });

    group('autofill hints', () {
      testWidgets('email field has email autofill hint', (tester) async {
        await tester.pumpWidget(buildSubject());

        final emailField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Email'),
        );
        expect(emailField.autofillHints, contains(AutofillHints.email));
      });

      testWidgets('password field has password autofill hint', (tester) async {
        await tester.pumpWidget(buildSubject());

        final passwordField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Password'),
        );
        expect(passwordField.autofillHints, contains(AutofillHints.password));
      });
    });
  });
}
