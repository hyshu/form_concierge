import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/services/email_service.dart';

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
      ),
    ],
  );

  // Admin Dashboard (Flutter Web)
  final adminAppDir = Directory('web/admin');
  if (adminAppDir.existsSync()) {
    pod.webServer.addRoute(FlutterRoute(adminAppDir), '/admin/*');
  }

  // Survey Form (Jaspr)
  final surveyWebDir = Directory('web/survey');
  if (surveyWebDir.existsSync()) {
    pod.webServer.addRoute(StaticRoute.directory(surveyWebDir), '/s/**');
  }

  await pod.start();
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
