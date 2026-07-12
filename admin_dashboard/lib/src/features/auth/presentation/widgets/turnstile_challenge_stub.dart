import 'package:flutter/widgets.dart';

class TurnstileChallenge extends StatelessWidget {
  const TurnstileChallenge({super.key, required this.siteKey});

  final String siteKey;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

String? getTurnstileResponse() => null;

void resetTurnstile() {}
