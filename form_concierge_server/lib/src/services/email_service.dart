import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:serverpod/serverpod.dart';

/// Configuration for SMTP email sending.
class SmtpConfig {
  /// Whether SMTP is enabled (all required fields are set).
  final bool enabled;

  /// SMTP server hostname.
  final String host;

  /// SMTP server port.
  final int port;

  /// SMTP username for authentication.
  final String? username;

  /// SMTP password for authentication.
  final String? password;

  /// Email address to send from.
  final String fromEmail;

  /// Display name for the sender.
  final String fromName;

  const SmtpConfig({
    required this.enabled,
    required this.host,
    required this.port,
    this.username,
    this.password,
    required this.fromEmail,
    required this.fromName,
  });

  /// Creates a disabled SMTP config.
  const SmtpConfig.disabled()
    : enabled = false,
      host = '',
      port = 0,
      username = null,
      password = null,
      fromEmail = '',
      fromName = '';

  /// Creates an SmtpConfig from Serverpod passwords.
  ///
  /// Returns a disabled config if required fields are missing.
  factory SmtpConfig.fromServerpod(Serverpod pod) {
    final host = pod.getPassword('smtpHost');
    final portStr = pod.getPassword('smtpPort');
    final fromEmail = pod.getPassword('smtpFromEmail');

    // Check if required fields are present
    if (host == null || portStr == null || fromEmail == null) {
      return const SmtpConfig.disabled();
    }

    final port = int.tryParse(portStr);
    if (port == null) {
      return const SmtpConfig.disabled();
    }

    return SmtpConfig(
      enabled: true,
      host: host,
      port: port,
      username: pod.getPassword('smtpUsername'),
      password: pod.getPassword('smtpPassword'),
      fromEmail: fromEmail,
      fromName: pod.getPassword('smtpFromName') ?? 'Form Concierge',
    );
  }
}

/// Singleton service for sending emails via SMTP.
class EmailService {
  static EmailService? _instance;

  /// Gets the singleton instance.
  ///
  /// Throws if [initialize] has not been called.
  static EmailService get instance {
    if (_instance == null) {
      throw StateError('EmailService has not been initialized');
    }
    return _instance!;
  }

  /// Whether the email service is configured and enabled.
  static bool get isConfigured => _instance?.config.enabled ?? false;

  /// The SMTP configuration.
  final SmtpConfig config;

  /// The SMTP server connection.
  late final SmtpServer? _smtpServer;

  EmailService._(this.config) {
    if (config.enabled) {
      _smtpServer = SmtpServer(
        config.host,
        port: config.port,
        username: config.username,
        password: config.password,
        allowInsecure: config.port == 25 || config.port == 1025,
      );
    } else {
      _smtpServer = null;
    }
  }

  /// Initializes the email service with the given configuration.
  static void initialize(SmtpConfig config) {
    _instance = EmailService._(config);
  }

  /// Sends an email.
  ///
  /// Throws [ServerpodException] if email is not configured.
  Future<void> sendEmail({
    required Session session,
    required String to,
    required String subject,
    required String body,
    String? htmlBody,
  }) async {
    if (!config.enabled || _smtpServer == null) {
      throw Exception('Email service is not configured');
    }

    final message = mailer.Message()
      ..from = mailer.Address(config.fromEmail, config.fromName)
      ..recipients.add(to)
      ..subject = subject
      ..text = body;

    if (htmlBody != null) {
      message.html = htmlBody;
    }

    try {
      final sendReport = await mailer.send(message, _smtpServer);
      session.log('Email sent to $to: ${sendReport.toString()}');
    } on mailer.MailerException catch (e) {
      session.log(
        'Failed to send email to $to: ${e.message}',
        level: LogLevel.error,
      );
      throw Exception('Failed to send email: ${e.message}');
    }
  }

  /// Sends a password reset verification code.
  ///
  /// Throws [ServerpodException] if email is not configured.
  Future<void> sendPasswordResetCode({
    required Session session,
    required String email,
    required String verificationCode,
  }) async {
    await sendEmail(
      session: session,
      to: email,
      subject: 'Password Reset Code',
      body:
          '''
Your password reset verification code is: $verificationCode

This code will expire in 1 hour.

If you did not request a password reset, please ignore this email.
''',
      htmlBody:
          '''
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2>Password Reset</h2>
  <p>Your password reset verification code is:</p>
  <p style="font-size: 24px; font-weight: bold; background: #f5f5f5; padding: 16px; text-align: center; letter-spacing: 4px;">
    $verificationCode
  </p>
  <p>This code will expire in 1 hour.</p>
  <p style="color: #666; font-size: 12px;">
    If you did not request a password reset, please ignore this email.
  </p>
</body>
</html>
''',
    );
  }

  /// Sends a registration verification code.
  ///
  /// Logs to console if email is not configured (registration doesn't require email).
  Future<void> sendRegistrationCode({
    required Session session,
    required String email,
    required String verificationCode,
  }) async {
    if (!config.enabled) {
      // Registration code sending is optional - just log if not configured
      session.log(
        '[EmailService] Registration code for $email: $verificationCode',
      );
      return;
    }

    await sendEmail(
      session: session,
      to: email,
      subject: 'Registration Verification Code',
      body:
          '''
Your registration verification code is: $verificationCode

This code will expire in 1 hour.

If you did not create an account, please ignore this email.
''',
      htmlBody:
          '''
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <h2>Welcome to Form Concierge</h2>
  <p>Your registration verification code is:</p>
  <p style="font-size: 24px; font-weight: bold; background: #f5f5f5; padding: 16px; text-align: center; letter-spacing: 4px;">
    $verificationCode
  </p>
  <p>This code will expire in 1 hour.</p>
  <p style="color: #666; font-size: 12px;">
    If you did not create an account, please ignore this email.
  </p>
</body>
</html>
''',
    );
  }
}
