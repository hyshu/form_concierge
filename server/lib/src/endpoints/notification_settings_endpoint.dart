import 'package:serverpod/serverpod.dart';

import '../generated/future_calls.dart';
import '../generated/protocol.dart';
import '../services/email_service.dart';
import '../services/notification_email_builder.dart';
import '../services/response_summary_service.dart';
import '../utils/exceptions.dart';
import '../utils/repository_extensions.dart';

/// Admin endpoint for managing daily notification settings.
/// All methods require authentication.
class NotificationSettingsEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Get notification settings for a survey.
  /// Returns null if not configured.
  Future<NotificationSettings?> getForSurvey(
    Session session,
    int surveyId,
  ) async {
    return await NotificationSettings.db.findFirstRow(
      session,
      where: (t) => t.surveyId.equals(surveyId),
    );
  }

  /// Create or update notification settings for a survey.
  Future<NotificationSettings> upsert(
    Session session,
    NotificationSettings settings,
  ) async {
    // Validate email format
    if (!_isValidEmail(settings.recipientEmail)) {
      throw const ValidationException('Invalid email address');
    }

    // Validate hour range
    if (settings.sendHour < 0 || settings.sendHour > 23) {
      throw const ValidationException('Send hour must be between 0 and 23');
    }

    // Verify survey exists
    throwIfNotFound(
      await Survey.db.findById(session, settings.surveyId),
      'Survey',
      settings.surveyId,
    );

    // Check if settings already exist
    final existing = await NotificationSettings.db.findFirstRow(
      session,
      where: (t) => t.surveyId.equals(settings.surveyId),
    );

    final now = DateTime.now();
    NotificationSettings result;

    if (existing != null) {
      // Update existing
      result = await NotificationSettings.db.updateRow(
        session,
        existing.copyWith(
          enabled: settings.enabled,
          recipientEmail: settings.recipientEmail,
          sendHour: settings.sendHour,
          updatedAt: now,
        ),
      );
    } else {
      // Create new
      result = await NotificationSettings.db.insertRow(
        session,
        settings.copyWith(updatedAt: now),
      );
    }

    // Schedule or cancel future call based on enabled status
    if (result.enabled) {
      await _scheduleFutureCall(session, result);
    } else {
      await _cancelFutureCall(session, result.surveyId);
    }

    return result;
  }

  /// Enable notifications for a survey.
  Future<NotificationSettings> enable(
    Session session,
    int surveyId,
  ) async {
    final settings = throwIfNotFound(
      await NotificationSettings.db.findFirstRow(
        session,
        where: (t) => t.surveyId.equals(surveyId),
      ),
      'NotificationSettings',
      surveyId,
    );

    final updated = await NotificationSettings.db.updateRow(
      session,
      settings.copyWith(enabled: true, updatedAt: DateTime.now()),
    );

    await _scheduleFutureCall(session, updated);

    return updated;
  }

  /// Disable notifications for a survey.
  Future<NotificationSettings> disable(
    Session session,
    int surveyId,
  ) async {
    final settings = throwIfNotFound(
      await NotificationSettings.db.findFirstRow(
        session,
        where: (t) => t.surveyId.equals(surveyId),
      ),
      'NotificationSettings',
      surveyId,
    );

    final updated = await NotificationSettings.db.updateRow(
      session,
      settings.copyWith(enabled: false, updatedAt: DateTime.now()),
    );

    await _cancelFutureCall(session, surveyId);

    return updated;
  }

  /// Delete notification settings for a survey.
  Future<bool> delete(Session session, int surveyId) async {
    final settings = await NotificationSettings.db.findFirstRow(
      session,
      where: (t) => t.surveyId.equals(surveyId),
    );

    if (settings != null) {
      await _cancelFutureCall(session, surveyId);
      await NotificationSettings.db.deleteRow(session, settings);
    }

    return true;
  }

  /// Check if email service is configured.
  Future<bool> isEmailConfigured(Session session) async {
    return EmailService.isConfigured;
  }

  /// Send a test notification immediately.
  Future<bool> sendTestNotification(
    Session session,
    int surveyId,
  ) async {
    if (!EmailService.isConfigured) {
      throw const ValidationException('Email service is not configured');
    }

    final settings = throwIfNotFound(
      await NotificationSettings.db.findFirstRow(
        session,
        where: (t) => t.surveyId.equals(surveyId),
      ),
      'NotificationSettings',
      surveyId,
    );

    final survey = throwIfNotFound(
      await Survey.db.findById(session, surveyId),
      'Survey',
      surveyId,
    );

    // Build and send test email using the summary service
    final summary = await ResponseSummaryService.buildSummary(session, survey);
    final textBody = NotificationEmailBuilder.buildTextBody(summary);
    final htmlBody = NotificationEmailBuilder.buildHtmlBody(summary);

    await EmailService.instance.sendEmail(
      session: session,
      to: settings.recipientEmail,
      subject: '[TEST] Daily Response Summary: ${survey.title}',
      body: textBody,
      htmlBody: htmlBody,
    );

    return true;
  }

  Future<void> _scheduleFutureCall(
    Session session,
    NotificationSettings settings,
  ) async {
    final identifier = _dailyNotificationIdentifier(settings.surveyId);

    // Cancel any existing schedule to avoid duplicates
    await session.serverpod.futureCalls.cancel(identifier);

    // Calculate next run time
    final now = DateTime.now().toUtc();
    var nextRun = DateTime.utc(now.year, now.month, now.day, settings.sendHour);

    // If today's run time has passed, schedule for tomorrow
    if (nextRun.isBefore(now) || nextRun.isAtSameMomentAs(now)) {
      nextRun = nextRun.add(const Duration(days: 1));
    }

    // Schedule the future call
    await session.serverpod.futureCalls
        .callAtTime(nextRun, identifier: identifier)
        .dailyNotification
        .invoke(settings);

    session.log(
      'Scheduled daily notification for survey ${settings.surveyId} at $nextRun',
    );
  }

  Future<void> _cancelFutureCall(Session session, int surveyId) async {
    final identifier = _dailyNotificationIdentifier(surveyId);
    await session.serverpod.futureCalls.cancel(identifier);
    session.log('Cancelled daily notification for survey $surveyId');
  }

  static String _dailyNotificationIdentifier(int surveyId) =>
      'daily-notification-survey-$surveyId';

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
}
