import 'package:flutter/widgets.dart';

/// Displays a Turnstile challenge on platforms that support the web widget.
class TurnstileChallenge extends StatelessWidget {
  /// Creates TurnstileChallenge with the supplied values.
  const TurnstileChallenge({super.key, required this.siteKey});

  /// The public Turnstile site key used to render the CAPTCHA challenge.
  final String siteKey;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Returns null because browser storage or page state is unavailable on this platform.
String? getTurnstileResponse() => null;

/// Does nothing on platforms without the required browser APIs.
void resetTurnstile() {}
