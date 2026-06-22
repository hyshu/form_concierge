import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../state/auth_state.dart';
import 'auth_form_controls.dart';

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
    } on Exception catch (error) {
      final errorMessage = _parseError(error);
      component.onAuthStateChanged(
        component.authState.copyWith(isLoading: false, error: errorMessage),
      );
    }
  }

  String _parseError(Exception error) {
    final message = error.toString();
    if (message.contains('emailAlreadyInUse')) {
      return 'This email is already registered. Please sign in instead.';
    }
    if (message.contains('invalidEmail')) {
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

      // Submit button
      div(classes: 'pt-2', [
        button(
          [Component.text(isLoading ? 'Sending...' : 'Continue')],
          classes: authPrimaryButtonClasses,
          disabled: isLoading,
          onClick: isLoading ? null : () => _submit(),
        ),
      ]),
    ]);
  }
}
