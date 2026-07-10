import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import 'auth_page_scaffold.dart';

class AuthCardScaffold extends StatelessWidget {
  const AuthCardScaffold({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final Widget? subtitle;
  final List<Widget> children;

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
