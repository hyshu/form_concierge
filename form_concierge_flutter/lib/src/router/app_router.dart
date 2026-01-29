import 'package:go_router/go_router.dart';
import 'package:rearch/rearch.dart';

import '../core/capsules/auth_state_capsule.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/verify_reset_code_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/responses/presentation/pages/responses_page.dart';
import '../features/surveys/presentation/pages/survey_editor_page.dart';
import '../features/users/presentation/pages/users_page.dart';

/// Capsule that provides the GoRouter instance with auth guards.
GoRouter appRouterCapsule(CapsuleHandle use) {
  final authManager = use(authStateCapsule);

  return use.memo(
    () => GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isLoggedIn = authManager.state.isAuthenticated;
        final path = state.matchedLocation;

        // Public pages that don't require authentication
        final publicPages = [
          '/login',
          '/forgot-password',
          '/verify-reset-code',
          '/reset-password',
        ];
        final isPublicPage = publicPages.contains(path);

        // Still checking auth state - don't redirect yet
        if (!authManager.state.hasCheckedAuth) {
          return null;
        }

        // Not logged in and not on public page - redirect to login
        if (!isLoggedIn && !isPublicPage) {
          return '/login';
        }

        // Logged in and on login page - redirect to admin
        if (isLoggedIn && path == '/login') {
          return '/admin';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/verify-reset-code',
          builder: (context, state) => const VerifyResetCodePage(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordPage(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const DashboardPage(),
          routes: [
            GoRoute(
              path: 'surveys/new',
              builder: (context, state) => const SurveyEditorPage(),
            ),
            GoRoute(
              path: 'users',
              builder: (context, state) => const UsersPage(),
            ),
            GoRoute(
              path: 'surveys/:id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return SurveyEditorPage(surveyId: id);
              },
              routes: [
                GoRoute(
                  path: 'responses',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    return ResponsesPage(surveyId: id);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    [authManager.state.isAuthenticated, authManager.state.hasCheckedAuth],
  );
}
