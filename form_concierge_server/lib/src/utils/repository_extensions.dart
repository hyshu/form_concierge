import 'exceptions.dart';

/// Throws [NotFoundException] if value is null, otherwise returns the value.
T throwIfNotFound<T>(T? value, String resourceName, [Object? id]) {
  if (value == null) {
    throw NotFoundException(resourceName, id);
  }
  return value;
}
