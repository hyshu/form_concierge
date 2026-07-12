import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
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

String? _activeWidgetId;
Completer<void>? _scriptLoading;
var _nextViewId = 0;

class TurnstileChallenge extends StatefulWidget {
  const TurnstileChallenge({super.key, required this.siteKey});

  final String siteKey;

  @override
  State<TurnstileChallenge> createState() => _TurnstileChallengeState();
}

class _TurnstileChallengeState extends State<TurnstileChallenge> {
  late final String _viewType;
  late final web.HTMLDivElement _container;
  String? _widgetId;

  @override
  void initState() {
    super.initState();
    _viewType = 'form-concierge-login-turnstile-${_nextViewId++}';
    _container = web.HTMLDivElement()
      ..style.width = '100%'
      ..style.height = '65px';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (_) => _container,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _mount());
  }

  @override
  void dispose() {
    final widgetId = _widgetId;
    final api = _turnstile;
    if (widgetId != null && api != null) {
      try {
        api.remove(widgetId.toJS);
      } on Object {
        // Container may already be detached during route changes.
      }
    }
    if (_activeWidgetId == widgetId) _activeWidgetId = null;
    super.dispose();
  }

  Future<void> _mount() async {
    await _ensureTurnstileScript();
    if (!mounted) return;
    final api = _turnstile;
    if (api == null) return;
    final parameters = <String, Object?>{
      'sitekey': widget.siteKey,
      'theme': Theme.of(context).brightness == Brightness.dark
          ? 'dark'
          : 'light',
      'size': 'flexible',
      'action': 'turnstile-spin-v1',
      'response-field': false,
    }.jsify();
    if (parameters == null) return;
    _widgetId = api.render(_container, parameters as JSObject);
    _activeWidgetId = _widgetId;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 65,
    child: HtmlElementView(viewType: _viewType),
  );
}

String? getTurnstileResponse() {
  final widgetId = _activeWidgetId;
  final api = _turnstile;
  if (widgetId == null || api == null) return null;
  try {
    final value = api.getResponse(widgetId.toJS);
    return value.isEmpty ? null : value;
  } on Object {
    return null;
  }
}

void resetTurnstile() {
  final widgetId = _activeWidgetId;
  final api = _turnstile;
  if (widgetId == null || api == null) return;
  api.reset(widgetId.toJS);
}

Future<void> _ensureTurnstileScript() async {
  if (_turnstile != null) return;
  final currentLoad = _scriptLoading;
  if (currentLoad != null) return currentLoad.future;

  final completer = Completer<void>();
  _scriptLoading = completer;
  try {
    final existing = web.document.querySelector(
      'script[src*="challenges.cloudflare.com/turnstile"]',
    );
    if (existing == null) {
      final script = web.HTMLScriptElement()
        ..src = _turnstileScriptSrc
        ..async = true;
      final loaded = Completer<void>();
      script.onload = ((web.Event _) {
        loaded.complete();
      }).toJS;
      script.onerror = ((web.Event _) {
        loaded.completeError(StateError('Failed to load Turnstile script'));
      }).toJS;
      web.document.head!.append(script);
      await loaded.future;
    }
    for (var attempt = 0; attempt < 50; attempt++) {
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
