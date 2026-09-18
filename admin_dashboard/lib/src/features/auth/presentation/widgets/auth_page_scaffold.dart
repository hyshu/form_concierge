import 'package:flutter/material.dart';

/// The shared page layout for administrator authentication screens.
class AuthPageScaffold extends StatelessWidget {
  /// Creates AuthPageScaffold with the supplied values.
  const AuthPageScaffold({
    super.key,
    required this.child,
    this.scrollable = true,
  });

  /// The content displayed inside this container.
  final Widget child;

  /// Whether the authentication content can scroll when space is limited.
  final bool scrollable;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) {
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
