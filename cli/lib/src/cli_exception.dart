/// Thrown for user-facing CLI failures with a preferred process exit code.
class CliException implements Exception {
  /// Creates CliException with the supplied values.
  CliException(this.message, {this.exitCode = 1});

  /// The message displayed to the caller or user.
  final String message;

  /// The process exit code reported for this failure.
  final int exitCode;

  /// Returns a readable description of this error.
  @override
  String toString() => message;
}
