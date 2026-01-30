import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../state/auth_state.dart';
import 'login_form.dart';
import 'register_form.dart';
import 'verify_code_form.dart';
import 'set_password_form.dart';

class AuthView extends StatelessComponent {
  const AuthView({
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
  Component build(BuildContext context) {
    return div(classes: 'flex items-center justify-center min-h-[480px]', [
      div(
          classes:
              'bg-white rounded-xl shadow-md border border-slate-200 p-8 w-full max-w-md',
          [
            h2(
                classes:
                    'text-xl font-semibold text-center text-slate-900 mb-6',
                [
                  Component.text(_getTitle()),
                ]),

            switch (authState.viewMode) {
              AuthViewMode.login => LoginForm(
                  client: client,
                  authState: authState,
                  onAuthStateChanged: onAuthStateChanged,
                  onAuthSuccess: onAuthSuccess,
                ),
              AuthViewMode.register => RegisterForm(
                  client: client,
                  authState: authState,
                  onAuthStateChanged: onAuthStateChanged,
                ),
              AuthViewMode.verifyCode => VerifyCodeForm(
                  client: client,
                  authState: authState,
                  onAuthStateChanged: onAuthStateChanged,
                ),
              AuthViewMode.setPassword => SetPasswordForm(
                  client: client,
                  authState: authState,
                  onAuthStateChanged: onAuthStateChanged,
                  onAuthSuccess: onAuthSuccess,
                ),
            },

            // Toggle between login and register
            if (authState.viewMode == AuthViewMode.login ||
                authState.viewMode == AuthViewMode.register)
              div(classes: 'text-center mt-6 text-sm text-slate-500', [
                Component.text(authState.viewMode == AuthViewMode.login
                    ? "Don't have an account? "
                    : 'Already have an account? '),
                button(
                  [
                    Component.text(authState.viewMode == AuthViewMode.login
                        ? 'Sign Up'
                        : 'Sign In'),
                  ],
                  classes: 'text-indigo-600 font-medium hover:underline',
                  onClick: () {
                    onAuthStateChanged(authState.copyWith(
                      viewMode: authState.viewMode == AuthViewMode.login
                          ? AuthViewMode.register
                          : AuthViewMode.login,
                      error: null,
                    ));
                  },
                ),
              ]),
          ]),
    ]);
  }

  String _getTitle() {
    return switch (authState.viewMode) {
      AuthViewMode.login => 'Sign In',
      AuthViewMode.register => 'Create Account',
      AuthViewMode.verifyCode => 'Verify Email',
      AuthViewMode.setPassword => 'Set Password',
    };
  }
}
