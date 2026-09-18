import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/public_config_capsule.dart';

/// Integration settings and progress or feedback for loading and saving them.
class AdminSettingsState {
  /// The settings currently displayed or edited.
  final AdminIntegrationSettings? settings;

  /// Whether data is currently being loaded.
  final bool isLoading;

  /// Whether a save operation is in progress.
  final bool isSaving;

  /// The error message, when the operation could not complete.
  final String? error;

  /// Feedback displayed after an operation succeeds, if any.
  final String? successMessage;

  /// Creates AdminSettingsState with the supplied values.
  const AdminSettingsState({
    this.settings,
    this.isLoading = true,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  /// Returns a copy with the supplied state changes.
  AdminSettingsState copyWith({
    AdminIntegrationSettings? settings,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) => AdminSettingsState(
    settings: settings ?? this.settings,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    error: clearError ? null : (error ?? this.error),
    successMessage: clearSuccessMessage
        ? null
        : (successMessage ?? this.successMessage),
  );
}

/// Provides reactive admin settings manager state and dependencies.
AdminSettingsManager adminSettingsManagerCapsule(CapsuleHandle use) {
  final (state, setState) = use.state(const AdminSettingsState());
  final client = use(clientCapsule);
  final publicConfig = use(publicConfigCapsule);

  return AdminSettingsManager(
    state: state,
    setState: setState,
    client: client,
    publicConfig: publicConfig,
  );
}

/// Loads and saves integration settings while updating interface state.
class AdminSettingsManager {
  /// The current state snapshot exposed by this manager.
  final AdminSettingsState state;
  final void Function(AdminSettingsState state) _setState;
  final Client _client;
  final PublicConfigManager _publicConfig;

  /// Creates AdminSettingsManager with the supplied values.
  const AdminSettingsManager({
    required this.state,
    required this._setState,
    required this._client,
    required this._publicConfig,
  });

  /// Loads saved integration settings and records any failure in state.
  Future<void> loadSettings() async {
    _setState(state.copyWith(isLoading: true, clearError: true));
    try {
      final settings = await _client.adminSettings.get();
      _setState(
        state.copyWith(
          settings: settings,
          isLoading: false,
          clearError: true,
        ),
      );
    } on Exception catch (e) {
      _setState(
        state.copyWith(
          isLoading: false,
          error: 'Failed to load settings: $e',
        ),
      );
    }
  }

  /// Saves integration settings and returns whether the update succeeded.
  Future<bool> saveSettings(AdminIntegrationSettingsInput input) async {
    _setState(
      state.copyWith(
        isSaving: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );
    try {
      final settings = await _client.adminSettings.update(input);
      _setState(
        state.copyWith(
          settings: settings,
          isSaving: false,
          successMessage: 'Settings saved successfully',
        ),
      );
      // Survey editor / login UI read AI & password-reset flags from public
      // config, which is cached until reload. Refresh so the first key save
      // is visible without a full page refresh.
      await _publicConfig.reloadConfig();
      return true;
    } on Exception catch (e) {
      _setState(
        state.copyWith(
          isSaving: false,
          error: 'Failed to save settings: $e',
        ),
      );
      return false;
    }
  }

  /// Clears operation success and error feedback from the current state.
  void clearMessages() =>
      _setState(state.copyWith(clearError: true, clearSuccessMessage: true));
}
