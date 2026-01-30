import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../state/auth_state.dart';

class VerifyCodeForm extends StatefulComponent {
  const VerifyCodeForm({
    required this.client,
    required this.authState,
    required this.onAuthStateChanged,
    super.key,
  });

  final Client client;
  final SurveyAuthState authState;
  final void Function(SurveyAuthState state) onAuthStateChanged;

  @override
  State<VerifyCodeForm> createState() => _VerifyCodeFormState();
}

class _VerifyCodeFormState extends State<VerifyCodeForm> {
  String _code = '';

  Future<void> _submit() async {
    if (_code.isEmpty) {
      component.onAuthStateChanged(
        component.authState
            .copyWith(error: 'Please enter the verification code'),
      );
      return;
    }

    component.onAuthStateChanged(
      component.authState.copyWith(isLoading: true, error: null),
    );

    try {
      final requestId = component.authState.registrationRequestId;
      if (requestId == null) {
        throw Exception('Registration request ID not found');
      }

      final result = await component.client.emailIdp.verifyRegistrationCode(
        accountRequestId: UuidValue.fromString(requestId),
        verificationCode: _code,
      );

      component.onAuthStateChanged(
        component.authState.copyWith(
          isLoading: false,
          viewMode: AuthViewMode.setPassword,
          registrationToken: result,
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
    if (error.contains('invalidVerificationCode')) {
      return 'Invalid verification code. Please try again.';
    }
    if (error.contains('expired')) {
      return 'Verification code has expired. Please request a new one.';
    }
    return 'Verification failed. Please try again.';
  }

  @override
  Component build(BuildContext context) {
    final isLoading = component.authState.isLoading;

    return div(classes: 'space-y-4', [
      // Info text
      div(classes: 'text-center py-2', [
        p(classes: 'text-sm text-slate-600', [
          Component.text('We sent a verification code to'),
        ]),
        p(classes: 'text-sm font-medium text-slate-800 mt-1', [
          Component.text(component.authState.registrationEmail ?? ''),
        ]),
      ]),

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

      // Code field
      div(classes: 'space-y-1.5', [
        label([Component.text('Verification Code')],
            htmlFor: 'code',
            classes: 'block text-sm font-medium text-slate-700'),
        input(
          type: InputType.text,
          id: 'code',
          name: 'code',
          value: _code,
          classes:
              'w-full px-4 py-3 border border-slate-200 rounded-lg focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 focus:outline-none text-sm disabled:bg-slate-50 disabled:cursor-not-allowed placeholder:text-slate-400 text-center tracking-widest',
          disabled: isLoading,
          attributes: {
            'placeholder': 'Enter verification code',
            'autocomplete': 'one-time-code',
          },
          onInput: (String value) => setState(() => _code = value),
        ),
      ]),

      // Submit button
      div(classes: 'pt-2', [
        button(
          [Component.text(isLoading ? 'Verifying...' : 'Verify')],
          classes:
              'w-full py-3 px-4 bg-indigo-600 text-white font-medium rounded-xl hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm',
          disabled: isLoading,
          onClick: isLoading ? null : () => _submit(),
        ),
      ]),

      // Back button
      div(classes: 'text-center', [
        button(
          [Component.text('Back')],
          classes: 'text-indigo-600 hover:underline text-sm font-medium',
          onClick: () {
            component.onAuthStateChanged(
              component.authState.copyWith(
                viewMode: AuthViewMode.register,
                error: null,
              ),
            );
          },
        ),
      ]),
    ]);
  }
}
