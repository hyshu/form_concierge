/// Custom exceptions for the server.
library;

/// Base exception for domain-specific errors.
sealed class DomainException implements Exception {
  final String message;
  const DomainException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when a requested resource is not found.
class NotFoundException extends DomainException {
  final String resourceType;
  final Object? id;

  NotFoundException(this.resourceType, [this.id])
    : super(
        id != null ? '$resourceType $id not found' : '$resourceType not found',
      );
}

/// Exception thrown when validation fails.
class ValidationException extends DomainException {
  const ValidationException(super.message);
}

/// Exception thrown when a state transition is not allowed.
class InvalidStateTransitionException extends DomainException {
  const InvalidStateTransitionException(super.message);
}

/// Exception thrown when user is not authorized for an action.
class UnauthorizedException extends DomainException {
  const UnauthorizedException([super.message = 'Unauthorized']);
}
