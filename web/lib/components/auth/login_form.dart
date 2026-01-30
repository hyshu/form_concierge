import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../state/auth_state.dart';

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
      await component.client.emailIdp.login(email: _email, password: _password);
      component.onAuthSuccess();
    } catch (e) {
      final errorMessage = _parseError(e.toString());
      component.onAuthStateChanged(
        component.authState.copyWith(isLoading: false, error: errorMessage),
      );
    }
  }

  String _parseError(String error) {
    if (error.contains('invalidCredentials')) {
      return 'Invalid email or password';
    }
    if (error.contains('tooManyAttempts')) {
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
        div(
            classes:
                'flex items-start gap-3 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl text-sm',
            [
              span(classes: 'text-red-500 flex-shrink-0', [
                Component.text('\u26A0'),
              ]),
              span([Component.text(component.authState.error!)]),
            ]),

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
          classes:
              'w-full px-4 py-3 border border-slate-200 rounded-lg focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 focus:outline-none text-sm disabled:bg-slate-50 disabled:cursor-not-allowed placeholder:text-slate-400',
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
          classes:
              'w-full px-4 py-3 border border-slate-200 rounded-lg focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 focus:outline-none text-sm disabled:bg-slate-50 disabled:cursor-not-allowed placeholder:text-slate-400',
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
          classes:
              'w-full py-3 px-4 bg-indigo-600 text-white font-medium rounded-xl hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm',
          disabled: isLoading,
          onClick: isLoading ? null : () => _submit(),
        ),
      ]),
    ]);
  }
}
