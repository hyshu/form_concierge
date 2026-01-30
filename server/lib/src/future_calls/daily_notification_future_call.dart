import 'package:serverpod/serverpod.dart';

import '../generated/future_calls.dart';
import '../generated/protocol.dart';
import '../services/email_service.dart';
import '../services/notification_email_builder.dart';
import '../services/response_summary_service.dart';

/// Future call for sending daily email notifications.
///
/// This call processes notifications for a specific survey and
/// self-reschedules for the next day.
class DailyNotificationFutureCall extends FutureCall<NotificationSettings> {
  static String _identifier(int surveyId) =>
      'daily-notification-survey-$surveyId';

  @override
  Future<void> invoke(
    Session session,
    NotificationSettings? object,
  ) async {
    final settings = object;
    if (settings == null) {
      session.log(
        'DailyNotificationFutureCall invoked with null settings',
        level: LogLevel.warning,
      );
      return;
    }

    session.log(
      'Processing daily notification for survey ${settings.surveyId}',
    );

    // Reload settings from DB to get latest configuration
    final currentSettings = await NotificationSettings.db.findFirstRow(
      session,
      where: (t) => t.surveyId.equals(settings.surveyId),
    );

    if (currentSettings == null) {
      session.log(
        'Notification settings for survey ${settings.surveyId} no longer exist',
        level: LogLevel.warning,
      );
      return;
    }

    // If still enabled, reschedule for next day first (before processing)
    if (currentSettings.enabled) {
      await _rescheduleForNextDay(session, currentSettings);
    }

    // If disabled, don't send notification
    if (!currentSettings.enabled) {
      session.log(
        'Notifications disabled for survey ${settings.surveyId}, skipping',
      );
      return;
    }

    // Process the notification
    await _sendNotification(session, currentSettings);
  }

  Future<void> _rescheduleForNextDay(
    Session session,
    NotificationSettings settings,
  ) async {
    final now = DateTime.now().toUtc();
    var nextRun = DateTime.utc(
      now.year,
      now.month,
      now.day,
      settings.sendHour,
    );

    // Schedule for tomorrow
    nextRun = nextRun.add(const Duration(days: 1));

    final identifier = _identifier(settings.surveyId);

    // Cancel any existing schedule to avoid duplicates
    await session.serverpod.futureCalls.cancel(identifier);

    // Schedule next run
    await session.serverpod.futureCalls
        .callAtTime(nextRun, identifier: identifier)
        .dailyNotification
        .invoke(settings);

    session.log(
      'Daily notification for survey ${settings.surveyId} rescheduled for $nextRun',
    );
  }

  Future<void> _sendNotification(
    Session session,
    NotificationSettings settings,
  ) async {
    // Get survey details
    final survey = await Survey.db.findById(session, settings.surveyId);
    if (survey == null) {
      session.log(
        'Survey ${settings.surveyId} not found, skipping notification',
        level: LogLevel.warning,
      );
      return;
    }

    // Build summary
    final summary = await ResponseSummaryService.buildSummary(session, survey);

    // Skip if no responses
    if (summary.responseCount == 0) {
      session.log(
        'No responses for survey ${survey.title}, skipping email',
      );
      return;
    }

    // Check if email service is configured
    if (!EmailService.isConfigured) {
      session.log(
        'Email service not configured, cannot send notification',
        level: LogLevel.warning,
      );
      return;
    }

    // Build and send email
    final textBody = NotificationEmailBuilder.buildTextBody(summary);
    final htmlBody = NotificationEmailBuilder.buildHtmlBody(summary);

    await EmailService.instance.sendEmail(
      session: session,
      to: settings.recipientEmail,
      subject: 'Daily Response Summary: ${survey.title}',
      body: textBody,
      htmlBody: htmlBody,
    );

    // Update last sent timestamp
    await NotificationSettings.db.updateRow(
      session,
      settings.copyWith(lastSentAt: DateTime.now()),
    );

    session.log(
      'Sent daily notification for survey ${survey.title} to ${settings.recipientEmail}',
    );
  }
}
