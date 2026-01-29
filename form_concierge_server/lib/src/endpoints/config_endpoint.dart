import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../services/email_service.dart';

/// Endpoint for retrieving public server configuration.
/// All methods are public - no authentication required.
class ConfigEndpoint extends Endpoint {
  /// Returns public server configuration for client apps.
  ///
  /// This endpoint is unauthenticated so clients can check
  /// feature availability before login.
  Future<PublicConfig> getPublicConfig(Session session) async {
    return PublicConfig(
      passwordResetEnabled: EmailService.isConfigured,
      requireEmailVerification: EmailService.isConfigured,
    );
  }
}
