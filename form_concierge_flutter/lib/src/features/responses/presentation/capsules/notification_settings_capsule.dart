import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../../../../core/capsules/client_capsule.dart';
import '../../../../core/capsules/keyed_state.dart';

/// State for notification settings.
class NotificationSettingsState {
  final NotificationSettings? settings;
  final bool isLoading;
  final bool isSaving;
  final bool isSendingTest;
  final String? error;
  final String? successMessage;
  final bool isEmailConfigured;

  const NotificationSettingsState({
    this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.isSendingTest = false,
    this.error,
    this.successMessage,
    this.isEmailConfigured = false,
  });

  factory NotificationSettingsState.initial() =>
      const NotificationSettingsState();

  NotificationSettingsState copyWith({
    NotificationSettings? settings,
    bool clearSettings = false,
    bool? isLoading,
    bool? isSaving,
    bool? isSendingTest,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    bool? isEmailConfigured,
  }) => NotificationSettingsState(
    settings: clearSettings ? null : (settings ?? this.settings),
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    isSendingTest: isSendingTest ?? this.isSendingTest,
    error: clearError ? null : (error ?? this.error),
    successMessage: clearSuccessMessage
        ? null
        : (successMessage ?? this.successMessage),
    isEmailConfigured: isEmailConfigured ?? this.isEmailConfigured,
  );
}

/// Capsule using keyed state pattern for per-survey notification settings.
KeyedStateAccessors<int, NotificationSettingsState>
notificationSettingsStateCapsule(CapsuleHandle use) {
  return createKeyedState(use, NotificationSettingsState.initial);
}

/// Capsule that provides the notification settings manager.
NotificationSettingsManager notificationSettingsManagerCapsule(
  CapsuleHandle use,
) {
  final (getState, setState) = use(notificationSettingsStateCapsule);
  final client = use(clientCapsule);

  return NotificationSettingsManager(
    getState: getState,
    setState: setState,
    client: client,
  );
}

/// Manager class for notification settings operations.
class NotificationSettingsManager {
  final NotificationSettingsState Function(int surveyId) getState;
  final void Function(int surveyId, NotificationSettingsState state) _setState;
  final Client _client;

  NotificationSettingsManager({
    required this.getState,
    required void Function(int surveyId, NotificationSettingsState state)
    setState,
    required Client client,
  }) : _setState = setState,
       _client = client;

  /// Load notification settings for a survey.
  Future<void> loadSettings(int surveyId) async {
    final state = getState(surveyId);
    _setState(
      surveyId,
      state.copyWith(isLoading: true, clearError: true),
    );

    try {
      final settings = await _client.notificationSettings.getForSurvey(
        surveyId,
      );
      final isEmailConfigured = await _client.notificationSettings
          .isEmailConfigured();

      _setState(
        surveyId,
        getState(surveyId).copyWith(
          settings: settings,
          clearSettings: settings == null,
          isLoading: false,
          isEmailConfigured: isEmailConfigured,
        ),
      );
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          isLoading: false,
          error: 'Failed to load notification settings: $e',
        ),
      );
    }
  }

  /// Save notification settings.
  Future<bool> saveSettings(int surveyId, NotificationSettings settings) async {
    final state = getState(surveyId);
    _setState(
      surveyId,
      state.copyWith(
        isSaving: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final updatedSettings = await _client.notificationSettings.upsert(
        settings,
      );

      _setState(
        surveyId,
        getState(surveyId).copyWith(
          settings: updatedSettings,
          isSaving: false,
          successMessage: 'Settings saved successfully',
        ),
      );
      return true;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          isSaving: false,
          error: 'Failed to save settings: $e',
        ),
      );
      return false;
    }
  }

  /// Toggle enabled state.
  Future<bool> toggleEnabled(int surveyId) async {
    final state = getState(surveyId);
    final settings = state.settings;

    if (settings == null) return false;

    _setState(
      surveyId,
      state.copyWith(
        isSaving: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final updatedSettings = settings.enabled
          ? await _client.notificationSettings.disable(surveyId)
          : await _client.notificationSettings.enable(surveyId);

      _setState(
        surveyId,
        getState(surveyId).copyWith(
          settings: updatedSettings,
          isSaving: false,
          successMessage: updatedSettings.enabled
              ? 'Notifications enabled'
              : 'Notifications disabled',
        ),
      );
      return true;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          isSaving: false,
          error: 'Failed to toggle notifications: $e',
        ),
      );
      return false;
    }
  }

  /// Send a test notification.
  Future<bool> sendTestNotification(int surveyId) async {
    final state = getState(surveyId);
    _setState(
      surveyId,
      state.copyWith(
        isSendingTest: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      await _client.notificationSettings.sendTestNotification(surveyId);

      _setState(
        surveyId,
        getState(surveyId).copyWith(
          isSendingTest: false,
          successMessage: 'Test notification sent',
        ),
      );
      return true;
    } on Exception catch (e) {
      _setState(
        surveyId,
        getState(surveyId).copyWith(
          isSendingTest: false,
          error: 'Failed to send test notification: $e',
        ),
      );
      return false;
    }
  }

  /// Clear messages for a survey.
  void clearMessages(int surveyId) {
    _setState(
      surveyId,
      getState(surveyId).copyWith(clearError: true, clearSuccessMessage: true),
    );
  }
}
