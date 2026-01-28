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
  }) {
    return PublicConfigState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      error: error,
    );
  }

  /// Whether password reset feature is available.
  bool get passwordResetEnabled => config?.passwordResetEnabled ?? false;
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
    required void Function(PublicConfigState) setState,
    required Client client,
  }) : _setState = setState,
       _client = client;

  /// Load public configuration from server.
  Future<void> loadConfig() async {
    if (state.hasLoaded || state.isLoading) return;

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
