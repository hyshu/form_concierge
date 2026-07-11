/// Thrown for user-facing CLI failures with a preferred process exit code.
class CliException implements Exception {
  CliException(this.message, {this.exitCode = 1});

  final String message;
  final int exitCode;

  @override
  String toString() => message;
}
