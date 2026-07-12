import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import 'client_capsule.dart';

/// State for public configuration.
class PublicConfigState {
  final PublicConfig? config;
  final bool isLoading;
  final bool hasLoaded;
  final String? error;

  const PublicConfigState({
    this.config,
    this.isLoading = false,
    this.hasLoaded = false,
    this.error,
  });

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
  final PublicConfigState state;
  final void Function(PublicConfigState) _setState;
  final Client _client;

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
