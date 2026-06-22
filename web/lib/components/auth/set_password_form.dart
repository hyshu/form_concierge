import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../state/auth_state.dart';
import 'auth_form_controls.dart';

class SetPasswordForm extends StatefulComponent {
  const SetPasswordForm({
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
  State<SetPasswordForm> createState() => _SetPasswordFormState();
}

class _SetPasswordFormState extends State<SetPasswordForm> {
  String _password = '';
  String _confirmPassword = '';

  Future<void> _submit() async {
    if (_password.isEmpty || _confirmPassword.isEmpty) {
      component.onAuthStateChanged(
        component.authState.copyWith(error: 'Please fill in all fields'),
      );
      return;
    }

    if (_password.length < 8) {
      component.onAuthStateChanged(
        component.authState.copyWith(
          error: 'Password must be at least 8 characters',
        ),
      );
      return;
    }

    if (_password != _confirmPassword) {
      component.onAuthStateChanged(
        component.authState.copyWith(error: 'Passwords do not match'),
      );
      return;
    }

    component.onAuthStateChanged(
      component.authState.copyWith(isLoading: true, error: null),
    );

    try {
      final token = component.authState.registrationToken;
      if (token == null) {
        component.onAuthStateChanged(
          component.authState.copyWith(
            isLoading: false,
            error: 'Registration session expired. Please start over.',
          ),
        );
        return;
      }

      final auth = await component.client.emailIdp.finishRegistration(
        registrationToken: token,
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
    if (message.contains('policyViolation')) {
      return 'Password does not meet security requirements.';
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
            'placeholder': 'Enter password (min 8 characters)',
            'autocomplete': 'new-password',
          },
          onInput: (String value) => setState(() => _password = value),
        ),
      ]),

      // Confirm password field
      div(classes: 'space-y-1.5', [
        label([Component.text('Confirm Password')],
            htmlFor: 'confirmPassword',
            classes: 'block text-sm font-medium text-slate-700'),
        input(
          type: InputType.password,
          id: 'confirmPassword',
          name: 'confirmPassword',
          value: _confirmPassword,
          classes: authInputClasses,
          disabled: isLoading,
          attributes: {
            'placeholder': 'Confirm your password',
            'autocomplete': 'new-password',
          },
          onInput: (String value) => setState(() => _confirmPassword = value),
        ),
      ]),

      // Submit button
      div(classes: 'pt-2', [
        button(
          [
            Component.text(isLoading ? 'Creating Account...' : 'Create Account')
          ],
          classes: authPrimaryButtonClasses,
          disabled: isLoading,
          onClick: isLoading ? null : () => _submit(),
        ),
      ]),
    ]);
  }
}
