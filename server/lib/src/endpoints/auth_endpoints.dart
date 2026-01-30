import 'package:serverpod_auth_idp_server/core.dart' as core;
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// Endpoint for refreshing JWT tokens
class RefreshJwtTokensEndpoint extends core.RefreshJwtTokensEndpoint {}

/// Endpoint for email-based authentication
class EmailIdpEndpoint extends EmailIdpBaseEndpoint {}
