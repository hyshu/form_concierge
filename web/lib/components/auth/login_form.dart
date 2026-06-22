import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../state/auth_state.dart';
import 'auth_form_controls.dart';

class LoginForm extends StatefulComponent {
  const LoginForm({
    required this.client,
    required this.authState,
    required this.onAuthStateChanged,
    required this.onAuthSuccess,
    super.key,
  });

  final Client client;
  final SurveyAuthState authState;
  final void Function(SurveyAuthState state) onAuthStateChanged;
  final void Function() onAuthSuccess;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  String _email = '';
  String _password = '';

  Future<void> _submit() async {
    if (_email.isEmpty || _password.isEmpty) {
      component.onAuthStateChanged(
        component.authState.copyWith(error: 'Please fill in all fields'),
      );
      return;
    }

    component.onAuthStateChanged(
      component.authState.copyWith(isLoading: true, error: null),
    );

    try {
      final auth = await component.client.emailIdp.login(
        email: _email,
        password: _password,
      );
      await component.client.auth.updateSignedInUser(auth);
      component.onAuthSuccess();
    } on Exception catch (error) {
      final errorMessage = _parseError(error);
      component.onAuthStateChanged(
        component.authState.copyWith(isLoading: false, error: errorMessage),
      );
    }
  }

  String _parseError(Exception error) {
    final message = error.toString();
    if (message.contains('invalidCredentials')) {
      return 'Invalid email or password';
    }
    if (message.contains('tooManyAttempts')) {
      return 'Too many login attempts. Please try again later.';
    }
    return 'Login failed. Please try again.';
  }

  @override
  Component build(BuildContext context) {
    final isLoading = component.authState.isLoading;

    return div(classes: 'space-y-4', [
      // Error message
      if (component.authState.error != null)
        AuthErrorMessage(component.authState.error!),

      // Email field
      div(classes: 'space-y-1.5', [
        label([Component.text('Email')],
            htmlFor: 'email',
            classes: 'block text-sm font-medium text-slate-700'),
        input(
          type: InputType.email,
          id: 'email',
          name: 'email',
          value: _email,
          classes: authInputClasses,
          disabled: isLoading,
          attributes: {
            'placeholder': 'Enter your email',
            'autocomplete': 'email',
          },
          onInput: (String value) => setState(() => _email = value),
        ),
      ]),

      // Password field
      div(classes: 'space-y-1.5', [
        label([Component.text('Password')],
            htmlFor: 'password',
            classes: 'block text-sm font-medium text-slate-700'),
        input(
          type: InputType.password,
          id: 'password',
          name: 'password',
          value: _password,
          classes: authInputClasses,
          disabled: isLoading,
          attributes: {
            'placeholder': 'Enter your password',
            'autocomplete': 'current-password',
          },
          onInput: (String value) => setState(() => _password = value),
        ),
      ]),

      // Submit button
      div(classes: 'pt-2', [
        button(
          [Component.text(isLoading ? 'Signing In...' : 'Sign In')],
          classes: authPrimaryButtonClasses,
          disabled: isLoading,
          onClick: isLoading ? null : () => _submit(),
        ),
      ]),
    ]);
  }
}
