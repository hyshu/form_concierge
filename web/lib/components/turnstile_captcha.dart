import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../utils/turnstile.dart';

/// Explicit Turnstile widget re-mounted after the SSR shell is removed.
class TurnstileCaptcha extends StatefulComponent {
  const TurnstileCaptcha({required this.siteKey, super.key});

  final String siteKey;

  static const containerId = 'form-concierge-turnstile';

  @override
  State<TurnstileCaptcha> createState() => _TurnstileCaptchaState();
}

class _TurnstileCaptchaState extends State<TurnstileCaptcha> {
  String? _error;
  var _mountGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scheduleMount();
  }

  @override
  void didUpdateComponent(covariant TurnstileCaptcha oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.siteKey != component.siteKey) {
      _scheduleMount();
    }
  }

  @override
  void dispose() {
    _mountGeneration++;
    unmountTurnstile();
    super.dispose();
  }

  void _scheduleMount() {
    final generation = ++_mountGeneration;
    // Wait until the container is in the live DOM.
    Future<void>(() async {
      for (var attempt = 0; attempt < 40; attempt++) {
        if (generation != _mountGeneration) return;
        try {
          await mountTurnstile(
            containerId: TurnstileCaptcha.containerId,
            siteKey: component.siteKey,
          );
          if (generation != _mountGeneration || !mounted) return;
          if (_error != null) {
            setState(() => _error = null);
          }
          return;
        } on Object {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
      if (generation != _mountGeneration || !mounted) return;
      setState(() => _error = 'CAPTCHA failed to load');
    });
  }

  @override
  Component build(context) => div(classes: 'my-4', [
    div(id: TurnstileCaptcha.containerId, classes: 'cf-turnstile', []),
    if (_error != null)
      p(classes: 'mt-2 text-sm text-red-600', [Component.text(_error!)]),
  ]);
}
