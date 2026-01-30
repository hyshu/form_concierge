import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:rearch/rearch.dart';

import 'core/capsules/auth_state_capsule.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

/// Root application widget.
class App extends RearchConsumer {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final router = use(appRouterCapsule);
    final authManager = use(authStateCapsule);

    // Check auth on startup
    use.effect(
      () {
        authManager.checkAuth();
        return null;
      },
      [],
    );

    return MaterialApp.router(
      title: 'Form Concierge Admin',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
