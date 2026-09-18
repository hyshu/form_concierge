import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import 'auth_page_scaffold.dart';

/// A consistent card layout for authentication forms and guidance.
class AuthCardScaffold extends StatelessWidget {
  /// Creates AuthCardScaffold with the supplied values.
  const AuthCardScaffold({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.children,
  });

  /// The icon displayed alongside the content or action.
  final IconData icon;

  /// The title displayed by this component.
  final String title;

  /// Optional supporting content displayed below the title.
  final Widget? subtitle;

  /// The child widgets displayed in order.
  final List<Widget> children;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => AuthPageScaffold(
    child: HuxCard(
      size: HuxCardSize.large,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 64, color: HuxTokens.primary(context)),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            subtitle!,
          ],
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    ),
  );
}
