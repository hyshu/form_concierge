import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import 'src/future_calls/daily_notification_future_call.dart';
import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/services/email_service.dart';
import 'src/services/gemini_service.dart';

void run(List<String> args) async {
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Initialize email service from SMTP configuration
  final smtpConfig = SmtpConfig.fromServerpod(pod);
  EmailService.initialize(smtpConfig);

  if (smtpConfig.enabled) {
    pod.logVerbose(
      'Email service enabled (${smtpConfig.host}:${smtpConfig.port})',
    );
  } else {
    pod.logVerbose('Email service disabled - SMTP not configured');
  }

  // Initialize Gemini service from API key configuration
  final geminiConfig = GeminiConfig.fromServerpod(pod);
  GeminiService.initialize(geminiConfig);

  if (geminiConfig.enabled) {
    pod.logVerbose('Gemini service enabled');
  } else {
    pod.logVerbose('Gemini service disabled - API key not configured');
  }

  // Use fixed verification code when email is disabled for easier development
  const devVerificationCode = '00000000';

  // Initialize authentication services
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      JwtConfigFromPasswords(),
    ],
    identityProviderBuilders: [
      EmailIdpConfig(
        secretHashPepper:
            pod.getPassword('emailSecretHashPepper') ??
            'development-pepper-minimum-32-chars',
        sendRegistrationVerificationCode: _sendRegistrationCode,
        sendPasswordResetVerificationCode: _sendPasswordResetCode,
        // Use fixed code when email is disabled so clients can auto-verify
        registrationVerificationCodeGenerator: smtpConfig.enabled
            ? defaultVerificationCodeGenerator
            : () => devVerificationCode,
      ),
    ],
  );

  // Admin Dashboard (Flutter Web)
  final adminAppDir = Directory('web/admin');
  if (adminAppDir.existsSync()) {
    pod.webServer.addRoute(FlutterRoute(adminAppDir), '/admin');
  }

  // Survey Form (Jaspr)
  final surveyWebDir = Directory('web/survey');
  if (surveyWebDir.existsSync()) {
    pod.webServer.addRoute(StaticRoute.directory(surveyWebDir), '/s/**');
  }

  // Register future calls
  pod.registerFutureCall(DailyNotificationFutureCall(), 'dailyNotification');

  await pod.start();

  // Initialize scheduled notifications for existing enabled settings
  await _initializeDailyNotifications(pod);
}

/// Initialize daily notification future calls for all enabled settings.
Future<void> _initializeDailyNotifications(Serverpod pod) async {
  final session = await pod.createSession();

  try {
    // Find all enabled notification settings
    final settings = await NotificationSettings.db.find(
      session,
      where: (t) => t.enabled.equals(true),
    );

    if (settings.isEmpty) {
      pod.logVerbose('No daily notifications configured');
      return;
    }

    pod.logVerbose('Initializing ${settings.length} daily notification(s)');

    for (final setting in settings) {
      final identifier = DailyNotificationFutureCall.taskIdentifier(
        setting.surveyId,
      );

      // Cancel any stale schedules
      await session.serverpod.cancelFutureCall(identifier);

      // Calculate next run time
      final now = DateTime.now().toUtc();
      var nextRun = DateTime.utc(
        now.year,
        now.month,
        now.day,
        setting.sendHour,
      );

      // If today's run time has passed, schedule for tomorrow
      if (nextRun.isBefore(now)) {
        nextRun = nextRun.add(const Duration(days: 1));
      }

      // Schedule the future call
      await session.serverpod.futureCallAtTime(
        'dailyNotification',
        setting,
        nextRun,
        identifier: identifier,
      );

      pod.logVerbose(
        'Scheduled notification for survey ${setting.surveyId} at $nextRun UTC',
      );
    }
  } finally {
    await session.close();
  }
}

void _sendRegistrationCode(
  Session session, {
  required String email,
  required UuidValue accountRequestId,
  required String verificationCode,
  required Transaction? transaction,
}) {
  // Registration code sending is optional - logs if SMTP not configured
  EmailService.instance.sendRegistrationCode(
    session: session,
    email: email,
    verificationCode: verificationCode,
  );
}

void _sendPasswordResetCode(
  Session session, {
  required String email,
  required UuidValue passwordResetRequestId,
  required String verificationCode,
  required Transaction? transaction,
}) {
  // Password reset requires email to be configured - throws if not
  EmailService.instance.sendPasswordResetCode(
    session: session,
    email: email,
    verificationCode: verificationCode,
  );
}
