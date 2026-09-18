import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import 'client_capsule.dart';

/// State for public configuration.
class PublicConfigState {
  /// The public server configuration, if it has been loaded.
  final PublicConfig? config;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// Whether an initial load has completed.
  final bool hasLoaded;

  /// The error message, when the operation could not complete.
  final String? error;

  /// Creates PublicConfigState with the supplied values.
  const PublicConfigState({
    this.config,
    this.isLoading = false,
    this.hasLoaded = false,
    this.error,
  });

  /// Returns a copy with the supplied state changes.
  PublicConfigState copyWith({
    PublicConfig? config,
    bool? isLoading,
    bool? hasLoaded,
    String? error,
  }) => PublicConfigState(
    config: config ?? this.config,
    isLoading: isLoading ?? this.isLoading,
    hasLoaded: hasLoaded ?? this.hasLoaded,
    error: error,
  );

  /// Whether password reset feature is available.
  bool get passwordResetEnabled => config?.passwordResetEnabled ?? false;

  /// Whether AI question generation is enabled.
  bool get aiGenerationEnabled => config?.aiGenerationEnabled ?? false;

  /// The public Turnstile site key used by the CAPTCHA widget.
  String? get turnstileSiteKey => config?.turnstileSiteKey;
}

/// Capsule that manages public server configuration.
PublicConfigManager publicConfigCapsule(CapsuleHandle use) {
  final (state, setState) = use.state(const PublicConfigState());
  final client = use(clientCapsule);

  return PublicConfigManager(
    state: state,
    setState: setState,
    client: client,
  );
}

/// Manager class for public configuration.
class PublicConfigManager {
  /// The current state snapshot exposed by this manager.
  final PublicConfigState state;
  final void Function(PublicConfigState) _setState;
  final Client _client;

  /// Creates PublicConfigManager with the supplied values.
  PublicConfigManager({
    required this.state,
    required this._setState,
    required this._client,
  });

  /// Load public configuration from server (no-op once loaded).
  Future<void> loadConfig() => _fetchConfig(force: false);

  /// Re-fetch public configuration, e.g. after admin settings change AI/SMTP.
  Future<void> reloadConfig() => _fetchConfig(force: true);

  Future<void> _fetchConfig({required bool force}) async {
    if (state.isLoading) return;
    if (!force && state.hasLoaded) return;

    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final config = await _client.config.getPublicConfig();
      _setState(
        state.copyWith(
          config: config,
          isLoading: false,
          hasLoaded: true,
        ),
      );
    } on Exception catch (e) {
      _setState(
        state.copyWith(
          isLoading: false,
          hasLoaded: true,
          error: 'Failed to load config: $e',
        ),
      );
    }
  }
}
