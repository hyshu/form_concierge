import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

const _turnstileScriptSrc =
    'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';

@JS('turnstile')
external TurnstileApi? get _turnstile;

extension type TurnstileApi(JSObject _) implements JSObject {
  external String render(JSAny container, JSObject parameters);
  external void reset(JSAny widgetId);
  external void remove(JSAny widgetId);
  external String getResponse(JSAny widgetId);
}

String? _widgetId;
Completer<void>? _scriptLoading;

/// Ensures the Turnstile script is available, then renders into [containerId].
Future<void> mountTurnstile({
  required String containerId,
  required String siteKey,
}) async {
  await _ensureTurnstileScript();
  final api = _turnstile;
  if (api == null) {
    throw StateError('Turnstile API is unavailable');
  }

  final container = web.document.getElementById(containerId);
  if (container == null) {
    throw StateError('Turnstile container #$containerId not found');
  }

  // Drop any previous widget (rebuild / navigation).
  unmountTurnstile();

  final parameters = <String, Object?>{'sitekey': siteKey}.jsify();
  if (parameters == null) {
    throw StateError('Failed to build Turnstile parameters');
  }
  _widgetId = api.render(container, parameters as JSObject);
}

/// Token from the currently mounted widget, or null if incomplete.
String? getTurnstileResponse() {
  final widgetId = _widgetId;
  final api = _turnstile;
  if (widgetId == null || api == null) {
    // Fallback for an SSR widget that was not re-mounted via JS API.
    final input = web.document.querySelector(
      '.cf-turnstile input[name="cf-turnstile-response"]',
    );
    if (input == null) return null;
    final value = (input as web.HTMLInputElement).value;
    return value.isEmpty ? null : value;
  }
  final value = api.getResponse(widgetId.toJS);
  return value.isEmpty ? null : value;
}

/// Reset after a failed submit (tokens are single-use).
void resetTurnstile() {
  final widgetId = _widgetId;
  final api = _turnstile;
  if (widgetId == null || api == null) return;
  api.reset(widgetId.toJS);
}

void unmountTurnstile() {
  final widgetId = _widgetId;
  final api = _turnstile;
  _widgetId = null;
  if (widgetId == null || api == null) return;
  try {
    api.remove(widgetId.toJS);
  } on Object {
    // Widget may already be gone with its container.
  }
}

Future<void> _ensureTurnstileScript() async {
  if (_turnstile != null) return;

  final existingLoad = _scriptLoading;
  if (existingLoad != null) {
    await existingLoad.future;
    return;
  }

  final completer = Completer<void>();
  _scriptLoading = completer;

  try {
    // Prefer an already-injected script (SSR page includes it).
    final existing = web.document.querySelector(
      'script[src*="challenges.cloudflare.com/turnstile"]',
    );
    if (existing == null) {
      final script = web.HTMLScriptElement()
        ..src = _turnstileScriptSrc
        ..async = true;
      final load = Completer<void>();
      script.onload = (web.Event _) {
        load.complete();
      }.toJS;
      script.onerror = (web.Event _) {
        load.completeError(StateError('Failed to load Turnstile script'));
      }.toJS;
      web.document.head!.append(script);
      await load.future;
    }

    // Script may be present but not finished executing yet.
    for (var i = 0; i < 50; i++) {
      if (_turnstile != null) {
        completer.complete();
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('Turnstile script did not initialize');
  } on Object catch (error, stack) {
    completer.completeError(error, stack);
    _scriptLoading = null;
    rethrow;
  }
}
