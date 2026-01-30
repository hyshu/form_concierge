import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../state/auth_state.dart';

class RegisterForm extends StatefulComponent {
  const RegisterForm({
    required this.client,
    required this.authState,
    required this.onAuthStateChanged,
    super.key,
  });

  final Client client;
  final SurveyAuthState authState;
  final void Function(SurveyAuthState state) onAuthStateChanged;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  String _email = '';

  Future<void> _submit() async {
    if (_email.isEmpty) {
      component.onAuthStateChanged(
        component.authState.copyWith(error: 'Please enter your email'),
      );
      return;
    }

    component.onAuthStateChanged(
      component.authState.copyWith(isLoading: true, error: null),
    );

    try {
      final result =
          await component.client.emailIdp.startRegistration(email: _email);

      component.onAuthStateChanged(
        component.authState.copyWith(
          isLoading: false,
          viewMode: AuthViewMode.verifyCode,
          registrationRequestId: result.toString(),
          registrationEmail: _email,
        ),
      );
    } catch (e) {
      final errorMessage = _parseError(e.toString());
      component.onAuthStateChanged(
        component.authState.copyWith(isLoading: false, error: errorMessage),
      );
    }
  }

  String _parseError(String error) {
    if (error.contains('emailAlreadyInUse')) {
      return 'This email is already registered. Please sign in instead.';
    }
    if (error.contains('invalidEmail')) {
      return 'Please enter a valid email address.';
    }
    return 'Registration failed. Please try again.';
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

      // Submit button
      div(classes: 'pt-2', [
        button(
          [Component.text(isLoading ? 'Sending...' : 'Continue')],
          classes:
              'w-full py-3 px-4 bg-indigo-600 text-white font-medium rounded-xl hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm',
          disabled: isLoading,
          onClick: isLoading ? null : () => _submit(),
        ),
      ]),
    ]);
  }
}
