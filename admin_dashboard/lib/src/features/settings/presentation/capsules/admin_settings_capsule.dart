import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/public_config_capsule.dart';

class AdminSettingsState {
  final AdminIntegrationSettings? settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const AdminSettingsState({
    this.settings,
    this.isLoading = true,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

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

class AdminSettingsManager {
  final AdminSettingsState state;
  final void Function(AdminSettingsState state) _setState;
  final Client _client;
  final PublicConfigManager _publicConfig;

  const AdminSettingsManager({
    required this.state,
    required this._setState,
    required this._client,
    required this._publicConfig,
  });

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

  void clearMessages() =>
      _setState(state.copyWith(clearError: true, clearSuccessMessage: true));
}
