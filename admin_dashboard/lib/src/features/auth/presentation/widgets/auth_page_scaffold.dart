import 'package:flutter/material.dart';

class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.child,
    this.scrollable = true,
  });

  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: child,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: scrollable ? SingleChildScrollView(child: content) : content,
        ),
      ),
    );
  }
}
